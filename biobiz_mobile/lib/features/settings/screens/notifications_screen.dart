import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _cardViewed = true;
  bool _contactSaved = true;
  bool _newExchange = true;
  bool _recordingSummary = true;
  bool _weeklyDigest = false;
  bool _marketingUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('ACTIVITY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Card viewed'),
                  subtitle: const Text('When someone views your card'),
                  value: _cardViewed,
                  onChanged: (v) => setState(() => _cardViewed = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Contact saved'),
                  subtitle: const Text('When someone saves your contact'),
                  value: _contactSaved,
                  onChanged: (v) => setState(() => _contactSaved = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Card exchange'),
                  subtitle: const Text('When someone exchanges cards with you'),
                  value: _newExchange,
                  onChanged: (v) => setState(() => _newExchange = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Recording summary'),
                  subtitle: const Text('When AI summary is ready'),
                  value: _recordingSummary,
                  onChanged: (v) => setState(() => _recordingSummary = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('UPDATES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Weekly digest'),
                  subtitle: const Text('Summary of card activity'),
                  value: _weeklyDigest,
                  onChanged: (v) => setState(() => _weeklyDigest = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Product updates'),
                  subtitle: const Text('New features and tips'),
                  value: _marketingUpdates,
                  onChanged: (v) => setState(() => _marketingUpdates = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
