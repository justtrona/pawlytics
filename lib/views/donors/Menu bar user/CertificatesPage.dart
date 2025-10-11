// lib/views/donors/Menu bar user/CertificatesPage.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;

// Conditional import for web download
import 'helper/download_stub.dart'
    if (dart.library.html) 'helper/download_web.dart';

class CertificatesPage extends StatefulWidget {
  final String? donorName;
  const CertificatesPage({super.key, this.donorName});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

/* ==============================
   Tier class (NON-CONST version)
   ============================== */
class _Tier {
  final String key;
  final String title;
  final int threshold;
  final Color tileColor;
  final Color medalColor;

  _Tier({
    required this.key,
    required this.title,
    required this.threshold,
    required this.tileColor,
    required this.medalColor,
  });
}

final List<_Tier> _tiers = [
  _Tier(
    key: 'bronze',
    title: 'Bronze Certificate',
    threshold: 5000,
    tileColor: const Color(0xFFFFF3E0),
    medalColor: const Color(0xFFCD7F32),
  ),
  _Tier(
    key: 'silver',
    title: 'Silver Certificate',
    threshold: 10000,
    tileColor: const Color(0xFFE0E0E0),
    medalColor: const Color(0xFFB0B0B0),
  ),
  _Tier(
    key: 'gold',
    title: 'Gold Certificate',
    threshold: 20000,
    tileColor: const Color(0xFFFFF9C4),
    medalColor: const Color(0xFFFFC107),
  ),
  _Tier(
    key: 'platinum',
    title: 'Platinum Certificate',
    threshold: 30000,
    tileColor: const Color(0xFFEDE7F6),
    medalColor: const Color(0xFF9C27B0),
  ),
  _Tier(
    key: 'diamond',
    title: 'Diamond Certificate',
    threshold: 40000,
    tileColor: const Color(0xFFE0F7FA),
    medalColor: const Color(0xFF00B8D9),
  ),
];

class _CertificatesPageState extends State<CertificatesPage> {
  static const navy = Color(0xFF1F2C47);
  final _sb = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  int _total = 0;
  String _resolvedDonorName = '';
  String _resolvedUserId = '';

  final Map<String, Map<String, dynamic>> _issuedByTier = {};

  final _money = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 0,
  );
  final _dateFmt = DateFormat('MMMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _sb.removeAllChannels();
    super.dispose();
  }

  void _subscribeRealtime() {
    _sb
        .channel('public:certificates_issued')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'certificates_issued',
          callback: (_) => _load(),
        )
        .subscribe();
  }

  String _norm(String s) => s.trim().toLowerCase();

  bool _matchesRow(Map r, String userId, String donorKey) {
    final rid = (r['user_id'] ?? '').toString().trim();
    if (rid.isNotEmpty && userId.isNotEmpty && rid == userId) return true;

    final dn = (r['donor_name'] ?? r['name'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (dn.isNotEmpty && dn == donorKey) return true;

    final em = (r['donor_email'] ?? r['email'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (em.isNotEmpty && em == donorKey) return true;

    return false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _issuedByTier.clear();
      _total = 0;
    });

    try {
      final u = _sb.auth.currentUser;
      _resolvedUserId = u?.id ?? '';

      final donorRaw =
          (widget.donorName ??
                  (u?.userMetadata?['donor_name'] as String?) ??
                  (u?.userMetadata?['full_name'] as String?) ??
                  u?.email ??
                  '')
              .trim();

      if (donorRaw.isEmpty) throw 'Missing donor identity for this account.';
      _resolvedDonorName = donorRaw;
      final donorKey = _norm(donorRaw);

      // Get donations total
      final rows = await _sb.from('donations').select('*');
      int sum = 0;
      for (final e in rows as List) {
        final r = Map<String, dynamic>.from(e);
        if (!_matchesRow(r, _resolvedUserId, donorKey)) continue;
        final v = r['amount'];
        if (v is num) {
          sum += v.toInt();
        } else {
          final p = int.tryParse(v?.toString() ?? '');
          if (p != null) sum += p;
        }
      }
      _total = sum;

      // Get existing certificates
      final certRows = await _sb.from('certificates_issued').select('*');
      for (final e in certRows as List) {
        final r = Map<String, dynamic>.from(e);
        if (!_matchesRow(r, _resolvedUserId, donorKey)) continue;
        final tierKey = (r['tier_key'] ?? '').toString().toLowerCase();
        if (tierKey.isEmpty) continue;
        _issuedByTier[tierKey] = {
          'pdf_url': (r['pdf_url'] ?? '').toString(),
          'jpg_url': (r['jpg_url'] ?? '').toString(),
          'issued_at': DateTime.tryParse((r['issued_at'] ?? '').toString()),
        };
      }
      print('Loaded issued certs: $_issuedByTier');
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isEarned(_Tier t) => _total >= t.threshold;
  double _progress(_Tier t) =>
      _isEarned(t) ? 1.0 : (_total / t.threshold).clamp(0.0, 1.0);

  String _subtitle(_Tier t) {
    if (_isEarned(t)) {
      final issuedAt = _issuedByTier[t.key]?['issued_at'] as DateTime?;
      return issuedAt != null
          ? 'Earned on ${_dateFmt.format(issuedAt)}'
          : 'Achieved';
    }
    final remain = t.threshold - _total;
    return '${_money.format(remain)} to Unlock This Achievement';
  }

  String _fillBody(String? template, String name) {
    final text =
        (template ??
        'This certificate is proudly presented to {name} for your continued dedication to Pawlytics.');
    return text.replaceAll('{{name}}', name).replaceAll('{name}', name);
  }

  Future<void> _generateCertificateForTier(_Tier t) async {
    if (!_isEarned(t)) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generating certificate...')));

    try {
      // 1. Load template
      final tpl = await _sb
          .from('certificate_templates')
          .select('tier_key, background_url, body_template')
          .eq('tier_key', t.key)
          .maybeSingle();

      if (tpl == null) throw 'No template found for ${t.key}.';
      final bgUrl = (tpl['background_url'] ?? '').toString().trim();
      if (bgUrl.isEmpty) throw 'Template is missing background_url.';

      // 2. Fetch background image
      final bgResp = await http.get(Uri.parse(bgUrl));
      if (bgResp.statusCode != 200)
        throw 'Failed to load certificate background.';
      final bgBytes = bgResp.bodyBytes;

      // 3. Generate PDF & JPG
      final result = await _buildCertificateImages(
        backgroundBytes: bgBytes,
        recipient: _resolvedDonorName,
        tierTitle: t.title,
        bodyText: _fillBody(
          tpl['body_template'] as String?,
          _resolvedDonorName,
        ),
      );
      final pdfBytes = result['pdf']!;
      final jpgBytes = result['jpg']!;

      // 4. Upload both files
      final safeName = _resolvedDonorName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final pdfPath = 'certificates/${safeName}_${t.key}.pdf';
      final jpgPath = 'certificates/${safeName}_${t.key}.jpg';

      await _sb.storage
          .from('certificates')
          .uploadBinary(
            pdfPath,
            pdfBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      await _sb.storage
          .from('certificates')
          .uploadBinary(
            jpgPath,
            jpgBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final pdfUrl = _sb.storage.from('certificates').getPublicUrl(pdfPath);
      final jpgUrl = _sb.storage.from('certificates').getPublicUrl(jpgPath);

      // 5. Update DB safely
      final donorName = _resolvedDonorName;
      final existing = await _sb
          .from('certificates_issued')
          .select('id')
          .eq('donor_name', donorName)
          .eq('tier_key', t.key)
          .maybeSingle();

      if (existing == null) {
        await _sb.from('certificates_issued').insert({
          'user_id': _resolvedUserId,
          'donor_name': donorName,
          'tier_key': t.key,
          'amount': _total,
          'issued_at': DateTime.now().toIso8601String(),
          'pdf_url': pdfUrl,
          'jpg_url': jpgUrl,
        });
      } else {
        await _sb
            .from('certificates_issued')
            .update({
              'pdf_url': pdfUrl,
              'jpg_url': jpgUrl,
              'issued_at': DateTime.now().toIso8601String(),
              'amount': _total,
            })
            .eq('id', existing['id']);
      }

      // 6. Auto-download on Web
      if (kIsWeb)
        await triggerWebDownload(pdfBytes, '${safeName}_${t.key}.pdf');

      if (mounted) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Certificate generated successfully!'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  Future<Map<String, Uint8List>> _buildCertificateImages({
    required Uint8List backgroundBytes,
    required String recipient,
    required String tierTitle,
    required String bodyText,
  }) async {
    final pdf = pw.Document();
    final bg = pw.MemoryImage(backgroundBytes);

    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Stack(
          children: [
            pw.Positioned.fill(child: pw.Image(bg, fit: pw.BoxFit.cover)),
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.SizedBox(height: 40),
                    pw.Text(
                      recipient,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      bodyText,
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      tierTitle,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();

    // For now we use pdfBytes as placeholder for jpg (Flutter web limitation)
    final jpgBytes = Uint8List.fromList(pdfBytes.take(2000).toList());

    return {'pdf': pdfBytes, 'jpg': jpgBytes};
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open file.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Certificates',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemCount: _tiers.length,
              itemBuilder: (_, i) {
                final t = _tiers[i];
                final earned = _isEarned(t);
                final issued = _issuedByTier[t.key];
                final pdfUrl = (issued?['pdf_url'] ?? '').toString();
                final jpgUrl = (issued?['jpg_url'] ?? '').toString();

                return _certTile(
                  tier: t,
                  progress: _progress(t),
                  subtitle: _subtitle(t),
                  onGenerate: earned
                      ? () => _generateCertificateForTier(t)
                      : null,
                  onDownloadPdf: pdfUrl.isNotEmpty
                      ? () => _openUrl(pdfUrl)
                      : null,
                  onDownloadJpg: jpgUrl.isNotEmpty
                      ? () => _openUrl(jpgUrl)
                      : null,
                );
              },
            ),
    );
  }

  Widget _certTile({
    required _Tier tier,
    required double progress,
    required String subtitle,
    VoidCallback? onGenerate,
    VoidCallback? onDownloadPdf,
    VoidCallback? onDownloadJpg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tier.tileColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.military_tech_rounded, size: 56, color: tier.medalColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: navy,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (onGenerate != null)
                      FilledButton.icon(
                        onPressed: onGenerate,
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                        label: const Text('Generate'),
                      ),
                    if (onDownloadPdf != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: onDownloadPdf,
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 16,
                        ),
                        label: const Text('PDF'),
                      ),
                    ],
                    if (onDownloadJpg != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: onDownloadJpg,
                        icon: const Icon(Icons.image, size: 16),
                        label: const Text('JPG'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------------- Small Error Widget ---------------------- */

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;
  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
