import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/ai_summary_service.dart';

/// AI Notetaker - Record meetings, get AI-powered summaries
class NotetakerScreen extends ConsumerStatefulWidget {
  const NotetakerScreen({super.key});

  @override
  ConsumerState<NotetakerScreen> createState() => _NotetakerScreenState();
}

class _NotetakerScreenState extends ConsumerState<NotetakerScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  List<Map<String, dynamic>> _recordings = [];
  bool _isLoading = true;
  bool _isSaving = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecordings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final recordings = await _supabase
          .from('recordings')
          .select('*, recording_summaries(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(
            () => _recordings = List<Map<String, dynamic>>.from(recordings));
      }
    } catch (e) {
      debugPrint('Error loading recordings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Microphone permission is required to record')),
        );
      }
      return;
    }

    final dir = Directory.systemTemp;
    final filePath =
        '${dir.path}/biobiz_recording_${const Uuid().v4()}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: filePath,
    );

    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordingSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) setState(() => _recordingSeconds++);
    });
  }

  Future<void> _togglePause() async {
    if (_isPaused) {
      await _recorder.resume();
    } else {
      await _recorder.pause();
    }
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _isSaving = true;
    });

    if (path == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Upload audio to Supabase storage
      final file = File(path);
      final fileName = '${const Uuid().v4()}.m4a';
      final storagePath = 'recordings/${user.id}/$fileName';

      await _supabase.storage.from('biobiz').uploadBinary(
            storagePath,
            await file.readAsBytes(),
            fileOptions:
                const FileOptions(contentType: 'audio/mp4', upsert: true),
          );

      final audioUrl =
          _supabase.storage.from('biobiz').getPublicUrl(storagePath);

      // Save recording metadata
      final recordingResponse =
          await _supabase.from('recordings').insert({
        'user_id': user.id,
        'audio_url': audioUrl,
        'duration_seconds': _recordingSeconds,
        'status': 'processing',
      }).select().single();

      final recordingId = recordingResponse['id'] as String;

      // Clean up temp file
      await file.delete().catchError((_) {});

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording saved! Generating AI summary...')));
        _loadRecordings();
        _tabController.animateTo(1);
      }

      // Generate AI summary in the background
      _generateSummary(recordingId, audioUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _generateSummary(String recordingId, String audioUrl) async {
    try {
      final aiService = AiSummaryService();
      final result = await aiService.summarizeRecording(audioUrl);

      final summary = (result['summary'] as String?) ?? '';
      final transcript = (result['transcript'] as String?) ?? '';

      if (summary.isEmpty && transcript.isEmpty) {
        throw Exception('AI could not process this recording. Try a longer or clearer recording.');
      }

      // Delete any existing summary for this recording (retry case)
      await _supabase
          .from('recording_summaries')
          .delete()
          .eq('recording_id', recordingId);

      // Save summary to database
      await _supabase.from('recording_summaries').insert({
        'recording_id': recordingId,
        'transcript': transcript,
        'summary': summary,
        'people_mentioned': result['people_mentioned'],
        'key_insights': result['key_insights'],
        'action_items': result['action_items'],
      });

      // Update recording status
      await _supabase
          .from('recordings')
          .update({'status': 'completed'})
          .eq('id', recordingId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI summary ready!')));
        _loadRecordings();
      }
    } catch (e) {
      debugPrint('AI summary error: $e');
      // Mark as completed so user can retry later
      await _supabase
          .from('recordings')
          .update({'status': 'completed'})
          .eq('id', recordingId);

      if (mounted) {
        final msg = e.toString().contains('429')
            ? 'AI rate limit reached. Tap the recording to retry later.'
            : 'AI summary failed. Tap the recording to retry.';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));
        _loadRecordings();
      }
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Notetaker'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: 'Record'),
          Tab(text: 'Recordings'),
        ]),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: _isRecording ? const NeverScrollableScrollPhysics() : null,
        children: [_buildRecordTab(), _buildRecordingsTab()],
      ),
    );
  }

  Widget _buildRecordTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isRecording ? 180 : 140,
              height: _isRecording ? 180 : 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.1)
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
              ),
              child: Center(
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  size: 48,
                  color: _isRecording
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _isRecording ? _formatTime(_recordingSeconds) : '00:00',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 8),
            Text(
              _isSaving
                  ? 'Saving recording...'
                  : _isRecording
                      ? (_isPaused ? 'Paused' : 'Recording...')
                      : 'Tap to start recording',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _isRecording && !_isPaused
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 48),
            if (_isSaving) ...[
              const CircularProgressIndicator(),
            ] else if (_isRecording) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: 'pause',
                    onPressed: _togglePause,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  ),
                  const SizedBox(width: 32),
                  FloatingActionButton.large(
                    heroTag: 'stop',
                    onPressed: _stopRecording,
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.stop, size: 36),
                  ),
                ],
              ),
            ] else ...[
              FloatingActionButton.large(
                heroTag: 'record',
                onPressed: _startRecording,
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                child: const Icon(Icons.fiber_manual_record, size: 36),
              ),
            ],
            const SizedBox(height: 48),
            if (!_isRecording && !_isSaving)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      Icon(Icons.lightbulb_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Tips',
                          style: Theme.of(context).textTheme.titleSmall),
                    ]),
                    const SizedBox(height: 8),
                    _buildTip('Place your phone near the conversation'),
                    _buildTip('Works best in quieter environments'),
                    _buildTip(
                        'AI will summarize key points and action items'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Text('  •  ', style: Theme.of(context).textTheme.bodySmall),
        Expanded(
            child:
                Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ]),
    );
  }

  Widget _buildRecordingsTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_recordings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.library_music_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text('No recordings yet',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Record a meeting to get AI-powered summaries',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecordings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recordings.length,
        itemBuilder: (context, index) =>
            _buildRecordingCard(_recordings[index]),
      ),
    );
  }

  Widget _buildRecordingCard(Map<String, dynamic> recording) {
    final duration = recording['duration_seconds'] as int? ?? 0;
    final status = recording['status'] as String? ?? 'completed';
    final createdAt = DateTime.tryParse(recording['created_at'] ?? '');
    final rawSummary = recording['recording_summaries'];
    final Map<String, dynamic>? summary;
    if (rawSummary is List && rawSummary.isNotEmpty) {
      summary = rawSummary.first as Map<String, dynamic>;
    } else if (rawSummary is Map<String, dynamic> && rawSummary.isNotEmpty) {
      summary = rawSummary;
    } else {
      summary = null;
    }
    final hasSummary = summary != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRecordingDetail(recording),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.mic,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recording ${_formatDate(createdAt)}',
                            style:
                                Theme.of(context).textTheme.titleSmall),
                        Text(
                            '${_formatTime(duration)} • ${_statusLabel(status)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                      ]),
                ),
                if (hasSummary)
                  Chip(
                    label: Text('AI Summary',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.primary)),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
              ]),
              if (summary != null && summary['summary'] != null) ...[
                const SizedBox(height: 12),
                Text(summary['summary'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordingDetail(Map<String, dynamic> recording) {
    final audioUrl = recording['audio_url'] as String?;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RecordingDetailSheet(
        recording: recording,
        audioUrl: audioUrl,
        onDelete: () => _deleteRecording(recording['id'], ctx),
        onRetrySummary: _generateSummary,
      ),
    );
  }

  Future<void> _deleteRecording(String id, BuildContext ctx) async {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete recording?'),
        content:
            const Text('This will permanently delete this recording.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await _supabase.from('recordings').delete().eq('id', id);
              if (mounted) {
                Navigator.pop(dialogCtx);
                Navigator.pop(ctx);
                _loadRecordings();
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'recording':
        return 'Recording';
      case 'processing':
        return 'Processing...';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }
}

/// Bottom sheet with audio player and summary details
class _RecordingDetailSheet extends StatefulWidget {
  final Map<String, dynamic> recording;
  final String? audioUrl;
  final VoidCallback onDelete;
  final Future<void> Function(String recordingId, String audioUrl)? onRetrySummary;

  const _RecordingDetailSheet({
    required this.recording,
    required this.audioUrl,
    required this.onDelete,
    this.onRetrySummary,
  });

  @override
  State<_RecordingDetailSheet> createState() => _RecordingDetailSheetState();
}

class _RecordingDetailSheetState extends State<_RecordingDetailSheet> {
  late AudioPlayer _player;
  bool _isPlayerReady = false;
  bool _isRetrying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.audioUrl;
    if (url == null || url.startsWith('pending://')) return;

    try {
      final duration = await _player.setUrl(url);
      if (duration != null && mounted) {
        setState(() {
          _duration = duration;
          _isPlayerReady = true;
        });
      }

      _player.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });

      _player.playerStateStream.listen((state) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      debugPrint('Player init error: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.recording['duration_seconds'] as int? ?? 0;
    final createdAt = DateTime.tryParse(widget.recording['created_at'] ?? '');
    final rawSummary = widget.recording['recording_summaries'];
    final Map<String, dynamic>? summary;
    if (rawSummary is List && rawSummary.isNotEmpty) {
      summary = rawSummary.first as Map<String, dynamic>;
    } else if (rawSummary is Map<String, dynamic> && rawSummary.isNotEmpty) {
      summary = rawSummary;
    } else {
      summary = null;
    }
    final status = widget.recording['status'] as String? ?? 'completed';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recording Details',
                    style: Theme.of(context).textTheme.titleLarge),
                Row(children: [
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error),
                    onPressed: widget.onDelete,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ]),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips
                  Row(children: [
                    _chip(context, Icons.timer,
                        '${(duration ~/ 60).toString().padLeft(2, '0')}:${(duration % 60).toString().padLeft(2, '0')}'),
                    const SizedBox(width: 8),
                    _chip(context, Icons.calendar_today, _fmtDate(createdAt)),
                  ]),
                  const SizedBox(height: 20),

                  // Audio Player
                  if (_isPlayerReady) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(children: [
                        Row(children: [
                          IconButton.filled(
                            onPressed: () {
                              if (_player.playing) {
                                _player.pause();
                              } else {
                                _player.play();
                              }
                            },
                            icon: Icon(
                              _player.playing ? Icons.pause : Icons.play_arrow,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                ),
                                child: Slider(
                                  value: _position.inMilliseconds
                                      .toDouble()
                                      .clamp(0, _duration.inMilliseconds.toDouble()),
                                  max: _duration.inMilliseconds.toDouble(),
                                  onChanged: (v) {
                                    _player.seek(
                                        Duration(milliseconds: v.toInt()));
                                  },
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_fmt(_position),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    Text(_fmt(_duration),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 24),
                  ] else if (widget.audioUrl != null &&
                      !widget.audioUrl!.startsWith('pending://')) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Loading audio...'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Processing status
                  if (status == 'processing') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text('Generating AI summary...',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer)),
                      ]),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Summary content
                  if (summary != null) ...[
                    if (summary['summary'] != null) ...[
                      Text('Summary',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(summary['summary'] as String),
                      const SizedBox(height: 24),
                    ],
                    if (summary['transcript'] != null &&
                        (summary['transcript'] as String).isNotEmpty) ...[
                      Text('Transcript',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(summary['transcript'] as String,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 24),
                    ],
                    if (summary['key_insights'] != null &&
                        (summary['key_insights'] as List).isNotEmpty) ...[
                      Text('Key Insights',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...((summary['key_insights'] as List).map((i) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('  •  '),
                                  Expanded(child: Text(i as String)),
                                ]),
                          ))),
                      const SizedBox(height: 24),
                    ],
                    if (summary['action_items'] != null &&
                        (summary['action_items'] as List).isNotEmpty) ...[
                      Text('Action Items',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...((summary['action_items'] as List).map((i) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_box_outline_blank,
                                      size: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(i as String)),
                                ]),
                          ))),
                    ],
                  ] else if (status != 'processing') ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(children: [
                          Icon(Icons.auto_awesome,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 16),
                          Text('No AI summary yet',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                              'Tap below to generate a summary.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                          const SizedBox(height: 16),
                          if (widget.onRetrySummary != null &&
                              widget.audioUrl != null &&
                              !widget.audioUrl!.startsWith('pending://'))
                            FilledButton.icon(
                              onPressed: _isRetrying
                                  ? null
                                  : () async {
                                      setState(() => _isRetrying = true);
                                      await widget.onRetrySummary!(
                                        widget.recording['id'] as String,
                                        widget.audioUrl!,
                                      );
                                      if (mounted) {
                                        setState(() => _isRetrying = false);
                                        Navigator.pop(context);
                                      }
                                    },
                              icon: _isRetrying
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.auto_awesome),
                              label: Text(_isRetrying
                                  ? 'Generating...'
                                  : 'Generate AI Summary'),
                            ),
                        ]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }

  String _fmtDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
