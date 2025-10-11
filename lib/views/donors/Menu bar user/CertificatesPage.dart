// certificates_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificatesPage extends StatefulWidget {
  /// Optional override. If null, we resolve from Supabase auth (donor_name -> full_name -> email).
  final String? donorName;
  const CertificatesPage({super.key, this.donorName});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _Tier {
  final String key;
  final String title;
  final int threshold;
  final Color bg;
  final String assetPath;
  const _Tier({
    required this.key,
    required this.title,
    required this.threshold,
    required this.bg,
    required this.assetPath,
  });
}

const _tiers = <_Tier>[
  _Tier(
    key: 'bronze',
    title: 'Bronze Certificate',
    threshold: 5000,
    bg: Color(0xFFFFF3E0),
    assetPath: 'assets/images/donors/bronze.png',
  ),
  _Tier(
    key: 'silver',
    title: 'Silver Certificate',
    threshold: 10000,
    bg: Color(0xFFE0E0E0),
    assetPath: 'assets/images/donors/silver.png',
  ),
  _Tier(
    key: 'gold',
    title: 'Gold Certificate',
    threshold: 20000,
    bg: Color(0xFFFFF9C4),
    assetPath: 'assets/images/donors/gold.png',
  ),
  _Tier(
    key: 'platinum',
    title: 'Platinum Certificate',
    threshold: 30000,
    bg: Color(0xFFEDE7F6),
    assetPath: 'assets/images/donors/silver.png',
  ),
  _Tier(
    key: 'diamond',
    title: 'Diamond Certificate',
    threshold: 40000,
    bg: Color(0xFFE0F7FA),
    assetPath: 'assets/images/donors/diamond.png',
  ),
];

class _CertificatesPageState extends State<CertificatesPage> {
  static const navy = Color(0xFF1F2C47);
  final _sb = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  int _total = 0;
  final Map<String, Map<String, dynamic>> _issuedByTier = {};
  String _resolvedDonorName = '';
  String _resolvedUserId = '';

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
  }

  String _norm(String s) => s.trim().toLowerCase();

  bool _matchesRow(Map r, String userId, String donorKey) {
    final rid = (r['user_id'] ?? '').toString();
    if (rid.isNotEmpty && userId.isNotEmpty && rid == userId) return true;

    final dn = (r['donor_name'] ?? r['name'] ?? '').toString();
    if (dn.isNotEmpty && _norm(dn) == donorKey) return true;

    final em = (r['donor_email'] ?? r['email'] ?? '').toString();
    if (em.isNotEmpty && _norm(em) == donorKey) return true;

    return false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _issuedByTier.clear();
      _total = 0;
      _resolvedDonorName = '';
      _resolvedUserId = '';
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

      // Sum donations
      final donRows = await _sb.from('donations').select('*');
      int sum = 0;
      for (final e in donRows as List) {
        final r = Map<String, dynamic>.from(e as Map);
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

      // Read issued certificates (normalized tier_key)
      final certRows = await _sb.from('certificates_issued').select('*');
      for (final e in certRows as List) {
        final r = Map<String, dynamic>.from(e as Map);
        if (!_matchesRow(r, _resolvedUserId, donorKey)) continue;

        final tierKey = (r['tier_key'] ?? '').toString().toLowerCase().trim();
        if (tierKey.isEmpty) continue;
        _issuedByTier[tierKey] = {
          'pdf_url': (r['pdf_url'] ?? '').toString(),
          'issued_at': DateTime.tryParse((r['issued_at'] ?? '').toString()),
        };
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isEarned(_Tier t) => _total >= t.threshold;

  double _progressValue(_Tier t) =>
      _isEarned(t) ? 1.0 : (_total / t.threshold).clamp(0.0, 1.0);

  String _subtitleOf(_Tier t) {
    if (_isEarned(t)) {
      final issuedAt = _issuedByTier[t.key]?['issued_at'] as DateTime?;
      return issuedAt != null
          ? 'Earned on ${_dateFmt.format(issuedAt)}'
          : 'Achieved';
    }
    if (t.key == 'silver') {
      return '${_money.format(_total)} out of ${_money.format(t.threshold)}';
    }
    final remain = t.threshold - _total;
    return '${_money.format(remain)} to Unlock This Achievement';
  }

  String? _extraTextOf(_Tier t) {
    if (!_isEarned(t) && t.key == 'silver') {
      final remain = t.threshold - _total;
      return "You're Almost There! Just Add ${_money.format(remain)} to unlock this achievement.";
    }
    return null;
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
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
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemCount: _tiers.length,
              itemBuilder: (_, i) {
                final t = _tiers[i];
                final isEarned = _isEarned(t);

                final issued = _issuedByTier[t.key];
                final pdfUrl = (issued?['pdf_url'] ?? '').toString();
                final hasPdf = pdfUrl.isNotEmpty;

                final buttons = <Widget>[];
                if (isEarned) {
                  buttons.add(
                    _actionBtn(
                      text: hasPdf ? 'Preview' : 'No File Yet',
                      bgColor: hasPdf ? Colors.white : Colors.grey.shade300,
                      textColor: hasPdf ? navy : Colors.black45,
                      outlined: true,
                      onTap: hasPdf
                          ? () => _openUrl(pdfUrl)
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Certificate not issued yet.'),
                              ),
                            ),
                    ),
                  );
                  buttons.add(
                    _actionBtn(
                      text: 'Download',
                      bgColor: hasPdf ? navy : Colors.grey.shade400,
                      textColor: Colors.white,
                      onTap: hasPdf
                          ? () => _openUrl(pdfUrl)
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No PDF available yet.'),
                              ),
                            ),
                    ),
                  );
                }

                return _certCard(
                  asset: t.assetPath,
                  title: t.title,
                  subtitle: _subtitleOf(t),
                  background: t.bg,
                  progress: _progressValue(t),
                  extraText: _extraTextOf(t),
                  buttons: buttons.isEmpty ? null : buttons,
                  dimIfLocked: !isEarned,
                );
              },
            ),
    );
  }

  Widget _certCard({
    required String asset,
    required String title,
    required String subtitle,
    required Color background,
    required double progress,
    String? extraText,
    List<Widget>? buttons,
    bool dimIfLocked = false,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(minHeight: 150),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(asset, width: 100, height: 100, fit: BoxFit.contain),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    color: navy,
                    backgroundColor: Colors.white,
                    minHeight: 8,
                  ),
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
                if (extraText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    extraText,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
                if (buttons != null && buttons.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: buttons),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return dimIfLocked ? Opacity(opacity: 0.95, child: card) : card;
  }

  Widget _actionBtn({
    required String text,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return ElevatedButton.icon(
      icon: Icon(
        text == 'Preview' ? Icons.visibility : Icons.download,
        size: 16,
        color: textColor,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: outlined
              ? BorderSide(color: textColor, width: 1)
              : BorderSide.none,
        ),
        elevation: 0,
      ),
      onPressed: onTap,
      label: Text(text, style: TextStyle(color: textColor, fontSize: 12)),
    );
  }
}

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
