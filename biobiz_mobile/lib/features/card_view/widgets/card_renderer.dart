import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Story 4.1: Card renderer — the visual business card
/// Atelier design: premium shadow, standard card aspect ratio,
/// gradient header accent, refined typography with Plus Jakarta Sans
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

    // Build full display name
    final nameParts = <String>[
      if (prefix.isNotEmpty) prefix,
      firstName,
      if (middleName.isNotEmpty) middleName,
      if (lastName != null && lastName.isNotEmpty) lastName,
      if (suffix.isNotEmpty) suffix,
    ];
    final fullName = nameParts.join(' ').trim();

    // Compute luminance for text color
    final isDarkCard = cardColor.computeLuminance() < 0.4;
    final textColor = isDarkCard ? Colors.white : const Color(0xFF1C1B1A);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative accent circles (subtle, Atelier signature)
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: textColor.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: textColor.withValues(alpha: 0.03),
                ),
              ),
            ),

            // Main content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cover image
                if (coverImageUrl != null && coverImageUrl.isNotEmpty)
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: textColor.withValues(alpha: 0.05),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),

                // Logo
                if (logoUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      height: 36,
                      child: Image.network(
                        logoUrl,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Profile image
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: textColor.withValues(alpha: 0.15),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: textColor.withValues(alpha: 0.1),
                    backgroundImage:
                        profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                    onBackgroundImageError:
                        profileImageUrl != null ? (_, __) {} : null,
                    child: profileImageUrl == null
                        ? Text(
                            firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: textColor.withValues(alpha: 0.6),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Full name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    fullName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Preferred name
                if (preferredName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Goes by "$preferredName"',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Pronoun
                if (pronoun.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    pronoun,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                // Job title
                if (jobTitle != null && jobTitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      jobTitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                // Company + Department
                if (company != null && company.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    department != null && department.isNotEmpty
                        ? '$company · $department'
                        : company,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (department != null && department.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    department,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.6),
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: textColor.withValues(alpha: 0.55),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Divider(
                    color: textColor.withValues(alpha: 0.12),
                    thickness: 1,
                  ),
                ),
                const SizedBox(height: 14),

                // Contact fields
                if (cardData['contact_fields'] != null)
                  ..._buildContactFields(cardData['contact_fields'] as List, textColor),

                // Company website
                if (companyWebsite != null &&
                    companyWebsite.isNotEmpty &&
                    !_hasFieldType(cardData['contact_fields'], 'company_website'))
                  _buildContactRow(
                    Icons.language,
                    companyWebsite,
                    textColor,
                  ),

                // Social links
                if (cardData['social_links'] != null &&
                    (cardData['social_links'] as List).isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Divider(
                      color: textColor.withValues(alpha: 0.08),
                      thickness: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildSocialLinks(cardData['social_links'] as List, textColor),
                ],

                const SizedBox(height: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _hasFieldType(dynamic fields, String type) {
    if (fields == null || fields is! List) return false;
    return fields.any((f) => f is Map && f['field_type'] == type);
  }

  Widget _buildContactRow(IconData icon, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 17, color: textColor.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContactFields(List fields, Color textColor) {
    return fields.map((field) {
      return _buildContactRow(
        _getContactIcon(field['field_type']),
        field['value'] ?? '',
        textColor,
      );
    }).toList();
  }

  List<Widget> _buildSocialLinks(List links, Color textColor) {
    return links.map((link) {
      final platform = link['platform'] as String? ?? '';
      final url = link['url'] as String? ?? '';
      final displayName = _platformDisplayName(platform);
      final displayUrl = _shortenUrl(url, platform);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 5),
        child: Row(
          children: [
            Icon(
              _getSocialIcon(platform),
              size: 17,
              color: textColor.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: textColor.withValues(alpha: 0.4),
                    ),
                  ),
                  Text(
                    displayUrl,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.85),
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
      case 'linkedin': return 'LINKEDIN';
      case 'instagram': return 'INSTAGRAM';
      case 'x': return 'X (TWITTER)';
      case 'facebook': return 'FACEBOOK';
      case 'whatsapp': return 'WHATSAPP';
      case 'telegram': return 'TELEGRAM';
      case 'tiktok': return 'TIKTOK';
      case 'youtube': return 'YOUTUBE';
      case 'github': return 'GITHUB';
      default: return platform.toUpperCase();
    }
  }

  String _shortenUrl(String url, String platform) {
    var display = url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst('www.', '');
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
      case 'email': return Icons.email_outlined;
      case 'phone': return Icons.phone_outlined;
      case 'address': return Icons.location_on_outlined;
      case 'link': return Icons.link;
      case 'company_website': return Icons.language;
      default: return Icons.info_outline;
    }
  }

  IconData _getSocialIcon(String? platform) {
    switch (platform) {
      case 'linkedin': return Icons.work_outline;
      case 'instagram': return Icons.photo_camera_outlined;
      case 'x': return Icons.close;
      case 'facebook': return Icons.facebook;
      case 'whatsapp': return Icons.chat;
      case 'telegram': return Icons.send_outlined;
      case 'tiktok': return Icons.music_note;
      case 'youtube': return Icons.play_circle_outline;
      case 'github': return Icons.code;
      default: return Icons.link;
    }
  }
}
