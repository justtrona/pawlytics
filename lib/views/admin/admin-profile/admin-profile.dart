import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/auth/auth_service.dart'; // your existing service

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  static const navy = Color(0xFF0F2D50);
  static const bg = Color(0xFFF6F7F9);

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final roleCtrl = TextEditingController();
  final bioCtrl = TextEditingController(
    text: 'Helping pets find loving homes.',
  );

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('registration')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (response != null) {
        nameCtrl.text = (response['fullName'] ?? '').toString();
        emailCtrl.text = (response['email'] ?? '').toString();
        phoneCtrl.text = (response['phone_number'] ?? '').toString();
        roleCtrl.text = (response['role'] ?? '').toString();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) return;

    final supabase = Supabase.instance.client;

    try {
      await supabase
          .from('registration')
          .update({
            'fullName': nameCtrl.text.trim(),
            'phone_number': phoneCtrl.text.trim(),
            // 'bio': bioCtrl.text.trim(), // add when column exists
          })
          .eq('id', user.id);

      await supabase.auth.updateUser(
        UserAttributes(data: {'fullName': nameCtrl.text.trim()}),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    roleCtrl.dispose();
    bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.maybePop(context),
          color: Colors.black87,
        ),
        title: const Text(
          'Admin Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  // Header Card
                  _Card(
                    child: Column(
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: navy.withOpacity(.08),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: navy,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          nameCtrl.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emailCtrl.text,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        _ChipPill(
                          icon: Icons.shield_outlined,
                          label: roleCtrl.text,
                        ),
                      ],
                    ),
                  ),

                  // About
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('About'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: bioCtrl,
                          maxLines: 3,
                          decoration: _field(
                            'Short bio',
                            hint: 'Tell something about yourself',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Account
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Account'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: _field(
                            'Full name',
                            prefix: const Icon(Icons.badge_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: emailCtrl,
                          readOnly: true,
                          decoration: _field(
                            'Email address',
                            prefix: const Icon(Icons.alternate_email),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: _field(
                            'Phone number',
                            prefix: const Icon(Icons.phone_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
    );
  }

  static InputDecoration _field(String label, {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

// ---------- Reusable UI bits ----------

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F2D50);
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ChipPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ChipPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F2D50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: navy.withOpacity(.06),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: navy),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
