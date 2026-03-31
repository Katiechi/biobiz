import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:biobiz_mobile/app/theme.dart';
import '../../../core/services/ai_summary_service.dart';

/// AI Notetaker - Record meetings, get AI-powered summaries
class NotetakerScreen extends ConsumerStatefulWidget {
  const NotetakerScreen({super.key});

  @override
  ConsumerState<NotetakerScreen> createState() => _NotetakerScreenState();
}

class _NotetakerScreenState extends ConsumerState<NotetakerScreen>
    with TickerProviderStateMixin {
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadRecordings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _tabController.dispose();
    _pulseController.dispose();
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Notetaker',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(100),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Record'),
                Tab(text: 'Recordings'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: _isRecording ? const NeverScrollableScrollPhysics() : null,
        children: [_buildRecordTab(), _buildRecordingsTab()],
      ),
    );
  }

  Widget _buildRecordTab() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing mic visualizer
            _buildMicVisualizer(cs),
            const SizedBox(height: 32),
            // Timer display - Plus Jakarta Sans, extra bold, monospace-like
            Text(
              _isRecording ? _formatTime(_recordingSeconds) : '00:00',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 56,
                fontWeight: FontWeight.w800,
                letterSpacing: -2.0,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // Status indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRecording && !_isPaused && !_isSaving) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _isSaving
                      ? 'Saving recording...'
                      : _isRecording
                          ? (_isPaused ? 'PAUSED' : 'RECORDING')
                          : 'READY TO CAPTURE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                    color: _isRecording && !_isPaused
                        ? cs.primary
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            if (_isSaving) ...[
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: cs.primary,
                ),
              ),
            ] else if (_isRecording) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pause button - tonal style
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Material(
                      color: cs.surfaceContainerHigh,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _togglePause,
                        child: Center(
                          child: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: cs.onSurface,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Stop button - primary gradient style
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Material(
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppTheme.heritageGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: _stopRecording,
                          child: const Center(
                            child: Icon(Icons.stop, size: 36, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Record FAB - primary color with shadow
              SizedBox(
                width: 80,
                height: 80,
                child: Material(
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppTheme.heritageGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: _startRecording,
                      child: const Center(
                        child: Icon(
                          Icons.fiber_manual_record,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            // Real-time transcription placeholder
            if (_isRecording && !_isSaving)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Transcribing in real-time as you speak...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Tips container - secondaryContainer background with lightbulb
            if (!_isRecording && !_isSaving)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lightbulb icon in secondaryContainer
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.lightbulb,
                        size: 20,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pro Tips',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMicVisualizer(ColorScheme cs) {
    if (_isRecording) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Inner filled circle
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.heritageGradient,
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.mic,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    // Not recording - static state
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary.withValues(alpha: 0.08),
          ),
        ),
        // Inner filled circle
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.heritageGradient,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.2),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.mic,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022  ',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingsTab() {
    final cs = Theme.of(context).colorScheme;
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: cs.primary),
      );
    }
    if (_recordings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.library_music_outlined,
                    size: 44, color: cs.primary),
              ),
              const SizedBox(height: 24),
              Text('No recordings yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  )),
              const SizedBox(height: 8),
              Text('Record a meeting to get AI-powered summaries',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: cs.primary,
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
    final cs = Theme.of(context).colorScheme;
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

    // No-line design: tonal depth with surfaceContainerLowest, no borders
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRecordingDetail(recording),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  // Mic icon with primary tonal bg
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.mic,
                        color: cs.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recording ${_formatDate(createdAt)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              )),
                          const SizedBox(height: 2),
                          Text(
                              '${_formatTime(duration)} \u2022 ${_statusLabel(status)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              )),
                        ]),
                  ),
                  // AI Summary chip - secondaryContainer/gold styling
                  if (hasSummary)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 12,
                              color: cs.onSecondaryContainer),
                          const SizedBox(width: 4),
                          Text('AI Summary',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSecondaryContainer,
                              )),
                        ],
                      ),
                    ),
                ]),
                if (summary != null && summary['summary'] != null) ...[
                  const SizedBox(height: 12),
                  Text(summary['summary'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      )),
                ],
              ],
            ),
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
        title: Text('Delete recording?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
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
    final cs = Theme.of(context).colorScheme;
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
          color: cs.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    )),
                Row(children: [
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: cs.error),
                    onPressed: widget.onDelete,
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cs.onSurfaceVariant),
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
                  // Info chips - tonal style
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
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(children: [
                        Row(children: [
                          // Play button with primary color
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: Material(
                              color: cs.primary,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  if (_player.playing) {
                                    _player.pause();
                                  } else {
                                    _player.play();
                                  }
                                },
                                child: Center(
                                  child: Icon(
                                    _player.playing ? Icons.pause : Icons.play_arrow,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  activeTrackColor: cs.primary,
                                  inactiveTrackColor: cs.surfaceContainerHighest,
                                  thumbColor: cs.primary,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14),
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
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        )),
                                    Text(_fmt(_duration),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        )),
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
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: cs.primary)),
                          const SizedBox(width: 12),
                          Text('Loading audio...',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                              )),
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
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimaryContainer)),
                        const SizedBox(width: 12),
                        Text('Generating AI summary...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onPrimaryContainer,
                            )),
                      ]),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Summary content
                  if (summary != null) ...[
                    if (summary['summary'] != null) ...[
                      _sectionHeader(context, 'Summary', Icons.auto_awesome),
                      const SizedBox(height: 8),
                      Text(summary['summary'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.6,
                            color: cs.onSurface,
                          )),
                      const SizedBox(height: 24),
                    ],
                    if (summary['transcript'] != null &&
                        (summary['transcript'] as String).isNotEmpty) ...[
                      _sectionHeader(context, 'Transcript', Icons.description_outlined),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(summary['transcript'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.6,
                              color: cs.onSurfaceVariant,
                            )),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (summary['key_insights'] != null &&
                        (summary['key_insights'] as List).isNotEmpty) ...[
                      _sectionHeader(context, 'Key Insights', Icons.lightbulb_outline),
                      const SizedBox(height: 8),
                      ...((summary['key_insights'] as List).map((i) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cs.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(i as String,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: cs.onSurface,
                                        )),
                                  ),
                                ]),
                          ))),
                      const SizedBox(height: 24),
                    ],
                    if (summary['action_items'] != null &&
                        (summary['action_items'] as List).isNotEmpty) ...[
                      _sectionHeader(context, 'Action Items', Icons.task_alt),
                      const SizedBox(height: 8),
                      ...((summary['action_items'] as List).map((i) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_box_outline_blank,
                                      size: 18,
                                      color: cs.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(i as String,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: cs.onSurface,
                                        )),
                                  ),
                                ]),
                          ))),
                    ],
                  ] else if (status != 'processing') ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.auto_awesome,
                                size: 36, color: cs.primary),
                          ),
                          const SizedBox(height: 16),
                          Text('No AI summary yet',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              )),
                          const SizedBox(height: 8),
                          Text(
                              'Tap below to generate a summary.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                              )),
                          const SizedBox(height: 20),
                          if (widget.onRetrySummary != null &&
                              widget.audioUrl != null &&
                              !widget.audioUrl!.startsWith('pending://'))
                            HeritageGradientButton(
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
                              height: 48,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isRetrying)
                                    const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  else
                                    const Icon(Icons.auto_awesome,
                                        size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isRetrying
                                        ? 'Generating...'
                                        : 'Generate AI Summary',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            )),
      ],
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            )),
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
