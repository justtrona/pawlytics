import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsGrid extends StatefulWidget {
  const StatsGrid({super.key});

  @override
  State<StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<StatsGrid> {
  final _sb = Supabase.instance.client;

  // --------- Adjust table/column names here if your schema differs ----------
  static const _usersTable = 'registration'; // admins/staff/users
  static const _userNameCol = 'fullName';
  static const _userEmailCol = 'email';

  static const _donationsTable = 'donations';
  static const _donorNameCol = 'donor_name';

  static const _campaignsTable = 'campaigns';
  // The fields we’ll scan for the word "urgent" (case-insensitive)
  static const _campaignUrgentFields = <String>[
    'category',
    'program',
    'description',
    'tags', // if you store comma-separated tags
  ];

  static const _petsTable = 'pet_profiles';
  // -------------------------------------------------------------------------

  bool _loading = true;
  String? _error;

  int _totalUsers = 0;
  int _campaigns = 0;
  int _urgent = 0;
  int _pets = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ---- Unique Users = union(registration users, donations donors)
      final usersRows = await _sb
          .from(_usersTable)
          .select('$_userNameCol, $_userEmailCol');

      final donorsRows = await _sb
          .from(_donationsTable)
          .select('$_donorNameCol');

      final uniquePeople = <String>{};

      String? _norm(String? s) {
        if (s == null) return null;
        final v = s.trim().toLowerCase();
        return v.isEmpty ? null : v;
      }

      for (final r in (usersRows as List)) {
        final name = _norm(r[_userNameCol]?.toString());
        final email = _norm(r[_userEmailCol]?.toString());
        if (name != null) {
          uniquePeople.add(name);
        } else if (email != null) {
          uniquePeople.add(email);
        }
      }

      for (final r in (donorsRows as List)) {
        final donor = _norm(r[_donorNameCol]?.toString());
        if (donor != null) uniquePeople.add(donor);
      }

      // ---- Campaigns (total + urgent)
      // Pull common text fields so we can detect "urgent" on the client
      final campaignsRows = await _sb
          .from(_campaignsTable)
          .select(['id', ..._campaignUrgentFields].join(','));

      final campaignsList = (campaignsRows as List).cast<Map>();

      int urgentCount = 0;
      for (final row in campaignsList) {
        final hasUrgent = _campaignUrgentFields.any((col) {
          final v = row[col]?.toString().toLowerCase() ?? '';
          return v.contains('urgent');
        });
        if (hasUrgent) urgentCount++;
      }

      // If you have a boolean like `is_urgent` instead, replace the block above
      // with this single query (and remove the text scan):
      //
      // final urgentRows = await _sb.from(_campaignsTable).select('id').eq('is_urgent', true);
      // final urgentCount = (urgentRows as List).length;

      // ---- Pets
      final petsRows = await _sb.from(_petsTable).select('id');

      if (!mounted) return;
      setState(() {
        _totalUsers = uniquePeople.length;
        _campaigns = campaignsList.length;
        _urgent = urgentCount;
        _pets = (petsRows as List).length;
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
    if (_loading) return const _SkeletonGrid();
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Failed to load stats: $_error')),
                  TextButton(
                    onPressed: _loadCounts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _grid(),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: _grid(),
    );
  }

  Widget _grid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        const _StatCard(
          icon: Icons.people,
          title: "Total Users",
        ).withValue(_totalUsers),
        const _StatCard(
          icon: Icons.campaign,
          title: "Campaigns",
        ).withValue(_campaigns),
        const _StatCard(
          icon: Icons.warning_amber_rounded,
          title: "Urgent Cases",
        ).withValue(_urgent),
        const _StatCard(icon: Icons.pets, title: "Total Pets").withValue(_pets),
      ],
    );
  }
}

// ---------- UI bits ----------

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? valueText;

  static const brandColor = Color(0xFFEC8C69);

  const _StatCard({required this.icon, required this.title, this.valueText});

  _StatCard withValue(int v) =>
      _StatCard(icon: icon, title: title, valueText: '$v');

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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                Text(
                  valueText ?? '—',
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

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    Widget box() => Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: List.generate(4, (_) => box()),
      ),
    );
  }
}
