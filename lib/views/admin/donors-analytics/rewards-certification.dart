import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;

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
  final String title; // e.g., Gold Certificate
  final String tierKey; // gold/silver/...
  final DateTime createdAt;
  final String pdfUrl; // direct link to PDF
  _CertificateRecord({
    required this.recipient,
    required this.title,
    required this.tierKey,
    required this.createdAt,
    required this.pdfUrl,
  });
}

class _CertTemplate {
  final int id;
  final String name;
  final String? tierKey;
  final String? backgroundUrl;
  final String? title;
  final String? bodyTemplate;
  final String? signatureName;
  const _CertTemplate({
    required this.id,
    required this.name,
    this.tierKey,
    this.backgroundUrl,
    this.title,
    this.bodyTemplate,
    this.signatureName,
  });
}

/* ====================== Page ====================== */

class _RewardsCertificationState extends State<RewardsCertification> {
  static const navy = Color(0xFF0F2D50);
  static const subtitle = Color(0xFF6E7B8A);
  static const bg = Color(0xFFF6F7F9);

  final _sb = Supabase.instance.client;

  // Tiers (MATCH donor page: 5k / 10k / 20k / 30k / 40k)
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
      threshold: 10000,
      badgeColor: Colors.grey,
    ),
    _Tier(
      name: 'Gold Certificate',
      key: 'gold',
      threshold: 20000,
      badgeColor: Colors.amber,
    ),
    _Tier(
      name: 'Platinum Certificate',
      key: 'platinum',
      threshold: 30000,
      badgeColor: Color(0xFF9C27B0),
    ),
    _Tier(
      name: 'Diamond Certificate',
      key: 'diamond',
      threshold: 40000,
      badgeColor: Color(0xFF00B8D9),
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

  // Templates (optional)
  final List<_CertTemplate> _templates = [];

  // Org summary
  final Map<String, int> _tierCounts = {};
  final Map<String, List<String>> _tierRecipients = {};
  DateTimeRange? _summaryRange;
  bool _summaryLoading = false;
  String? _summaryError;

  final _money = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 0,
  );
  final _dateFmt = DateFormat('MMMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() => _loading = true);
    try {
      await _loadTemplates(); // 1) templates (optional)
      await _loadAndGroup(); // 2) compute donor totals
      await _autoIssueForAll(); // 3) ISSUE missing certs (will insert even if PDF upload fails)
      await _loadCertificatesForSelected(); // 4) refresh visible donor certs
      await _loadSummary(); // 5) summary
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ====================== Data Loading ====================== */

  Future<void> _loadAndGroup() async {
    _groups.clear();
    _keys.clear();
    _certs.clear();

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
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    _keys = list.map((g) => g.key).toList();

    if (_keys.isNotEmpty) {
      _selectedKey = _keys.first;
      _applySelection(_selectedKey!);
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final rows = await _sb
          .from('certificate_templates')
          .select(
            'id,name,tier_key,background_url,title,body_template,signature_name',
          )
          .order('id');

      _templates
        ..clear()
        ..addAll(
          (rows as List).map(
            (r) => _CertTemplate(
              id: r['id'] as int,
              name: (r['name'] ?? '').toString(),
              tierKey: ((r['tier_key'] ?? '').toString().isEmpty)
                  ? null
                  : (r['tier_key'] as String),
              backgroundUrl: ((r['background_url'] ?? '').toString().isEmpty)
                  ? null
                  : (r['background_url'] as String),
              title: ((r['title'] ?? '').toString().isEmpty)
                  ? null
                  : (r['title'] as String),
              bodyTemplate: ((r['body_template'] ?? '').toString().isEmpty)
                  ? null
                  : (r['body_template'] as String),
              signatureName: ((r['signature_name'] ?? '').toString().isEmpty)
                  ? null
                  : (r['signature_name'] as String),
            ),
          ),
        );
    } catch (_) {
      // optional table; ignore errors
    }
  }

  Future<void> _loadCertificatesForSelected() async {
    if (_selectedKey == null) return;
    final donor = _groups[_selectedKey!]!.label;

    final rows = await _sb
        .from('certificates_issued')
        .select('donor_name,tier_key,issued_at,pdf_url')
        .eq('donor_name', donor)
        .order('issued_at', ascending: false);

    _certs
      ..clear()
      ..addAll(
        (rows as List).map(
          (r) => _CertificateRecord(
            recipient: r['donor_name'],
            title: _tiers
                .firstWhere(
                  (t) => t.key == (r['tier_key'] ?? ''),
                  orElse: () => const _Tier(
                    name: 'Certificate',
                    key: 'certificate',
                    threshold: 0,
                    badgeColor: Colors.blueGrey,
                  ),
                )
                .name,
            tierKey: (r['tier_key'] ?? '').toString(),
            createdAt:
                DateTime.tryParse((r['issued_at'] ?? '').toString()) ??
                DateTime.now(),
            pdfUrl: (r['pdf_url'] ?? '').toString(),
          ),
        ),
      );
    setState(() {});
  }

  void _applySelection(String key) {
    final g = _groups[key]!;
    _total = g.total;
    _earnedDates = g.earnedDates;
    _progress = _computeProgress(_total);
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

  /* ====================== AUTO Issue Certificates ====================== */

  Future<void> _autoIssueForAll() async {
    // Fetch all existing cert rows once
    final existingRows = await _sb
        .from('certificates_issued')
        .select('donor_name,tier_key');

    final existingSet = <String>{};
    for (final r in existingRows as List) {
      final name = (r['donor_name'] ?? '').toString();
      final tier = (r['tier_key'] ?? '').toString();
      if (name.isEmpty || tier.isEmpty) continue;
      existingSet.add('${name.toLowerCase()}_$tier');
    }

    // For every donor, if they earned a tier but don't have a cert, create it
    for (final g in _groups.values) {
      for (final t in _tiers) {
        if (g.total < t.threshold) break; // tiers are ascending
        final key = '${g.label.toLowerCase()}_${t.key}';
        if (existingSet.contains(key)) continue; // already issued

        // Use a matching template if available
        final tpl = _templates.firstWhere(
          (tmp) => tmp.tierKey == t.key,
          orElse: () => _templates.isNotEmpty
              ? _templates.first
              : _CertTemplate(id: -1, name: '—'),
        );

        await _createCertificatePdfAndStore(
          recipient: g.label,
          title: t.name,
          body:
              tpl.bodyTemplate ??
              'In grateful recognition of your generous support to our organization.',
          orgName: _orgName,
          signName: tpl.signatureName ?? _signName,
          signTitle: _signTitle,
          donorKey: g.key,
          template: tpl.id == -1 ? null : tpl,
          silent: true, // run quietly on boot
        );

        existingSet.add(key);
      }
    }
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

  /* ====================== Certificate Logic ====================== */

  Future<void> _createCertificatePdfAndStore({
    required String recipient,
    required String title,
    required String body,
    required String orgName,
    required String signName,
    required String signTitle,
    String? donorKey,
    _CertTemplate? template,
    bool silent = false,
  }) async {
    try {
      // Resolve tier (fallback to "appreciation")
      final tier = _tiers.firstWhere(
        (t) => t.name.toLowerCase().trim() == title.toLowerCase().trim(),
        orElse: () => const _Tier(
          name: 'Appreciation',
          key: 'appreciation',
          threshold: 0,
          badgeColor: Colors.blueGrey,
        ),
      );
      final tierKey = template?.tierKey ?? tier.key;

      // Prevent duplicate donor+tier
      final existing = await _sb
          .from('certificates_issued')
          .select('id')
          .eq('donor_name', recipient)
          .eq('tier_key', tierKey)
          .maybeSingle();
      if (existing != null) {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ $recipient already has a $tierKey certificate.',
              ),
            ),
          );
        }
        return;
      }

      // Ensure donor qualifies (except appreciation)
      final donor = _groups[donorKey];
      if (donor == null) throw 'Donor not found.';
      final enforcedTier = _tiers.firstWhere(
        (t) => t.key == tierKey,
        orElse: () => const _Tier(
          name: 'Appreciation',
          key: 'appreciation',
          threshold: 0,
          badgeColor: Colors.blueGrey,
        ),
      );
      if (enforcedTier.key != 'appreciation' &&
          donor.total < enforcedTier.threshold) {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ $recipient has not yet reached ₱${enforcedTier.threshold} for $tierKey.',
              ),
            ),
          );
        }
        return;
      }

      // Build PDF
      final now = DateTime.now();
      final bgBytes = await _fetchBytesOrNull(template?.backgroundUrl);
      final pdfBytes = await _buildCertificatePdfBytes(
        orgName: orgName,
        recipient: recipient,
        title: title,
        body: body,
        signName: signName,
        signTitle: signTitle,
        issuedAt: now,
        backgroundImage: bgBytes,
      );

      // Try to upload the PDF — but **do not block issuance** if it fails.
      String pdfUrl = '';
      try {
        final safeRecipient = recipient
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .replaceAll(' ', '_');
        final fileName =
            '${safeRecipient}_${tierKey}_${now.millisecondsSinceEpoch}.pdf';
        pdfUrl = await _uploadPdfToSupabase(
          fileName: fileName,
          bytes: pdfBytes,
        );
      } catch (_) {
        // leave pdfUrl as empty -> the row will be inserted, UI will show "No file yet"
      }

      // Insert DB row **even if pdfUrl is empty**
      await _sb.from('certificates_issued').insert({
        'user_id': _sb.auth.currentUser?.id,
        'donor_name': recipient,
        'tier_key': tierKey,
        'amount': donor.total,
        'issued_at': now.toIso8601String(),
        'pdf_url': pdfUrl, // '' when upload failed
      });

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Certificate created for $recipient ($tierKey).'),
          ),
        );
      }
    } catch (e) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating certificate: $e')),
        );
      }
    }
  }

  /* ====================== PDF + Storage Helpers ====================== */

  Future<Uint8List> _buildCertificatePdfBytes({
    required String orgName,
    required String recipient,
    required String title,
    required String body,
    required String signName,
    required String signTitle,
    required DateTime issuedAt,
    Uint8List? backgroundImage,
  }) async {
    final pdf = pw.Document();
    final header = pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold);
    final big = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold);
    final normal = pw.TextStyle(fontSize: 14);
    final small = pw.TextStyle(fontSize: 12);

    pw.Widget pageContent() => pw.Stack(
      children: [
        if (backgroundImage != null)
          pw.Positioned.fill(
            child: pw.Opacity(
              opacity: 0.15,
              child: pw.Image(
                pw.MemoryImage(backgroundImage),
                fit: pw.BoxFit.cover,
              ),
            ),
          ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(48),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(orgName, style: header),
              pw.SizedBox(height: 6),
              pw.Text('Certificate', style: big),
              pw.SizedBox(height: 20),
              pw.Text(title, style: big),
              pw.SizedBox(height: 14),
              pw.Text('Awarded to', style: small),
              pw.SizedBox(height: 4),
              pw.Text(
                recipient,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(body, textAlign: pw.TextAlign.center, style: normal),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(signName, style: normal),
                      pw.Text(signTitle, style: small),
                    ],
                  ),
                  pw.Text(
                    DateFormat('MMMM d, yyyy').format(issuedAt),
                    style: small,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    pdf.addPage(pw.Page(build: (_) => pageContent()));
    return await pdf.save();
  }

  Future<Uint8List?> _fetchBytesOrNull(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) return Uint8List.fromList(res.bodyBytes);
    } catch (_) {}
    return null;
  }

  Future<String> _uploadPdfToSupabase({
    required String fileName,
    required Uint8List bytes,
  }) async {
    // PUBLIC bucket 'certificates'
    final path = 'certs/$fileName';
    await _sb.storage
        .from('certificates')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _sb.storage.from('certificates').getPublicUrl(path);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  /* ====================== Organization Summary (Admin) ====================== */

  Future<void> _loadSummary() async {
    _summaryLoading = true;
    _summaryError = null;
    _tierCounts.clear();
    _tierRecipients.clear();
    setState(() {});

    try {
      var query = _sb
          .from('certificates_issued')
          .select('donor_name,tier_key,issued_at');
      if (_summaryRange != null) {
        final since = _summaryRange!.start.toIso8601String();
        final until = _summaryRange!.end.toIso8601String();
        query = query.gte('issued_at', since).lte('issued_at', until);
      }

      final rows = await query.order('issued_at', ascending: false);

      for (final r in rows as List) {
        final tierKey = (r['tier_key'] ?? '').toString();
        final name = (r['donor_name'] ?? '').toString();
        if (tierKey.isEmpty || name.isEmpty) continue;

        _tierCounts[tierKey] = (_tierCounts[tierKey] ?? 0) + 1;
        _tierRecipients.putIfAbsent(tierKey, () => []);
        if (!_tierRecipients[tierKey]!.contains(name)) {
          _tierRecipients[tierKey]!.add(name);
        }
      }

      for (final t in _tiers) {
        _tierCounts.putIfAbsent(t.key, () => 0);
        _tierRecipients.putIfAbsent(t.key, () => []);
      }
    } catch (e) {
      _summaryError = e.toString();
    } finally {
      _summaryLoading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickSummaryRange() async {
    final now = DateTime.now();
    final initial =
        _summaryRange ??
        DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initial,
      helpText: 'Filter certificates by issue date',
    );
    if (picked != null) {
      setState(() => _summaryRange = picked);
      await _loadSummary();
    }
  }

  String _buildSummaryCsv() {
    final buffer = StringBuffer('tier_key,tier_name,count\n');
    for (final t in _tiers) {
      final count = _tierCounts[t.key] ?? 0;
      buffer.writeln('${t.key},"${t.name}",$count');
    }
    return buffer.toString();
  }

  Widget _buildSummaryHeaderRow() {
    final label = _summaryRange == null
        ? 'All time'
        : '${DateFormat('MMM d, yyyy').format(_summaryRange!.start)} – ${DateFormat('MMM d, yyyy').format(_summaryRange!.end)}';

    return Row(
      children: [
        Expanded(
          child: Text(
            'Certificates issued • $label',
            style: const TextStyle(
              color: subtitle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: _pickSummaryRange,
          tooltip: 'Date filter',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadSummary,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined),
          tooltip: 'Export CSV',
          onPressed: () async {
            try {
              final csv = _buildSummaryCsv();
              final dir = await getTemporaryDirectory();
              final file = File('${dir.path}/certificate_summary.csv');
              await file.writeAsString(csv);
              await Share.shareXFiles([
                XFile(file.path),
              ], text: 'Certificate Summary');
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
            }
          },
        ),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    if (_summaryLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_summaryError != null) return _ErrorRow(_summaryError!);

    final total = _tierCounts.values.fold<int>(0, (a, b) => a + b);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _tiers.map((t) {
        final count = _tierCounts[t.key] ?? 0;
        final pct = total == 0 ? 0.0 : (count / total);
        return Container(
          width: 180,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.military_tech, color: t.badgeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$count issued',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: pct, minHeight: 8),
              const SizedBox(height: 4),
              Text(
                total == 0
                    ? '—'
                    : '${(pct * 100).toStringAsFixed(0)}% of total',
                style: const TextStyle(fontSize: 12, color: subtitle),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
                const SizedBox(height: 24),
                const Text(
                  'Organization Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSummaryHeaderRow(),
                const SizedBox(height: 10),
                _buildSummaryGrid(),
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
                (k) => DropdownMenuItem(
                  value: k,
                  child: Text(
                    _groups[k]!.label,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
              .toList(),
          onChanged: (k) async {
            if (k == null) return;
            _selectedKey = k;
            _applySelection(k);
            await _loadCertificatesForSelected(); // refresh cert list when switching donor
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
                  : (_total >= t.threshold ? 'unlocked' : 'locked'),
            ),
          );
        }).toList(),
      ),
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
      children: _certs.map((c) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
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
                tooltip: c.pdfUrl.isEmpty ? 'No file yet' : 'Open PDF',
                onPressed: c.pdfUrl.isEmpty
                    ? null
                    : () async {
                        try {
                          await _openUrl(c.pdfUrl);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Open failed: $e')),
                          );
                        }
                      },
                icon: const Icon(Icons.download_rounded),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /* ====================== Utils ====================== */

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
