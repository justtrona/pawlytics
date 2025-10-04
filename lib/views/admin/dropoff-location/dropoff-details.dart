// lib/views/admin/campaigns/dropoff-details.dart
import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/controllers/dropoff-controller.dart';
import 'package:pawlytics/views/admin/model/dropoff-model.dart';

class DropoffDetails extends StatefulWidget {
  const DropoffDetails({super.key, required this.location});
  final DropoffLocation location;

  @override
  State<DropoffDetails> createState() => _DropoffDetailsState();
}

class _DropoffDetailsState extends State<DropoffDetails> {
  static const brand = Color(0xFF27374D);

  final _formKey = GlobalKey<FormState>();

  final _orgCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _dateTimeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _status = 'Active';

  DateTime? _selectedDateTime;

  final DropoffLocationController _controller = DropoffLocationController();

  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _seedFromModel();
  }

  void _seedFromModel() {
    final m = widget.location;
    _orgCtrl.text = m.organization;
    _addressCtrl.text = m.address;
    _phoneCtrl.text = m.phone;
    _status = (m.status.isEmpty ? 'Active' : m.status);
    _selectedDateTime = m.scheduledAt;

    String _two(int n) => n.toString().padLeft(2, '0');
    final dt = m.scheduledAt;
    final hour12 = ((dt.hour + 11) % 12) + 1;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    _dateTimeCtrl.text =
        '${_two(dt.month)}/${_two(dt.day)}/${dt.year}  ${_two(hour12)}:${_two(dt.minute)} $ampm';
  }

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
    final init = _selectedDateTime ?? now;

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: init,
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
      initialTime: TimeOfDay.fromDateTime(init),
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
    _selectedDateTime = dt;

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
        const SnackBar(content: Text('Please select a date & time')),
      );
      return;
    }

    // ensure we have a DB id before updating
    if (widget.location.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing location id; cannot update.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = DropoffLocation(
        id: widget.location.id, // non-null confirmed above
        organization: _orgCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        scheduledAt: _selectedDateTime!,
        phone: _phoneCtrl.text.trim(),
        status: _status,
      );

      await _controller.update(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location updated')));
      Navigator.pop(context, true); // signal caller to refresh
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
        title: const Text('Delete location?'),
        content: const Text(
          'This will permanently remove the drop-off location.',
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
    // ensure we have a DB id before deleting
    if (widget.location.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing location id; cannot delete.')),
      );
      return;
    }

    setState(() => _deleting = true);
    try {
      await _controller.deleteById(widget.location.id!); // non-nullable id
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location deleted')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _deleting = false);
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
          title: const Text('Location Details'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
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
                    minimumSize: const Size(120, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
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
                    minimumSize: const Size(120, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
