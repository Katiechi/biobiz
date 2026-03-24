import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  final _supabase = Supabase.instance.client;
  bool _isPremium = false;
  String _currentPlan = 'free';
  int _selectedPlan = 1; // 0=monthly, 1=annual
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final sub = await _supabase.from('subscriptions').select().eq('user_id', user.id).maybeSingle();
      if (sub != null && mounted) {
        setState(() {
          _currentPlan = sub['plan'] as String? ?? 'free';
          _isPremium = _currentPlan != 'free' && (sub['status'] == 'active' || sub['status'] == 'trialing');
        });
      }
    } catch (e) {
      debugPrint('Error loading subscription: $e');
      // If table doesn't exist or query fails, user stays on free
    }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator())
          : _isPremium ? _buildPremiumActive() : _buildPremiumOffer(),
    );
  }

  Widget _buildPremiumActive() {
    return ListView(padding: const EdgeInsets.all(24), children: [
      Center(child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(Icons.star, size: 48, color: Theme.of(context).colorScheme.primary),
      )),
      const SizedBox(height: 24),
      Text("You're on Premium!", textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 32),
      _buildFeatureItem(Icons.badge, '5 active cards'),
      _buildFeatureItem(Icons.palette, 'Custom card colors'),
      _buildFeatureItem(Icons.qr_code, 'Logo in QR code'),
      _buildFeatureItem(Icons.remove_circle_outline, 'No BioBiz branding'),
      _buildFeatureItem(Icons.auto_awesome, 'Unlimited AI summaries'),
      _buildFeatureItem(Icons.email, 'Custom email domain'),
      const SizedBox(height: 32),
      OutlinedButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Manage subscription in your app store settings'))),
        child: const Text('Manage subscription'),
      ),
    ]);
  }

  Widget _buildPremiumOffer() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Hero
      Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(children: [
          Icon(Icons.star, size: 48, color: Colors.white),
          SizedBox(height: 12),
          Text('BioBiz Premium', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 4),
          Text('Make every connection count', style: TextStyle(color: Colors.white70)),
        ]),
      ),
      const SizedBox(height: 24),

      // Features comparison
      _buildCompareRow('Active cards', '2', '5'),
      _buildCompareRow('Card colors', 'Presets', 'Custom'),
      _buildCompareRow('QR code', 'Standard', 'Logo'),
      _buildCompareRow('Branding', 'BioBiz badge', 'None'),
      _buildCompareRow('AI Notetaker', '3/month', 'Unlimited'),
      _buildCompareRow('Analytics', 'Basic', 'Advanced'),
      _buildCompareRow('Email sig', 'No', 'Yes'),
      const SizedBox(height: 24),

      // Plan cards
      Row(children: [
        Expanded(child: _buildPlanCard(0, 'Monthly', '\$4.99', '/month', null)),
        const SizedBox(width: 12),
        Expanded(child: _buildPlanCard(1, 'Annual', '\$2.99', '/month', 'Save 40%')),
      ]),
      const SizedBox(height: 24),

      FilledButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('In-app purchases available when published to stores.'), duration: Duration(seconds: 3))),
        style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
        child: const Text('Start 7-day free trial', style: TextStyle(fontSize: 16)),
      ),
      const SizedBox(height: 8),
      Text('Cancel anytime. No charge during trial.', textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildPlanCard(int index, String name, String price, String period, String? badge) {
    final isSelected = _selectedPlan == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1),
        ),
        child: Column(children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
              child: Text(badge, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
          ],
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Theme.of(context).colorScheme.primary : null)),
          const SizedBox(height: 4),
          Text(price, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(period, style: Theme.of(context).textTheme.bodySmall),
          if (index == 1) Text('Billed \$35.88/year', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _buildCompareRow(String feature, String free, String premium) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 110, child: Text(feature, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
        Expanded(child: Text(free, textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
        Expanded(child: Text(premium, textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 12),
        Text(text),
      ]),
    );
  }
}
