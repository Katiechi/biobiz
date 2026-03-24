class SubscriptionModel {
  final String id;
  final String userId;
  final String plan;
  final String status;
  final String? provider;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    this.plan = 'free',
    this.status = 'active',
    this.provider,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPremium => plan != 'free' && (status == 'active' || status == 'trialing');
  int get maxCards => isPremium ? 5 : 2;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) => SubscriptionModel(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    plan: json['plan'] as String? ?? 'free',
    status: json['status'] as String? ?? 'active',
    provider: json['provider'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  static SubscriptionModel free(String userId) => SubscriptionModel(
    id: '',
    userId: userId,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
