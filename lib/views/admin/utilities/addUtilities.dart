import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/controllers/utilities-controller.dart';
import 'package:pawlytics/views/admin/model/utilities-model.dart';
class AddUtilities extends StatefulWidget {
  const AddUtilities({super.key});

  @override
  State<AddUtilities> createState() => _AddUtilitiesState();
}

class _AddUtilitiesState extends State<AddUtilities> {
  static const brand = Color(0xFF27374D);
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _dueCtrl = TextEditingController();
  final _controller = UtilityController();

  String _utility = 'Utilities';
  String _status = 'Paid';
  DateTime? _dueDate;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dueCtrl.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: c, width: 1.2),
      );

  InputDecoration _dec({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: _border(Colors.blueGrey.shade200),
      focusedBorder: _border(brand),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: ColorScheme.fromSeed(seedColor: brand)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _dueCtrl.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) return;
    FocusScope.of(context).unfocus();

    final utility = Utility(
      type: _utility,
      amount: double.parse(_amountCtrl.text),
      dueDate: _dueDate!,
      status: _status,
    );

    await _controller.addUtility(utility);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Utility saved successfully!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Utilities'),
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
                DropdownButtonFormField<String>(
                  value: _utility,
                  isExpanded: true,
                  decoration: _dec(hint: 'Utilities'),
                  items: const [
                    DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                    DropdownMenuItem(value: 'Water', child: Text('Water')),
                    DropdownMenuItem(value: 'Electricity', child: Text('Electricity')),
                    DropdownMenuItem(value: 'Waste Collection', child: Text('Waste Collection')),
                    DropdownMenuItem(value: 'Drinking Water', child: Text('Drinking Water')),
                  ],
                  onChanged: (v) => setState(() => _utility = v ?? 'Utilities'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _dec(hint: 'Goal Amount'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _dueCtrl,
                  readOnly: true,
                  onTap: _pickDueDate,
                  decoration: _dec(
                    hint: 'Due Date',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.event_note_outlined),
                      onPressed: _pickDueDate,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _status,
                  isExpanded: true,
                  decoration: _dec(hint: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'Due', child: Text('Due')),
                    DropdownMenuItem(value: 'Stocked', child: Text('Stocked')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'Paid'),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _save,
                    child: const Text('Save Changes'),
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
