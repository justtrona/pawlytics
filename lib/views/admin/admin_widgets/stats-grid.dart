import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsGrid extends StatefulWidget {
  const StatsGrid({super.key});

  @override
  State<StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<StatsGrid> {
  static const _accent = Color(0xFFEC8C69);

  final _sb = Supabase.instance.client;

  int _totalUsers = 0;
  int _campaigns = 0;
  int _urgentCases = 0;
  int _totalPets = 0;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ----- Total admins (registration) -----
      final regRows = await _sb.from('registration').select('id');
      final adminCount = (regRows as List).length;

      // ----- Distinct donors by donor_name (column exists) -----
      // Some rows might have null/empty names; filter client-side to be safe.
      final donorRows = await _sb
          .from('donations')
          .select('donor_name'); // no donor_email
      final donorNames = <String>{};
      for (final r in (donorRows as List)) {
        final name = (r['donor_name'] ?? '').toString().trim().toLowerCase();
        if (name.isNotEmpty) donorNames.add(name);
      }
      final donorCount = donorNames.length;

      // ----- Campaigns (all) -----
      final campRows = await _sb.from('campaigns').select('id');
      final campaigns = (campRows as List).length;

      // ----- Urgent Cases (category ILIKE 'urgent') -----
      final urgentRows = await _sb
          .from('campaigns')
          .select('id')
          .ilike('category', 'urgent');
      final urgent = (urgentRows as List).length;

      // ----- Total Pets -----
      final petRows = await _sb.from('pet_profiles').select('id');
      final pets = (petRows as List).length;

      if (!mounted) return;
      setState(() {
        _totalUsers = adminCount + donorCount;
        _campaigns = campaigns;
        _urgentCases = urgent;
        _totalPets = pets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFCDD2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to load stats: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _StatCard(
            icon: Icons.people,
            title: 'Total Users',
            value: '$_totalUsers',
          ),
          _StatCard(
            icon: Icons.campaign,
            title: 'Campaigns',
            value: '$_campaigns',
          ),
          _StatCard(
            icon: Icons.warning_amber_rounded,
            title: 'Urgent Cases',
            value: '$_urgentCases',
          ),
          _StatCard(
            icon: Icons.pets,
            title: 'Total Pets',
            value: '$_totalPets',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  static const brandColor = Color(0xFFEC8C69);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: brandColor, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
