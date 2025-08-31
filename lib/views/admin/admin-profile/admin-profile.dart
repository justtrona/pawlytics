import 'package:flutter/material.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  // Palette (consistent with your app)
  static const navy = Color(0xFF0F2D50);
  static const subtitle = Color(0xFF6E7B8A);
  static const bg = Color(0xFFF6F7F9);

  // Form controllers
  final nameCtrl = TextEditingController(text: 'Jane Admin');
  final emailCtrl = TextEditingController(text: 'admin@pawlytics.org');
  final phoneCtrl = TextEditingController(text: '+63 912 345 6789');
  final roleCtrl = TextEditingController(text: 'Administrator');
  final bioCtrl = TextEditingController(
    text: 'Helping pets find loving homes.',
  );

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    roleCtrl.dispose();
    bioCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: Persist to backend/Firestore
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Header card (avatar + name + email + quick actions)
            _Card(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
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
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            // TODO: open picker to change photo
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: navy,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ChipPill(
                        icon: Icons.shield_outlined,
                        label: roleCtrl.text,
                      ),
                      _ChipPill(
                        icon: Icons.location_on_outlined,
                        label: 'Philippines',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HeaderButton(
                        icon: Icons.mail_outline,
                        label: 'Message',
                        onTap: () {},
                      ),
                      const SizedBox(width: 10),
                      _HeaderButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick stats
            _Card(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: const [
                  _KpiTile(title: 'Managed Campaigns', value: '12'),
                  _DividerY(),
                  _KpiTile(title: 'Resolved Reports', value: '43'),
                  _DividerY(),
                  _KpiTile(title: 'Team Members', value: '6'),
                ],
              ),
            ),

            // About me / bio
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

            // Contact & account
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
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _field(
                      'Email address',
                      prefix: const Icon(Icons.alternate_email),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final ok = RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim());
                      return ok ? null : 'Enter a valid email';
                    },
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
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: roleCtrl,
                    readOnly: true,
                    decoration: _field(
                      'Role',
                      prefix: const Icon(Icons.admin_panel_settings_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        // TODO: navigate to roles screen
                      },
                      icon: const Icon(Icons.manage_accounts_outlined),
                      label: const Text('Manage role'),
                    ),
                  ),
                ],
              ),
            ),

            // Recent activity (optional)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Recent activity'),
                  const SizedBox(height: 4),
                  _ActivityTile(
                    icon: Icons.update,
                    title: 'Updated payment configuration',
                    subtitle: '2 hours ago',
                  ),
                  _ActivityTile(
                    icon: Icons.pets_outlined,
                    title: 'Approved new pet profile',
                    subtitle: 'Yesterday • 4:13 PM',
                  ),
                  _ActivityTile(
                    icon: Icons.campaign_outlined,
                    title: 'Created campaign “Food Drive 2025”',
                    subtitle: 'Aug 25, 2025 • 10:22 AM',
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

  // --- Small UI helpers

  InputDecoration _field(String label, {String? hint, Widget? prefix}) {
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

// ============== Reusable widgets ==============

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
    return const Text(
      '',
      // we’ll use a small colored bar + title row
    );
  }
}

// Slightly fancier section header without being heavy
extension on _SectionTitle {
  Widget get widget => Builder(
    builder: (context) {
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
            (this).text,
            style: const TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    },
  );
}

// Replace _SectionTitle build to use the extension above
extension _SectionTitleBuild on _SectionTitle {
  Widget build(BuildContext context) => widget;
}

class _KpiTile extends StatelessWidget {
  final String title;
  final String value;
  const _KpiTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F2D50);
    final subtle = Colors.grey.shade600;
    return Expanded(
      child: Column(
        children: [
          Text(title, style: TextStyle(color: subtle, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, color: navy),
          ),
        ],
      ),
    );
  }
}

class _DividerY extends StatelessWidget {
  const _DividerY();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.grey.shade200,
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F2D50);
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0F2D50);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: navy.withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: navy),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, color: navy),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
