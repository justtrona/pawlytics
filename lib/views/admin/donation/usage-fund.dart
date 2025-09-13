import 'package:flutter/material.dart';

class FundUsage extends StatefulWidget {
  const FundUsage({super.key});

  @override
  State<FundUsage> createState() => _FundState();
}

class _FundState extends State<FundUsage> {
  // Theme
  static const brand = Color(0xFF27374D);

  final _formKey = GlobalKey<FormState>();

  // Controllers / state
  String _treatment = 'Vaccination';
  final _petCtrl = TextEditingController(text: 'Peter');
  final _amountCtrl = TextEditingController(text: 'PHP 800.00');
  final _dateCtrl = TextEditingController();
  final _proofCtrl = TextEditingController();

  @override
  void dispose() {
    _petCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _proofCtrl.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c, width: 1.2),
  );

  InputDecoration _dec({String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: _border(Colors.blueGrey.shade200),
      focusedBorder: _border(brand),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
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
      const months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      _dateCtrl.text = '${months[picked.month]} ${picked.day}, ${picked.year}';
      setState(() {});
    }
  }

  Future<void> _attachProof() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Attach Proof',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: brand),
              title: const Text('Choose Photo'),
              onTap: () => Navigator.pop(ctx, 'receipt_photo.jpg'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: brand),
              title: const Text('Choose PDF'),
              onTap: () => Navigator.pop(ctx, 'receipt_document.pdf'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (name != null) {
      _proofCtrl.text = name;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Attached: $name')));
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Saved: $_treatment • ${_petCtrl.text} • ${_amountCtrl.text} • ${_dateCtrl.text}'
          '${_proofCtrl.text.isNotEmpty ? ' • proof: ${_proofCtrl.text}' : ''}',
        ),
      ),
    );
    // TODO: persist to backend / navigate
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Donation Usage'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const Text(
                  'Type of Treatment',
                  style: TextStyle(color: brand, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _treatment,
                  isExpanded: true,
                  decoration: _dec(),
                  items: const [
                    DropdownMenuItem(
                      value: 'Vaccination',
                      child: Text('Vaccination'),
                    ),
                    DropdownMenuItem(value: 'Surgery', child: Text('Surgery')),
                    DropdownMenuItem(
                      value: 'Deworming',
                      child: Text('Deworming'),
                    ),
                    DropdownMenuItem(
                      value: 'Dental Care',
                      child: Text('Dental Care'),
                    ),
                    DropdownMenuItem(
                      value: 'Spay/Neuter',
                      child: Text('Spay/Neuter'),
                    ),
                    DropdownMenuItem(
                      value: 'Injury Treatment',
                      child: Text('Injury Treatment'),
                    ),
                    DropdownMenuItem(
                      value: 'Skin Treatment',
                      child: Text('Skin Treatment'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _treatment = v ?? _treatment),
                ),
                const SizedBox(height: 14),

                // Pet
                TextFormField(
                  controller: _petCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: _dec(hint: 'Pet'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Fund Used
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: _dec(hint: 'Fund Used'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Date Used
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: _dec(
                    hint: 'Date Used',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.event_note_outlined),
                      onPressed: _pickDate,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Attach Proof (Optional)
                TextFormField(
                  controller: _proofCtrl,
                  readOnly: true,
                  onTap: _attachProof,
                  decoration: _dec(
                    hint: 'Attach Proof (Optional)',
                    prefixIcon: const Icon(Icons.attach_file_rounded),
                  ),
                ),
                const SizedBox(height: 22),

                // Save button
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
