import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for card CRUD operations
class CardService {
  static final CardService _instance = CardService._internal();
  factory CardService() => _instance;
  CardService._internal();

  final _supabase = Supabase.instance.client;

  /// Save contact fields for a card (delete existing, insert new)
  Future<void> saveContactFields(String cardId, List<Map<String, dynamic>> fields) async {
    try {
      await _supabase.from('card_contact_fields').delete().eq('card_id', cardId);

      if (fields.isNotEmpty) {
        final toInsert = fields.asMap().entries.map((entry) => {
          'card_id': cardId,
          'field_type': entry.value['field_type'],
          'value': entry.value['value'],
          'label': entry.value['label'],
          'sort_order': entry.key,
        }).toList();

        await _supabase.from('card_contact_fields').insert(toInsert);
      }
    } catch (e) {
      debugPrint('Error saving contact fields: $e');
      rethrow;
    }
  }

  /// Save social links for a card (delete existing, insert new)
  Future<void> saveSocialLinks(String cardId, List<Map<String, dynamic>> links) async {
    try {
      await _supabase.from('card_social_links').delete().eq('card_id', cardId);

      if (links.isNotEmpty) {
        final toInsert = links.asMap().entries.map((entry) => {
          'card_id': cardId,
          'platform': entry.value['platform'],
          'url': entry.value['url'],
          'sort_order': entry.key,
        }).toList();

        await _supabase.from('card_social_links').insert(toInsert);
      }
    } catch (e) {
      debugPrint('Error saving social links: $e');
      rethrow;
    }
  }
}
