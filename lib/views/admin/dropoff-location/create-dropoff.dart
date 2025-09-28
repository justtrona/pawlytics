import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/controllers/dropoff-controller.dart';
import 'package:pawlytics/views/admin/model/dropoff-model.dart';

class CreateDropoff extends StatefulWidget {
  const CreateDropoff({super.key});

  @override
  State<CreateDropoff> createState() => _CreateDropoffState();
}

class _CreateDropoffState extends State<CreateDropoff> {
  static const brand = Color(0xFF27374D);

  final _formKey = GlobalKey<FormState>();

  final _orgCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _dateTimeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _status = 'Active';

  // ✅ declare this so we can store the real DateTime
  DateTime? _selectedDateTime;

  final DropoffLocationController _controller = DropoffLocationController();

  @override
  void dispose() {
    _orgCtrl.dispose();
    _addressCtrl.dispose();
    _dateTimeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: c, width: 1.2),
  );

  InputDecoration _dec({String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: _border(Colors.blueGrey.shade200),
      focusedBorder: _border(brand),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _selectedDateTime ?? now,
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: brand)),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: brand)),
        child: child!,
      ),
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // ✅ store actual DateTime for saving
    _selectedDateTime = dt;

    // For display only
    String _two(int n) => n.toString().padLeft(2, '0');
    final hour12 = ((dt.hour + 11) % 12) + 1;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';

    _dateTimeCtrl.text =
        '${_two(dt.month)}/${_two(dt.day)}/${dt.year}  ${_two(hour12)}:${_two(dt.minute)} $ampm';

    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date & time")),
      );
      return;
    }

    try {
      final location = DropoffLocation(
        organization: _orgCtrl.text,
        address: _addressCtrl.text,
        scheduledAt: _selectedDateTime!, // ✅ now safe
        phone: _phoneCtrl.text,
        status: _status,
      );

      await _controller.create(location);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dropoff location saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Locations'),
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
                TextFormField(
                  controller: _orgCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: _dec(hint: 'Organization/Company'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: _dec(hint: 'Address'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _dateTimeCtrl,
                  readOnly: true,
                  onTap: _pickDateTime,
                  decoration: _dec(
                    hint: 'Set Date & Time',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.event_note_outlined),
                      onPressed: _pickDateTime,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _dec(hint: 'Contact Number'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _status,
                  isExpanded: true,
                  decoration: _dec(hint: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'Inactive',
                      child: Text('Inactive'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'Active'),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 46,
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
                    child: const Text('Save Location'),
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
