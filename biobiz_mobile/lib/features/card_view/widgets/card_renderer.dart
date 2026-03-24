import 'package:flutter/material.dart';

/// Story 4.1: Card renderer — the visual business card
class CardRenderer extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final bool isPreview;

  const CardRenderer({
    super.key,
    required this.cardData,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = _parseColor(cardData['card_color'] as String? ?? '#000000');
    final firstName = cardData['first_name'] ?? '';
    final lastName = cardData['last_name'] ?? '';
    final middleName = cardData['middle_name'] ?? '';
    final prefix = cardData['prefix'] ?? '';
    final suffix = cardData['suffix'] ?? '';
    final pronoun = cardData['pronoun'] ?? '';
    final preferredName = cardData['preferred_name'] ?? '';
    final jobTitle = cardData['job_title'];
    final company = cardData['company'];
    final department = cardData['department'];
    final companyWebsite = cardData['company_website'];
    final headline = cardData['headline'];
    final profileImageUrl = cardData['profile_image_url'];
    final logoUrl = cardData['logo_url'];
    final coverImageUrl = cardData['cover_image_url'];

    // Build full display name with prefix/suffix
    final nameParts = <String>[
      if (prefix.isNotEmpty) prefix,
      firstName,
      if (middleName.isNotEmpty) middleName,
      if (lastName != null && lastName.isNotEmpty) lastName,
      if (suffix.isNotEmpty) suffix,
    ];
    final fullName = nameParts.join(' ').trim();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover image
            if (coverImageUrl != null && coverImageUrl.isNotEmpty)
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Image.network(
                  coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              )
            else
              const SizedBox(height: 8),

            // Header with logo
            if (logoUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 32,
                  child: Image.network(
                    logoUrl,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Profile image
            CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
              onBackgroundImageError: profileImageUrl != null ? (_, __) {} : null,
              child: profileImageUrl == null
                  ? Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Full name with prefix/suffix
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Preferred name
            if (preferredName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Goes by "$preferredName"',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Pronoun
            if (pronoun.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                pronoun,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Job title
            if (jobTitle != null && jobTitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  jobTitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Company + Department
            if (company != null && company.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                department != null && department.isNotEmpty
                    ? '$company · $department'
                    : company,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (department != null && department.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                department,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Headline
            if (headline != null && headline.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  headline,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Divider(color: Colors.white.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 12),

            // Contact fields
            if (cardData['contact_fields'] != null)
              ..._buildContactFields(cardData['contact_fields'] as List),

            // Company website (shown if not already in contact fields)
            if (companyWebsite != null &&
                companyWebsite.isNotEmpty &&
                !_hasFieldType(cardData['contact_fields'], 'company_website'))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        companyWebsite,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Social links
            if (cardData['social_links'] != null &&
                (cardData['social_links'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._buildSocialLinks(cardData['social_links'] as List),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  bool _hasFieldType(dynamic fields, String type) {
    if (fields == null || fields is! List) return false;
    return fields.any((f) => f is Map && f['field_type'] == type);
  }

  List<Widget> _buildContactFields(List fields) {
    return fields.map((field) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
        child: Row(
          children: [
            Icon(
              _getContactIcon(field['field_type']),
              size: 18,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                field['value'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildSocialLinks(List links) {
    return links.map((link) {
      final platform = link['platform'] as String? ?? '';
      final url = link['url'] as String? ?? '';
      // Show a readable label: platform name, and trim base URL for cleaner display
      final displayName = _platformDisplayName(platform);
      final displayUrl = _shortenUrl(url, platform);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
        child: Row(
          children: [
            Icon(
              _getSocialIcon(platform),
              size: 18,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    displayUrl,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _platformDisplayName(String platform) {
    switch (platform) {
      case 'linkedin': return 'LinkedIn';
      case 'instagram': return 'Instagram';
      case 'x': return 'X (Twitter)';
      case 'facebook': return 'Facebook';
      case 'whatsapp': return 'WhatsApp';
      case 'telegram': return 'Telegram';
      case 'tiktok': return 'TikTok';
      case 'youtube': return 'YouTube';
      case 'github': return 'GitHub';
      default: return platform;
    }
  }

  String _shortenUrl(String url, String platform) {
    // Strip common prefixes for cleaner display
    var display = url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst('www.', '');
    // Remove trailing slash
    if (display.endsWith('/')) display = display.substring(0, display.length - 1);
    return display;
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.black;
    }
  }

  IconData _getContactIcon(String? type) {
    switch (type) {
      case 'email':
        return Icons.email_outlined;
      case 'phone':
        return Icons.phone_outlined;
      case 'address':
        return Icons.location_on_outlined;
      case 'link':
        return Icons.link;
      case 'company_website':
        return Icons.language;
      default:
        return Icons.info_outline;
    }
  }

  IconData _getSocialIcon(String? platform) {
    switch (platform) {
      case 'linkedin':
        return Icons.work_outline;
      case 'instagram':
        return Icons.photo_camera_outlined;
      case 'x':
        return Icons.close;
      case 'facebook':
        return Icons.facebook;
      case 'whatsapp':
        return Icons.chat;
      case 'telegram':
        return Icons.send_outlined;
      case 'tiktok':
        return Icons.music_note;
      case 'youtube':
        return Icons.play_circle_outline;
      case 'github':
        return Icons.code;
      default:
        return Icons.link;
    }
  }
}
