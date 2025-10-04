// lib/views/admin/campaigns/campaign-details.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawlytics/views/admin/model/campaigns-model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampaignDetails extends StatefulWidget {
  const CampaignDetails({super.key, required this.campaign});
  final Campaign campaign;

  @override
  State<CampaignDetails> createState() => _CampaignDetailsState();
}

class _CampaignDetailsState extends State<CampaignDetails> {
  // ---- Palette & sizing to match CampaignSettingsScreen ----
  static const brand = Color(0xFF27374D);
  static const brandDark = Color(0xFF1B2A3A);
  static const line = Color(0xFFE6EDF4);
  static const textMuted = Color(0xFF6A7886);

  static const double kSectionGap = 20;
  static const double kFieldGap = 12;
  static const double kControlHeight = 48;
  static const EdgeInsets kScreenPadding = EdgeInsets.fromLTRB(16, 12, 16, 120);

  // ---- Totals from campaigns_with_totals ----
  bool _loadingTotals = true;
  String? _totalsError;
  double _raised = 0.0;
  double _progress = 0.0; // 0..1

  // ---- Editable form state ----
  final _formKey = GlobalKey<FormState>();

  late String _program;
  late String _category;
  late String _currency;
  late bool _notifyAt75;

  // status dropdown stores Active/Inactive; "Due" is computed from deadline
  late String _status; // 'Active' | 'Inactive'
  DateTime? _deadline;

  final _goalCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();

    final c = widget.campaign;
    _program = c.program;
    _category = c.category;
    _currency = c.currency;

    // --------- NO JSON: read directly from known fields with safe fallbacks ----------
    _notifyAt75 = _notifyFromModel(c);
    final bool isActive = _isActiveFromModel(c);

    _goalCtrl.text = _formatGoal(c.fundraisingGoal);
    _descCtrl.text = c.description;

    _deadline = c.deadline;
    _deadlineCtrl.text = DateFormat(
      'MM/dd/yyyy',
    ).format(_deadline ?? DateTime.now());

    _status = isActive ? 'Active' : 'Inactive';

    _loadTotals();
  }

  @override
  void dispose() {
    _goalCtrl.dispose();
    _deadlineCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /* ===================== DIRECT FIELD HELPERS (no json) ===================== */

  bool _notifyFromModel(Campaign c) {
    // Try common field names on your model without using toJson/map
    try {
      final v = (c as dynamic).notifyAt75;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
    } catch (_) {}
    try {
      final v = (c as dynamic).notify_at_75;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
    } catch (_) {}
    return true; // sensible default
  }

  bool _isActiveFromModel(Campaign c) {
    // Prefer an explicit boolean if the model has it
    try {
      final v = (c as dynamic).isActive;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
    } catch (_) {}
    try {
      final v = (c as dynamic).is_active;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
    } catch (_) {}

    // Or derive from status string if present
    try {
      final s = ((c as dynamic).status as String?)?.toLowerCase() ?? '';
      if (s.isNotEmpty) return s == 'active';
    } catch (_) {}

    // Fallback: deadline-based
    return !c.deadline.isBefore(DateTime.now());
  }

  String _formatGoal(num v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final re = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${parts[0].replaceAllMapped(re, (m) => ',')}.${parts[1]}';
  }

  num _parseGoal(String s) => num.tryParse(s.replaceAll(',', '')) ?? 0;

  String _money(num v) {
    final s = v.toStringAsFixed(0);
    final re = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '$_currency ${s.replaceAllMapped(re, (m) => ',')}';
  }

  String get _computedStatus {
    if (_deadline != null && _deadline!.isBefore(DateTime.now())) return 'Due';
    return _status; // Active/Inactive
  }

  OutlineInputBorder _border([Color? c]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c ?? Colors.blueGrey.shade200, width: 1),
  );

  InputDecoration _dec({
    String? label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefix: prefix,
      filled: true,
      fillColor: Colors.blueGrey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: _border(),
      focusedBorder: _border(Colors.blueGrey.shade400),
    );
  }

  SizedBox get _vGap => const SizedBox(height: kSectionGap);
  SizedBox get _hGap => const SizedBox(width: kFieldGap);

  /* ===================== Totals fetch ===================== */

  Future<void> _loadTotals() async {
    setState(() {
      _loadingTotals = true;
      _totalsError = null;
    });

    try {
      final row = await Supabase.instance.client
          .from('campaigns_with_totals')
          .select('id, raised_amount, progress_ratio, currency')
          .eq('id', widget.campaign.id)
          .maybeSingle();

      final m = (row as Map<String, dynamic>?) ?? const <String, dynamic>{};

      double raised = 0;
      double progress = 0;
      if (m['raised_amount'] != null) {
        raised = (m['raised_amount'] as num).toDouble();
      }
      if (m['progress_ratio'] != null) {
        progress = (m['progress_ratio'] as num).toDouble();
        if (progress > 1) progress = (progress / 100).clamp(0, 1);
      }
      if (m['currency'] is String && (m['currency'] as String).isNotEmpty) {
        _currency = m['currency'] as String;
      }

      if (!mounted) return;
      setState(() {
        _raised = raised;
        _progress = progress.clamp(0.0, 1.0);
        _loadingTotals = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _totalsError = '${e.code}: ${e.message}';
        _loadingTotals = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _totalsError = e.toString();
        _loadingTotals = false;
      });
    }
  }

  /* ===================== Actions ===================== */

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _deadline ?? now,
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: brand)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
        _deadlineCtrl.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final goal = _parseGoal(_goalCtrl.text);
    if (goal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a valid fundraising goal.')),
      );
      return;
    }
    if (_deadline == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick a deadline.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final isActive = (_status == 'Active');

      final payload = <String, dynamic>{
        'program': _program,
        'category': _category,
        'fundraising_goal': goal,
        'deadline': _deadline!.toIso8601String(),
        'currency': _currency,
        'description': _descCtrl.text,
        'notify_at_75': _notifyAt75,
        'is_active': isActive,
        // If your table doesn't have 'status', PostgREST will error; we catch & soften it.
        'status': _computedStatus.toLowerCase(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('campaigns')
          .update(payload)
          .eq('id', widget.campaign.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Campaign updated')));
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      final friendly = e.code == '42703'
          ? 'Some fields (e.g. status) do not exist in the campaigns table. Other fields were saved.'
          : e.message;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $friendly')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete campaign?'),
        content: const Text(
          'This will permanently remove the campaign. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) _delete();
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await Supabase.instance.client
          .from('campaigns')
          .delete()
          .eq('id', widget.campaign.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Campaign deleted')));
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  /* ===================== UI ===================== */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text('Campaign'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: line),
        ),
      ),

      // Bottom actions
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _deleting ? null : _confirmDelete,
                icon: _deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                label: Text(_deleting ? 'Deleting…' : 'Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(120, kControlHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(120, kControlHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: kScreenPadding,
            children: [
              // ===== Support so far =====
              if (_loadingTotals)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_totalsError != null)
                _TotalsError(message: _totalsError!, onRetry: _loadTotals)
              else
                _TotalsCard(
                  progress: _progress,
                  raisedLabel:
                      '${_money(_raised)} of ${_money(_parseGoal(_goalCtrl.text))}',
                  onRefresh: _loadTotals,
                ),

              const SizedBox(height: 16),

              // Program
              _sectionLabel('Default Program'),
              DropdownButtonFormField<String>(
                value: _program,
                borderRadius: BorderRadius.circular(12),
                decoration: _dec(),
                items: const [
                  DropdownMenuItem(
                    value: 'Shelters Improvement',
                    child: Text('Shelters Improvement'),
                  ),
                  DropdownMenuItem(value: 'Surgery', child: Text('Surgery')),
                  DropdownMenuItem(
                    value: 'Dog Pound',
                    child: Text('Dog Pound'),
                  ),
                  DropdownMenuItem(value: 'Rescue', child: Text('Rescue')),
                  DropdownMenuItem(
                    value: 'Stray Animals',
                    child: Text('Stray Animals'),
                  ),
                  DropdownMenuItem(
                    value: 'Vaccination',
                    child: Text('Vaccination'),
                  ),
                  DropdownMenuItem(
                    value: 'Spay/Neuter',
                    child: Text('Spay/Neuter'),
                  ),
                  DropdownMenuItem(value: 'Pet Food', child: Text('Pet Food')),
                  DropdownMenuItem(
                    value: 'Medical Supplies',
                    child: Text('Medical Supplies'),
                  ),
                  DropdownMenuItem(
                    value: 'Outreach and Awareness',
                    child: Text('Outreach and Awareness'),
                  ),
                ],
                onChanged: (v) => setState(() => _program = v!),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Program is required' : null,
              ),

              _vGap,

              // Category
              _sectionLabel('Category'),
              DropdownButtonFormField<String>(
                value: _category,
                borderRadius: BorderRadius.circular(12),
                decoration: _dec(),
                items: const [
                  DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                  DropdownMenuItem(
                    value: 'Medical Care',
                    child: Text('Medical Care'),
                  ),
                  DropdownMenuItem(
                    value: 'Food and Care',
                    child: Text('Food and Care'),
                  ),
                  DropdownMenuItem(
                    value: 'Emergency Care',
                    child: Text('Emergency Care'),
                  ),
                  DropdownMenuItem(
                    value: 'Community and Advocacy',
                    child: Text('Community and Advocacy'),
                  ),
                ],
                onChanged: (v) => setState(() => _category = v!),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Category is required' : null,
              ),

              _vGap,

              // Status + Current (with Due)
              _sectionLabel('Status'),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: _dec(
                        hint: 'Select status',
                        prefixIcon: const Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 'Active'),
                    ),
                  ),
                  _hGap,
                  Container(
                    height: kControlHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: brand),
                        const SizedBox(width: 8),
                        Text(
                          'Current: $_computedStatus',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              _vGap,

              // Goal
              _sectionLabel('Fundraising Goal'),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: kControlHeight,
                      child: TextFormField(
                        controller: _goalCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _dec(
                          prefixIcon: const Icon(Icons.payments_outlined),
                          prefix: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 4),
                            child: Text(
                              '$_currency ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        validator: (v) => (_parseGoal(v ?? '') <= 0)
                            ? 'Enter a valid amount'
                            : null,
                      ),
                    ),
                  ),
                  _hGap,
                  ElevatedButton(
                    style: _primaryBtn,
                    onPressed: () => setState(() {}),
                    child: const Text('Set Goal'),
                  ),
                ],
              ),

              _vGap,

              // Deadline + Currency
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: kControlHeight,
                      child: TextFormField(
                        controller: _deadlineCtrl,
                        readOnly: true,
                        onTap: _pickDeadline,
                        decoration: _dec(
                          label: 'Deadline',
                          hint: 'MM/DD/YYYY',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                    ),
                  ),
                  _hGap,
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      borderRadius: BorderRadius.circular(12),
                      decoration: _dec(label: 'Currency'),
                      items: const [
                        DropdownMenuItem(value: 'PHP', child: Text('PHP')),
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      ],
                      onChanged: (v) => setState(() => _currency = v ?? 'PHP'),
                    ),
                  ),
                ],
              ),

              _vGap,

              // Description
              _sectionLabel('Description'),
              TextFormField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 6,
                maxLength: 500,
                decoration: _dec(
                  hint: 'Tell donors what this campaign is about…',
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),

              _vGap,

              // Progress tracker
              Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress Tracker',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _notifyAt75,
                      onChanged: (v) =>
                          setState(() => _notifyAt75 = v ?? false),
                      title: const Text(
                        'Notify When 75% Goal Reached: Enable goal notifications',
                        style: TextStyle(height: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ======= Small UI helpers ======= */

  ButtonStyle get _primaryBtn => ElevatedButton.styleFrom(
    backgroundColor: brand,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    minimumSize: const Size(120, kControlHeight),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    ),
  );
}

/* === Reusable parts === */

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.progress,
    required this.raisedLabel,
    required this.onRefresh,
  });

  final double progress;
  final String raisedLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _CampaignDetailsState.line),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.volunteer_activism_rounded,
                color: _CampaignDetailsState.brand,
              ),
              SizedBox(width: 8),
              Text(
                'Support so far',
                style: TextStyle(
                  color: _CampaignDetailsState.brandDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.blueGrey.shade50,
                  color: _CampaignDetailsState.brand,
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  raisedLabel,
                  style: const TextStyle(
                    color: _CampaignDetailsState.brand,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalsError extends StatelessWidget {
  const _TotalsError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
