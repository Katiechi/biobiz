/// Data model for a BioBiz digital business card
class CardModel {
  final String id;
  final String userId;
  final String slug;
  final String cardName;
  final String firstName;
  final String? lastName;
  final String? middleName;
  final String? prefix;
  final String? suffix;
  final String? pronoun;
  final String? preferredName;
  final String? jobTitle;
  final String? department;
  final String? company;
  final String? companyWebsite;
  final String? headline;
  final String? profileImageUrl;
  final String? logoUrl;
  final String? coverImageUrl;
  final String cardColor;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ContactField> contactFields;
  final List<SocialLink> socialLinks;

  const CardModel({
    required this.id,
    required this.userId,
    required this.slug,
    this.cardName = 'My Card',
    required this.firstName,
    this.lastName,
    this.middleName,
    this.prefix,
    this.suffix,
    this.pronoun,
    this.preferredName,
    this.jobTitle,
    this.department,
    this.company,
    this.companyWebsite,
    this.headline,
    this.profileImageUrl,
    this.logoUrl,
    this.coverImageUrl,
    this.cardColor = '#000000',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.contactFields = const [],
    this.socialLinks = const [],
  });

  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  factory CardModel.fromJson(Map<String, dynamic> json, {
    List<Map<String, dynamic>> contactFieldsJson = const [],
    List<Map<String, dynamic>> socialLinksJson = const [],
  }) {
    return CardModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      slug: json['slug'] as String,
      cardName: json['card_name'] as String? ?? 'My Card',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String?,
      middleName: json['middle_name'] as String?,
      prefix: json['prefix'] as String?,
      suffix: json['suffix'] as String?,
      pronoun: json['pronoun'] as String?,
      preferredName: json['preferred_name'] as String?,
      jobTitle: json['job_title'] as String?,
      department: json['department'] as String?,
      company: json['company'] as String?,
      companyWebsite: json['company_website'] as String?,
      headline: json['headline'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      cardColor: json['card_color'] as String? ?? '#000000',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      contactFields: contactFieldsJson.map((e) => ContactField.fromJson(e)).toList(),
      socialLinks: socialLinksJson.map((e) => SocialLink.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'slug': slug,
    'card_name': cardName,
    'first_name': firstName,
    'last_name': lastName,
    'middle_name': middleName,
    'prefix': prefix,
    'suffix': suffix,
    'pronoun': pronoun,
    'preferred_name': preferredName,
    'job_title': jobTitle,
    'department': department,
    'company': company,
    'company_website': companyWebsite,
    'headline': headline,
    'profile_image_url': profileImageUrl,
    'logo_url': logoUrl,
    'cover_image_url': coverImageUrl,
    'card_color': cardColor,
    'is_active': isActive,
  };
}

class ContactField {
  final String id;
  final String cardId;
  final String fieldType;
  final String value;
  final String? label;
  final int sortOrder;

  const ContactField({
    required this.id,
    required this.cardId,
    required this.fieldType,
    required this.value,
    this.label,
    this.sortOrder = 0,
  });

  factory ContactField.fromJson(Map<String, dynamic> json) => ContactField(
    id: json['id'] as String,
    cardId: json['card_id'] as String,
    fieldType: json['field_type'] as String,
    value: json['value'] as String,
    label: json['label'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'card_id': cardId,
    'field_type': fieldType,
    'value': value,
    'label': label,
    'sort_order': sortOrder,
  };
}

class SocialLink {
  final String id;
  final String cardId;
  final String platform;
  final String url;
  final int sortOrder;

  const SocialLink({
    required this.id,
    required this.cardId,
    required this.platform,
    required this.url,
    this.sortOrder = 0,
  });

  factory SocialLink.fromJson(Map<String, dynamic> json) => SocialLink(
    id: json['id'] as String,
    cardId: json['card_id'] as String,
    platform: json['platform'] as String,
    url: json['url'] as String,
    sortOrder: json['sort_order'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'card_id': cardId,
    'platform': platform,
    'url': url,
    'sort_order': sortOrder,
  };
}
