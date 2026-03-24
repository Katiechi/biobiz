class ContactModel {
  final String id;
  final String userId;
  final String source;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? company;
  final String? jobTitle;
  final String? website;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContactModel({
    required this.id,
    required this.userId,
    this.source = 'manual',
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.company,
    this.jobTitle,
    this.website,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory ContactModel.fromJson(Map<String, dynamic> json) => ContactModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    source: json['source'] as String? ?? 'manual',
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    company: json['company'] as String?,
    jobTitle: json['job_title'] as String?,
    website: json['website'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
