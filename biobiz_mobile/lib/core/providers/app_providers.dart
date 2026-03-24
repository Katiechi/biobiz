import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import '../models/contact_model.dart';
import '../models/recording_model.dart';
import '../models/subscription_model.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});

final activeCardProvider = FutureProvider<CardModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final supabase = Supabase.instance.client;
  final cards = await supabase
      .from('cards')
      .select()
      .eq('user_id', user.id)
      .eq('is_active', true)
      .order('updated_at', ascending: false)
      .limit(1);

  if (cards.isEmpty) return null;
  final card = cards.first;

  final fields = await supabase.from('card_contact_fields').select().eq('card_id', card['id']).order('sort_order');
  final links = await supabase.from('card_social_links').select().eq('card_id', card['id']).order('sort_order');

  return CardModel.fromJson(
    card,
    contactFieldsJson: List<Map<String, dynamic>>.from(fields),
    socialLinksJson: List<Map<String, dynamic>>.from(links),
  );
});

final contactsProvider = FutureProvider<List<ContactModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final contacts = await Supabase.instance.client
      .from('contacts')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return contacts.map((c) => ContactModel.fromJson(c)).toList();
});

final recordingsProvider = FutureProvider<List<RecordingModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final recordings = await Supabase.instance.client
      .from('recordings')
      .select('*, recording_summaries(*)')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return recordings.map((r) {
    final summaries = r['recording_summaries'] as List?;
    final summaryJson = summaries != null && summaries.isNotEmpty
        ? summaries.first as Map<String, dynamic>
        : null;
    return RecordingModel.fromJson(r, summaryJson: summaryJson);
  }).toList();
});

final subscriptionProvider = FutureProvider<SubscriptionModel>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return SubscriptionModel.free('');

  final sub = await Supabase.instance.client
      .from('subscriptions')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();

  if (sub == null) return SubscriptionModel.free(user.id);
  return SubscriptionModel.fromJson(sub);
});

final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
});
