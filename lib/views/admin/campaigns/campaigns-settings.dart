import 'package:flutter/material.dart';

class CampaignSettingsScreen extends StatefulWidget {
  const CampaignSettingsScreen({super.key});

  @override
  State<CampaignSettingsScreen> createState() => _CampaignSettingsScreenState();
}

class _CampaignSettingsScreenState extends State<CampaignSettingsScreen> {
  // Branding
  static const brand = Color(0xFF27374D);

  // Spacing & sizing
  static const double kSectionGap = 20; // vertical gap between sections
  static const double kFieldGap = 12; // horizontal gap inside rows
  static const double kControlHeight = 48; // consistent control height
  static const EdgeInsets kScreenPadding = EdgeInsets.fromLTRB(16, 12, 16, 24);

  // State
  String _program = 'All Campaigns';
  String _category = 'Urgent';
  String _currency = 'PHP';
  bool _notifyAt75 = true;

  final _goalCtrl = TextEditingController(text: '12,500.00');
  final _deadlineCtrl = TextEditingController(text: '');
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _goalCtrl.dispose();
    _deadlineCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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
      isDense: false,
    );
  }

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

  ButtonStyle get _primaryBtn => ElevatedButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        minimumSize: const Size(120, kControlHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: brand)),
        child: child!,
      ),
    );
    if (picked != null) {
      _deadlineCtrl.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {});
    }
  }

  SizedBox get _vGap => const SizedBox(height: kSectionGap);
  SizedBox get _hGap => const SizedBox(width: kFieldGap);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Campaign Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: ListView(
          padding: kScreenPadding,
          children: [
            // Default Program
            _sectionLabel('Default Program'),
            DropdownButtonFormField<String>(
              value: _program,
              borderRadius: BorderRadius.circular(12),
              decoration: _dec(),
              items: const [
                DropdownMenuItem(
                  value: 'All Campaigns',
                  child: Text('All Campaigns'),
                ),
                DropdownMenuItem(value: 'Rescue', child: Text('Rescue')),
                DropdownMenuItem(
                  value: 'Vaccination',
                  child: Text('Vaccination'),
                ),
                DropdownMenuItem(
                  value: 'Spay/Neuter',
                  child: Text('Spay/Neuter'),
                ),
              ],
              onChanged: (v) => setState(() => _program = v!),
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
                DropdownMenuItem(value: 'Medical', child: Text('Medical')),
                DropdownMenuItem(value: 'Shelter', child: Text('Shelter')),
                DropdownMenuItem(value: 'Food', child: Text('Food')),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),

            _vGap,

            // Fundraising Goal + button
            _sectionLabel('Fundraising Goal'),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: kControlHeight,
                    child: TextField(
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _hGap,
                ElevatedButton(
                  style: _primaryBtn,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Goal set to $_currency ${_goalCtrl.text}'),
                    ),
                  ),
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
                    child: TextField(
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
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
              ],
            ),

            _vGap,

            // Description
            _sectionLabel('Description'),
            TextField(
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

            // Progress tracker card
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
                  const SizedBox(height: kFieldGap),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _notifyAt75,
                    onChanged: (v) => setState(() => _notifyAt75 = v ?? false),
                    title: const Text(
                      'Notify When 75% Goal Reached: Enable goal notifications',
                      style: TextStyle(height: 1.2),
                    ),
                  ),
                  const SizedBox(height: kFieldGap),
                  ElevatedButton(
                    style: _primaryBtn,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _notifyAt75
                              ? 'Notifications enabled at 75% of goal'
                              : 'Notifications disabled',
                        ),
                      ),
                    ),
                    child: const Text('Set Target'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
