import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardsCertification extends StatefulWidget {
  const RewardsCertification({super.key});

  @override
  State<RewardsCertification> createState() => _RewardsCertificationState();
}

/* ---------- Models ---------- */

class _Tier {
  final String name;
  final String key; // stable key for map lookups
  final int threshold; // in PHP
  final Color badgeColor;
  const _Tier({
    required this.name,
    required this.key,
    required this.threshold,
    required this.badgeColor,
  });
}

class _TierProgress {
  final String label; // e.g., "Silver Certificate"
  final double value; // 0..1
  final _Tier? current; // highest earned (may be null if none)
  final _Tier? next; // null if top tier achieved
  final String currentOutOf; // "₱x out of ₱y"
  const _TierProgress({
    required this.label,
    required this.value,
    required this.current,
    required this.next,
    required this.currentOutOf,
  });
}

class _DonorGroup {
  final String key; // normalized name
  String label; // latest non-empty donor_name used for display
  double total = 0.0; // cash only total
  final Map<String, DateTime?> earnedDates; // tierKey -> first-cross time
  _DonorGroup({
    required this.key,
    required this.label,
    required List<_Tier> tiers,
  }) : earnedDates = {for (final t in tiers) t.key: null};
}

/* ---------- Page ---------- */

class _RewardsCertificationState extends State<RewardsCertification> {
  // Theme
  static const navy = Color(0xFF0F2D50);
  static const subtitle = Color(0xFF6E7B8A);
  static const bg = Color(0xFFF6F7F9);

  final _sb = Supabase.instance.client;

  // Tiers
  final _tiers = const [
    _Tier(
      name: 'Bronze Certificate',
      key: 'bronze',
      threshold: 5000,
      badgeColor: Colors.brown,
    ),
    _Tier(
      name: 'Silver Certificate',
      key: 'silver',
      threshold: 10500,
      badgeColor: Colors.grey,
    ),
    _Tier(
      name: 'Gold Certificate',
      key: 'gold',
      threshold: 25000,
      badgeColor: Colors.amber,
    ),
  ];

  // State
  bool _loading = true;
  String? _error;

  // Grouped donors: key -> group
  final Map<String, _DonorGroup> _groups = {};
  // Dropdown options (stable order)
  List<String> _keys = [];
  String? _selectedKey;

  // Current selection stats
  double _total = 0.0;
  Map<String, DateTime?> _earnedDates = {};
  _TierProgress? _progress;

  final _money = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 0,
  );
  final _dateFmt = DateFormat('MMMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _loadAndGroup();
  }

  /// Load minimal donation data and group by normalized donor_name
  Future<void> _loadAndGroup() async {
    setState(() {
      _loading = true;
      _error = null;
      _groups.clear();
      _keys = [];
      _selectedKey = null;
      _total = 0.0;
      _earnedDates = {};
      _progress = null;
    });

    try {
      // We only need donor_name, donation_date, amount
      final rows = await _sb
          .from('donations')
          .select('donor_name, donation_date, amount')
          .order('donation_date', ascending: true);

      // Build groups (chronological so we can compute earned dates correctly)
      for (final r in rows as List) {
        final rawName = (r['donor_name'] ?? '').toString().trim();
        if (rawName.isEmpty) continue; // skip nameless entries

        final key = rawName.toLowerCase(); // normalized key
        final dt = _parseDt(r['donation_date']);
        final amt = _toDouble(r['amount']);

        _groups.putIfAbsent(
          key,
          () => _DonorGroup(key: key, label: rawName, tiers: _tiers),
        );

        final g = _groups[key]!;

        // Keep the most recent non-empty display label (we iterate oldest->newest,
        // so overwrite label to end up with the latest spelling/casing).
        g.label = rawName;

        // CASH ONLY total (amount > 0)
        if (amt > 0) {
          g.total += amt;

          // Check tier crossings in chronological order
          for (final t in _tiers) {
            if (g.earnedDates[t.key] == null && g.total >= t.threshold) {
              g.earnedDates[t.key] = dt;
            }
          }
        }
      }

      // Create sorted keys by label (list of group keys as strings)
      final groupsList = _groups.values.toList();
      groupsList.sort(
        (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );
      _keys = groupsList.map((g) => g.key).toList();

      if (_keys.isNotEmpty) {
        _selectedKey = _keys.first;
        _applySelection(_selectedKey!);
      }

      if (_keys.isNotEmpty) {
        _selectedKey = _keys.first;
        _applySelection(_selectedKey!);
      }
    } on PostgrestException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySelection(String key) {
    final g = _groups[key]!;
    _total = g.total;
    _earnedDates = g.earnedDates;
    _progress = _computeProgress(_total);
    setState(() {});
  }

  _TierProgress _computeProgress(double total) {
    _Tier? earnedHighest;
    _Tier? nextTarget;

    for (final t in _tiers) {
      if (total >= t.threshold) {
        earnedHighest = t;
      } else {
        nextTarget ??= t;
        break;
      }
    }

    if (nextTarget == null) {
      final top = _tiers.last;
      return _TierProgress(
        label: '${top.name} (Completed)',
        value: 1.0,
        current: top,
        next: null,
        currentOutOf: _money.format(total),
      );
    }

    final double prevThreshold = (earnedHighest?.threshold ?? 0).toDouble();
    final double span = (nextTarget.threshold - prevThreshold).toDouble();
    final double intoSpan = (total - prevThreshold).clamp(0.0, span).toDouble();
    final double percent = span == 0.0
        ? 0.0
        : (intoSpan / span).clamp(0.0, 1.0).toDouble();

    final String outOf =
        '${_money.format(total)} out of ${_money.format(nextTarget.threshold)}';

    return _TierProgress(
      label: nextTarget.name,
      value: percent,
      current: earnedHighest,
      next: nextTarget,
      currentOutOf: outOf,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
          color: Colors.black87,
        ),
        title: const Text(
          'Rewards & Certification',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorRow(_error!)
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                // ---- Donor dropdown (grouped by name)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedKey,
                      hint: const Text('Select donor'),
                      icon: const Icon(Icons.arrow_drop_down),
                      isExpanded: true,
                      items: _keys
                          .map(
                            (k) => DropdownMenuItem<String>(
                              value: k,
                              child: Text(
                                _groups[k]!.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (k) {
                        if (k == null) return;
                        _selectedKey = k;
                        _applySelection(k);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Donor Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 10),

                // ---- Progress card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, size: 50, color: navy),
                      const SizedBox(height: 8),
                      Text(
                        _progress?.label ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress?.value ?? 0.0,
                          minHeight: 14,
                          color: navy,
                          backgroundColor: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _progress?.currentOutOf ?? _money.format(0),
                        style: const TextStyle(
                          fontSize: 14,
                          color: subtitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Donor Achievements',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 12),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tiers
                        .map((t) {
                          final earnedOn = _earnedDates[t.key];
                          final isEarned = earnedOn != null;
                          final isUnlocked = !isEarned && _total >= t.threshold;
                          final statusText = isEarned
                              ? 'Earned on ${_dateFmt.format(earnedOn)}'
                              : isUnlocked
                              ? 'Unlocked'
                              : 'Locked';
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _AchievementCard(
                              title: t.name,
                              subtitle: statusText,
                              color: t.badgeColor,
                              status: isEarned
                                  ? 'earned'
                                  : isUnlocked
                                  ? 'unlocked'
                                  : 'locked',
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
    );
  }

  // ---- utils
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  DateTime _parseDt(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}

/* ---------- UI bits ---------- */

class _ErrorRow extends StatelessWidget {
  final String message;
  const _ErrorRow(this.message);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String status; // 'earned' | 'unlocked' | 'locked'
  const _AchievementCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = status == 'unlocked' || status == 'earned';
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events, size: 45, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF0F2D50),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? Colors.green : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
