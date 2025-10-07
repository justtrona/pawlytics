import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardsCertification extends StatefulWidget {
  const RewardsCertification({super.key});

  @override
  State<RewardsCertification> createState() => _RewardsCertificationState();
}

/* ====================== Models ====================== */

class _Tier {
  final String name;
  final String key;
  final int threshold;
  final Color badgeColor;

  const _Tier({
    required this.name,
    required this.key,
    required this.threshold,
    required this.badgeColor,
  });
}

class _TierProgress {
  final String label;
  final double value;
  final _Tier? current;
  final _Tier? next;
  final String currentOutOf;

  const _TierProgress({
    required this.label,
    required this.value,
    required this.current,
    required this.next,
    required this.currentOutOf,
  });
}

class _DonorGroup {
  final String key;
  String label;
  double total = 0.0;
  final Map<String, DateTime?> earnedDates;

  _DonorGroup({
    required this.key,
    required this.label,
    required List<_Tier> tiers,
  }) : earnedDates = {for (final t in tiers) t.key: null};
}

class _CertificateRecord {
  final String recipient;
  final String title;
  final DateTime createdAt;

  _CertificateRecord(this.recipient, this.title, this.createdAt);
}

/* ====================== Page ====================== */

class _RewardsCertificationState extends State<RewardsCertification> {
  static const navy = Color(0xFF0F2D50);
  static const subtitle = Color(0xFF6E7B8A);
  static const bg = Color(0xFFF6F7F9);

  final _sb = Supabase.instance.client;

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

  String _orgName = 'Pawlytics';
  String _signName = 'Jane D. Admin';
  String _signTitle = 'Executive Director';

  bool _loading = true;
  String? _error;

  final Map<String, _DonorGroup> _groups = {};
  List<String> _keys = [];
  String? _selectedKey;

  double _total = 0.0;
  Map<String, DateTime?> _earnedDates = {};
  _TierProgress? _progress;
  final List<_CertificateRecord> _certs = [];

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

  /* ====================== Data Loading ====================== */

  Future<void> _loadAndGroup() async {
    setState(() {
      _loading = true;
      _error = null;
      _groups.clear();
      _keys.clear();
      _certs.clear();
    });

    try {
      final rows = await _sb
          .from('donations')
          .select('donor_name, donation_date, amount')
          .order('donation_date', ascending: true);

      for (final r in rows as List) {
        final rawName = (r['donor_name'] ?? '').toString().trim();
        if (rawName.isEmpty) continue;

        final key = rawName.toLowerCase();
        final dt = _parseDt(r['donation_date']);
        final amt = _toDouble(r['amount']);

        _groups.putIfAbsent(
          key,
          () => _DonorGroup(key: key, label: rawName, tiers: _tiers),
        );
        final g = _groups[key]!;

        if (amt > 0) {
          g.total += amt;
          for (final t in _tiers) {
            if (g.earnedDates[t.key] == null && g.total >= t.threshold) {
              g.earnedDates[t.key] = dt;
            }
          }
        }
      }

      final list = _groups.values.toList()
        ..sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
        );
      _keys = list.map((g) => g.key).toList();

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
    _loadCertificatesForSelected();
    setState(() {});
  }

  _Tier? _highestTierFor(String key) {
    final g = _groups[key];
    if (g == null) return null;
    _Tier? earned;
    for (final t in _tiers) {
      if (g.earnedDates[t.key] != null) earned = t;
    }
    return earned;
  }

  String? _selectedDonorLabel() =>
      _selectedKey == null ? null : _groups[_selectedKey!]?.label;

  Future<void> _loadCertificatesForSelected() async {
    if (_selectedKey == null) return;
    final donor = _groups[_selectedKey!]!.label;

    final rows = await _sb
        .from('certificates_issued')
        .select()
        .eq('donor_name', donor);
    _certs
      ..clear()
      ..addAll(
        rows.map(
          (r) => _CertificateRecord(
            r['donor_name'],
            r['tier_key'] ?? 'Certificate',
            DateTime.tryParse(r['issued_at'] ?? '') ?? DateTime.now(),
          ),
        ),
      );
    setState(() {});
  }

  /* ====================== Tier Progress ====================== */

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

    final prev = (earnedHighest?.threshold ?? 0).toDouble();
    final span = (nextTarget.threshold - prev).toDouble();
    final into = (total - prev).clamp(0.0, span);
    final pct = span == 0 ? 0.0 : (into / span).clamp(0.0, 1.0);

    return _TierProgress(
      label: nextTarget.name,
      value: pct,
      current: earnedHighest,
      next: nextTarget,
      currentOutOf:
          '${_money.format(total)} out of ${_money.format(nextTarget.threshold)}',
    );
  }

  Future<void> _showCreateDialog({
    String? initialTitle,
    String? initialBody,
    String? initialOrgName,
    String? initialSignName,
    String? initialSignTitle,
  }) async {
    final recipient = _selectedDonorLabel();
    if (recipient == null || recipient.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a donor first.')));
      return;
    }

    final titleCtl = TextEditingController(
      text:
          initialTitle ??
          (_selectedKey != null
              ? (_highestTierFor(_selectedKey!)?.name ??
                    'Certificate of Appreciation')
              : 'Certificate of Appreciation'),
    );
    final bodyCtl = TextEditingController(
      text:
          initialBody ??
          'In grateful recognition of your generous support to our organization.',
    );
    final orgCtl = TextEditingController(text: initialOrgName ?? _orgName);
    final signNameCtl = TextEditingController(
      text: initialSignName ?? _signName,
    );
    final signTitleCtl = TextEditingController(
      text: initialSignTitle ?? _signTitle,
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create certificate'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recipient: $recipient',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleCtl,
                decoration: const InputDecoration(
                  labelText: 'Certificate title',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyCtl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Body text'),
              ),
              const Divider(height: 18),
              TextField(
                controller: orgCtl,
                decoration: const InputDecoration(
                  labelText: 'Organization name',
                ),
              ),
              TextField(
                controller: signNameCtl,
                decoration: const InputDecoration(labelText: 'Signatory name'),
              ),
              TextField(
                controller: signTitleCtl,
                decoration: const InputDecoration(labelText: 'Signatory title'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _createCertificatePdfAndStore(
                recipient: recipient,
                title: titleCtl.text.trim(),
                body: bodyCtl.text.trim(),
                orgName: orgCtl.text.trim(),
                signName: signNameCtl.text.trim(),
                signTitle: signTitleCtl.text.trim(),
                donorKey: _selectedKey,
              );
              if (mounted) Navigator.pop(ctx);
              await _loadCertificatesForSelected();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /* ====================== Certificate Logic ====================== */

  Future<void> _createCertificatePdfAndStore({
    required String recipient,
    required String title,
    required String body,
    required String orgName,
    required String signName,
    required String signTitle,
    String? donorKey,
  }) async {
    try {
      final tierKey = _tiers
          .firstWhere(
            (t) => t.name == title,
            orElse: () => const _Tier(
              name: 'Appreciation',
              key: 'appreciation',
              threshold: 0,
              badgeColor: Colors.blueGrey,
            ),
          )
          .key;

      // Prevent duplicates
      final existing = await _sb
          .from('certificates_issued')
          .select()
          .eq('donor_name', recipient)
          .eq('tier_key', tierKey)
          .maybeSingle();

      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $recipient already has a $tierKey certificate.'),
          ),
        );
        return;
      }

      // Ensure donor reached the tier
      final donor = _groups[donorKey];
      if (donor == null) throw 'Donor not found.';
      final tier = _tiers.firstWhere((t) => t.key == tierKey);
      if (donor.total < tier.threshold) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ $recipient has not yet reached ₱${tier.threshold} for $tierKey.',
            ),
          ),
        );
        return;
      }

      final pdfUrl = 'https://example.com/certs/${recipient}_$tierKey.pdf';

      await _sb.from('certificates_issued').insert({
        'user_id': _sb.auth.currentUser?.id,
        'donor_name': recipient,
        'tier_key': tierKey,
        'amount': donor.total,
        'issued_at': DateTime.now().toIso8601String(),
        'pdf_url': pdfUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Certificate created for $recipient ($tierKey).'),
        ),
      );
      _certs.add(_CertificateRecord(recipient, title, DateTime.now()));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating certificate: $e')));
    }
  }

  Future<void> _bulkCreateForAll() async {
    if (_groups.isEmpty) return;
    final org = _orgName;
    final sName = _signName;
    final sTitle = _signTitle;
    const body = 'In grateful recognition of your generous support.';

    final existingRows = await _sb
        .from('certificates_issued')
        .select('donor_name, tier_key');
    final existingSet = {
      for (final r in existingRows) '${r['donor_name']}_${r['tier_key']}',
    };
    int createdCount = 0;

    for (final g in _groups.values) {
      final tier = _highestTierFor(g.key);
      if (tier == null) continue;
      final comboKey = '${g.label}_${tier.key}';
      if (existingSet.contains(comboKey)) continue;

      await _createCertificatePdfAndStore(
        recipient: g.label,
        title: tier.name,
        body: body,
        orgName: org,
        signName: sName,
        signTitle: sTitle,
        donorKey: g.key,
      );
      createdCount++;
    }

    await _loadCertificatesForSelected();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Bulk creation complete. $createdCount new certificates issued.',
          ),
        ),
      );
    }
  }

  /* ====================== UI ====================== */

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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorRow(_error!)
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _buildDonorDropdown(),
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
                _buildProgressCard(),
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
                _buildAchievements(),
                const SizedBox(height: 14),
                _buildActionsRow(),
                const SizedBox(height: 18),
                const Text(
                  'Certificates',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCertificatesList(),
              ],
            ),
    );
  }

  Widget _buildDonorDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedKey,
          hint: const Text('Select donor'),
          isExpanded: true,
          items: _keys
              .map(
                (k) => DropdownMenuItem<String>(
                  value: k,
                  child: Text(
                    _groups[k]!.label,
                    style: const TextStyle(fontSize: 16),
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
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
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
          LinearProgressIndicator(
            value: _progress?.value ?? 0.0,
            minHeight: 14,
            color: navy,
            backgroundColor: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            _progress?.currentOutOf ?? _money.format(0),
            style: const TextStyle(fontSize: 14, color: subtitle),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tiers.map((t) {
          final earnedOn = _earnedDates[t.key];
          final isEarned = earnedOn != null;
          final statusText = isEarned
              ? 'Earned on ${_dateFmt.format(earnedOn)}'
              : _total >= t.threshold
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
                  : _total >= t.threshold
                  ? 'unlocked'
                  : 'locked',
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionsRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('Create certificate'),
            onPressed: () {
              if (_selectedKey == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select a donor first.')),
                );
                return;
              }
              final tier = _highestTierFor(_selectedKey!);
              final defaultTitle = tier?.name ?? 'Certificate of Appreciation';
              final defaultBody =
                  'In grateful recognition of your generous support to our organization.';
              _showCreateDialog(
                initialTitle: defaultTitle,
                initialBody: defaultBody,
                initialOrgName: _orgName,
                initialSignName: _signName,
                initialSignTitle: _signTitle,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.add_to_photos_rounded),
            label: const Text('Bulk create (all)'),
            onPressed: _groups.isEmpty ? null : _bulkCreateForAll,
          ),
        ),
      ],
    );
  }

  Widget _buildCertificatesList() {
    if (_certs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('No certificates yet.'),
      );
    }
    return Column(
      children: _certs
          .map(
            (c) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${c.recipient} • ${_dateFmt.format(c.createdAt)}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  double _toDouble(dynamic v) => v == null
      ? 0.0
      : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);

  DateTime _parseDt(dynamic v) => v == null
      ? DateTime.now()
      : (v is DateTime ? v : DateTime.tryParse(v.toString()) ?? DateTime.now());
}

/* ====================== Small UI Components ====================== */

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
  final String status;
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
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
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
