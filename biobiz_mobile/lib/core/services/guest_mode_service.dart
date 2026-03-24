import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service for managing guest user data locally
/// Used when users want to create a card without signing up
class GuestModeService {
  static const _boxName = 'guest_card_data';
  static const _cardDataKey = 'card_data';
  static const _guestSlugKey = 'guest_slug';
  static const _isGuestKey = 'is_guest';
  
  static final GuestModeService _instance = GuestModeService._internal();
  factory GuestModeService() => _instance;
  GuestModeService._internal();
  
  Box<dynamic>? _box;
  bool _initialized = false;
  
  /// Initialize Hive box for guest data
  Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    _initialized = true;
  }
  
  Box<dynamic> get _safeBox {
    if (_box == null) {
      throw StateError('GuestModeService not initialized. Call initialize() first.');
    }
    return _box!;
  }
  
  /// Generate a unique guest slug
  String generateGuestSlug() {
    final uuid = const Uuid().v4();
    return 'guest-${uuid.substring(0, 8)}';
  }
  
  /// Save card data for guest user
  Future<void> saveGuestCardData(Map<String, dynamic> cardData) async {
    await _safeBox.put(_cardDataKey, jsonEncode(cardData));
  }
  
  /// Get saved guest card data
  Map<String, dynamic>? getGuestCardData() {
    final data = _safeBox.get(_cardDataKey);
    if (data == null) return null;
    try {
      return jsonDecode(data as String) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  /// Save guest slug
  Future<void> saveGuestSlug(String slug) async {
    await _safeBox.put(_guestSlugKey, slug);
  }
  
  /// Get guest slug
  String? getGuestSlug() {
    return _safeBox.get(_guestSlugKey) as String?;
  }
  
  /// Mark current session as guest
  Future<void> setIsGuest(bool isGuest) async {
    await _safeBox.put(_isGuestKey, isGuest);
  }
  
  /// Check if current user is a guest
  bool get isGuest => _safeBox.get(_isGuestKey) ?? false;
  
  /// Check if guest has saved card data
  bool get hasGuestCardData => getGuestCardData() != null;
  
  /// Clear all guest data (called after successful conversion to registered user)
  Future<void> clearGuestData() async {
    await _safeBox.delete(_cardDataKey);
    await _safeBox.delete(_guestSlugKey);
    await _safeBox.put(_isGuestKey, false);
  }
  
  /// Convert guest data to registered user format
  Map<String, String> convertToCardData() {
    final data = getGuestCardData();
    if (data == null) return {};
    
    return data.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }
}

/// Provider for easy access to guest mode status
class GuestModeProvider {
  final GuestModeService _service = GuestModeService();
  
  bool get isGuest => _service.isGuest;
  bool get hasCardData => _service.hasGuestCardData;
  Map<String, String>? get cardData => _service.hasGuestCardData 
      ? _service.convertToCardData() 
      : null;
  String? get slug => _service.getGuestSlug();
}
