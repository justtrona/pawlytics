import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class RewardsCertification extends StatefulWidget {
  const RewardsCertification({super.key});

  @override
  State<RewardsCertification> createState() => _RewardsCertificationState();
}

/* ====================== Models ====================== */

class _Tier {
  final String name;
  final String key;
  final Color color;
  final IconData icon;
  const _Tier({
    required this.name,
    required this.key,
    required this.color,
    required this.icon,
  });
}

/* ====================== Main Class ====================== */

class _RewardsCertificationState extends State<RewardsCertification> {
  static const bg = Color(0xFFF6F7F9);
  static const subtitle = Color(0xFF6E7B8A);

  final _sb = Supabase.instance.client;

  final _tiers = const [
    _Tier(
      name: 'Bronze Certificate',
      key: 'bronze',
      color: Color(0xFFCD7F32),
      icon: Icons.military_tech,
    ),
    _Tier(
      name: 'Silver Certificate',
      key: 'silver',
      color: Color(0xFFC0C0C0),
      icon: Icons.military_tech,
    ),
    _Tier(
      name: 'Gold Certificate',
      key: 'gold',
      color: Color(0xFFFFD700),
      icon: Icons.military_tech,
    ),
    _Tier(
      name: 'Platinum Certificate',
      key: 'platinum',
      color: Color(0xFF9C27B0),
      icon: Icons.military_tech,
    ),
    _Tier(
      name: 'Diamond Certificate',
      key: 'diamond',
      color: Color(0xFF00B8D9),
      icon: Icons.military_tech,
    ),
  ];

  bool _loading = true;
  String? _error;

  final Map<String, int> _tierCounts = {};
  bool _summaryLoading = false;
  String? _summaryError;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() => _loading = true);
    try {
      await _loadSummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ====================== Summary ====================== */

  Future<void> _loadSummary() async {
    _summaryLoading = true;
    _summaryError = null;
    _tierCounts.clear();
    setState(() {});

    try {
      final rows = await _sb
          .from('certificates_issued')
          .select('donor_name,tier_key,issued_at')
          .order('issued_at', ascending: false);

      final Map<String, Set<String>> uniqueDonors = {};

      for (final r in rows as List) {
        final tierKey = (r['tier_key'] ?? '').toString().toLowerCase().trim();
        final donor = (r['donor_name'] ?? '').toString().trim();
        if (tierKey.isEmpty || donor.isEmpty) continue;

        uniqueDonors.putIfAbsent(tierKey, () => <String>{});
        uniqueDonors[tierKey]!.add(donor.toLowerCase());
      }

      for (final t in _tiers) {
        _tierCounts[t.key] = uniqueDonors[t.key]?.length ?? 0;
      }
    } catch (e) {
      _summaryError = e.toString();
    } finally {
      _summaryLoading = false;
      if (mounted) setState(() {});
    }
  }

  /* ====================== UI BUILDERS ====================== */

  Widget _buildTierCard(_Tier tier, int count, int totalUsers) {
    final pct = totalUsers == 0 ? 0.0 : (count / totalUsers);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: tier.color.withOpacity(0.15),
                radius: 18,
                child: Icon(tier.icon, color: tier.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tier.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // User count
          Text(
            '$count user${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: tier.color,
            ),
          ),

          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              color: tier.color,
            ),
          ),

          const SizedBox(height: 6),
          Text(
            totalUsers == 0
                ? '—'
                : '${(pct * 100).toStringAsFixed(0)}% of all users',
            style: const TextStyle(fontSize: 12, color: subtitle),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    if (_summaryLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_summaryError != null) return _ErrorRow(_summaryError!);

    final totalUsers = _tierCounts.values.fold<int>(0, (a, b) => a + b);
    if (totalUsers == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No certificates issued yet.',
            style: TextStyle(color: subtitle, fontSize: 16),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700
            ? 3
            : constraints.maxWidth > 450
            ? 2
            : 1;
        return GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: _tiers
              .map(
                (t) => _buildTierCard(t, _tierCounts[t.key] ?? 0, totalUsers),
              )
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalUniqueUsers = _tierCounts.isNotEmpty
        ? _tierCounts.values.fold<int>(0, (a, b) => a + b)
        : 0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          'Rewards & Certification',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorRow(_error!)
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🏅 Organization Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_outlined),
                      tooltip: 'Export CSV',
                      onPressed: () async {
                        try {
                          final csv = StringBuffer(
                            'tier_key,tier_name,unique_users\n',
                          );
                          for (final t in _tiers) {
                            final count = _tierCounts[t.key] ?? 0;
                            csv.writeln('${t.key},"${t.name}",$count');
                          }
                          final dir = await getTemporaryDirectory();
                          final file = File(
                            '${dir.path}/certificate_summary.csv',
                          );
                          await file.writeAsString(csv.toString());
                          await Share.shareXFiles([
                            XFile(file.path),
                          ], text: 'Certificate Summary (Unique Users)');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Export failed: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Total unique users: $totalUniqueUsers',
                  style: const TextStyle(
                    color: Color(0xFF0F2D50),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryGrid(),
              ],
            ),
    );
  }
}

/* ====================== Error Row ====================== */

class _ErrorRow extends StatelessWidget {
  final String message;
  const _ErrorRow(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
