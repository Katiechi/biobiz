/// Service for generating vCard data from card information
class VCardService {
  static String generateVCard(Map<String, dynamic> cardData) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');

    final firstName = cardData['first_name'] ?? '';
    final lastName = cardData['last_name'] ?? '';
    buffer.writeln('N:$lastName;$firstName;;;');
    buffer.writeln('FN:$firstName${lastName.isNotEmpty ? " $lastName" : ""}'.trim());

    if (cardData['company'] != null && (cardData['company'] as String).isNotEmpty) {
      buffer.writeln('ORG:${cardData['company']}');
    }
    if (cardData['job_title'] != null && (cardData['job_title'] as String).isNotEmpty) {
      buffer.writeln('TITLE:${cardData['job_title']}');
    }
    if (cardData['headline'] != null && (cardData['headline'] as String).isNotEmpty) {
      buffer.writeln('NOTE:${cardData['headline']}');
    }
    if (cardData['company_website'] != null && (cardData['company_website'] as String).isNotEmpty) {
      buffer.writeln('URL:${cardData['company_website']}');
    }
    if (cardData['profile_image_url'] != null) {
      buffer.writeln('PHOTO;VALUE=uri:${cardData['profile_image_url']}');
    }

    final contactFields = cardData['contact_fields'] as List?;
    if (contactFields != null) {
      for (final field in contactFields) {
        final type = field['field_type'] as String? ?? '';
        final value = field['value'] as String? ?? '';
        switch (type) {
          case 'email': buffer.writeln('EMAIL;TYPE=WORK:$value');
          case 'phone': buffer.writeln('TEL;TYPE=WORK:$value');
          case 'address': buffer.writeln('ADR;TYPE=WORK:;;$value');
          case 'link':
          case 'company_website': buffer.writeln('URL;TYPE=WORK:$value');
        }
      }
    }

    final socialLinks = cardData['social_links'] as List?;
    if (socialLinks != null) {
      for (final link in socialLinks) {
        buffer.writeln('X-SOCIALPROFILE;TYPE=${link['platform']}:${link['url']}');
      }
    }

    buffer.writeln('END:VCARD');
    return buffer.toString();
  }
}
