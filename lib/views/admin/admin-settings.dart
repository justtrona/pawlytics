import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // Palette
  static const navy = Color(0xFF0F2D50);
  static const subtitle = Color(0xFF6E7B8A);
  static const bg = Color(0xFFF6F7F9);

  // --- Profile
  final TextEditingController nameCtrl = TextEditingController(
    text: 'Jane Admin',
  );
  final TextEditingController emailCtrl = TextEditingController(
    text: 'admin@pawlytics.org',
  );
  final TextEditingController phoneCtrl = TextEditingController(
    text: '+63 912 345 6789',
  );

  // --- Organization
  final TextEditingController orgNameCtrl = TextEditingController(
    text: 'Pawlytics PH',
  );
  final TextEditingController orgAddressCtrl = TextEditingController(
    text: '123 Cat St, Quezon City, Metro Manila',
  );
  String timezone = 'Asia/Manila';
  String currency = 'PHP — Philippine Peso';

  // --- Security
  bool twoFAEnabled = false;

  // --- Notifications
  bool emailNotif = true;
  bool pushNotif = true;
  String digest = 'Weekly'; // Off / Daily / Weekly / Monthly

  // --- Appearance
  ThemeMode themeMode = ThemeMode.light;
  String density = 'Comfortable'; // Compact / Comfortable

  // --- Permissions (summary only)
  final List<String> roles = const ['Owner', 'Admin', 'Editor'];

  // --- Team & Staff
  final List<_Staff> staff = [
    _Staff(
      name: 'Maria Santos',
      email: 'maria@pawlytics.org',
      role: 'Editor',
      active: true,
    ),
    _Staff(
      name: 'John Cruz',
      email: 'john@pawlytics.org',
      role: 'Admin',
      active: true,
    ),
    _Staff(
      name: 'Alex Dela Cruz',
      email: 'alex@pawlytics.org',
      role: 'Viewer',
      active: false,
    ),
  ];
  final List<String> staffRoles = const ['Admin', 'Editor', 'Viewer'];

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    orgNameCtrl.dispose();
    orgAddressCtrl.dispose();
    super.dispose();
  }

  void _saveAll() {
    final settings = {
      'profile': {
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
      },
      'organization': {
        'name': orgNameCtrl.text.trim(),
        'address': orgAddressCtrl.text.trim(),
        'timezone': timezone,
        'currency': currency,
      },
      'security': {'twoFAEnabled': twoFAEnabled},
      'notifications': {
        'email': emailNotif,
        'push': pushNotif,
        'digest': digest,
      },
      'appearance': {'theme': themeMode.name, 'density': density},
      'team_count': staff.length,
    };

    // TODO: Persist to your backend/Firestore.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    debugPrint('Saved settings: $settings');
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text || newCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              // TODO: call backend to change password
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Password updated')));
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _manageDevices() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Active sessions & devices',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            _deviceTile(
              'iPhone 14',
              'Quezon City • Active now',
              Icons.phone_iphone,
            ),
            _deviceTile(
              'Chrome on Mac',
              'Makati • 2 hours ago',
              Icons.laptop_mac,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out other sessions')),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out others'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _deviceTile(String title, String subtitleText, IconData icon) {
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
      subtitle: Text(
        subtitleText,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.more_horiz),
      onTap: () {},
    );
  }

  // ---------- Staff management ----------
  Future<void> _openAddStaffDialog() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final tempPass = TextEditingController();
    String role = staffRoles.first;
    bool sendInvite = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add staff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 10),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.manage_accounts_outlined),
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: role,
                    items: staffRoles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => role = v ?? role,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tempPass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Temporary password',
                  prefixIcon: Icon(Icons.password_outlined),
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: sendInvite,
                onChanged: (v) => sendInvite = v,
                title: const Text('Send invite email'),
                subtitle: const Text(
                  'Email staff a link to set up their account',
                ),
                activeColor: navy,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final e = email.text.trim();
              final n = name.text.trim();
              if (n.isEmpty ||
                  e.isEmpty ||
                  !RegExp(r'^\S+@\S+\.\S+$').hasMatch(e)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid name and email')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() {
        staff.insert(
          0,
          _Staff(
            name: name.text.trim(),
            email: email.text.trim(),
            role: role,
            active: true,
          ),
        );
      });

      // TODO: Call backend to create account, set role, store temp password, and optionally send invite.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Staff added')));
    }
  }

  void _toggleActive(_Staff s) {
    setState(() => s.active = !s.active);
    // TODO: Persist active status to backend
  }

  void _resetPassword(_Staff s) {
    // TODO: Backend reset (send reset email or surface a temporary password)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password reset link sent to ${s.email}')),
    );
  }

  void _removeStaff(_Staff s) {
    setState(() => staff.remove(s));
    // TODO: Remove in backend
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Removed ${s.name}')));
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
          'Admin Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          // Profile
          _SectionCard(
            title: 'Profile',
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: navy.withOpacity(.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: navy,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: nameCtrl,
                            decoration: _field(
                              'Full name',
                              prefix: const Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _field(
                              'Email address',
                              prefix: const Icon(Icons.alternate_email),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
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

          // Organization
          _SectionCard(
            title: 'Organization',
            child: Column(
              children: [
                TextField(
                  controller: orgNameCtrl,
                  decoration: _field(
                    'Organization name',
                    prefix: const Icon(Icons.apartment_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: orgAddressCtrl,
                  decoration: _field(
                    'Address',
                    prefix: const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                _TwoCol(
                  left: _DropdownTile<String>(
                    icon: Icons.schedule_outlined,
                    label: 'Timezone',
                    value: timezone,
                    items: const [
                      'Asia/Manila',
                      'UTC',
                      'America/Los_Angeles',
                      'Europe/London',
                    ],
                    onChanged: (v) => setState(() => timezone = v!),
                  ),
                  right: _DropdownTile<String>(
                    icon: Icons.payments_outlined,
                    label: 'Currency',
                    value: currency,
                    items: const [
                      'PHP — Philippine Peso',
                      'USD — US Dollar',
                      'EUR — Euro',
                    ],
                    onChanged: (v) => setState(() => currency = v!),
                  ),
                ),
              ],
            ),
          ),

          // Security
          _SectionCard(
            title: 'Security',
            child: Column(
              children: [
                _SwitchTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Two-factor authentication',
                  subtitle: 'Add an extra layer of security at sign in',
                  value: twoFAEnabled,
                  onChanged: (v) => setState(() => twoFAEnabled = v),
                ),
                const SizedBox(height: 8),
                _ButtonTile(
                  icon: Icons.password_outlined,
                  title: 'Change password',
                  subtitle: 'Update your account password',
                  onTap: _changePassword,
                ),
                const SizedBox(height: 8),
                _ButtonTile(
                  icon: Icons.devices_other_outlined,
                  title: 'Sessions & devices',
                  subtitle: 'Review logged-in devices and sign out others',
                  onTap: _manageDevices,
                ),
              ],
            ),
          ),

          // Notifications
          _SectionCard(
            title: 'Notifications',
            child: Column(
              children: [
                _SwitchTile(
                  icon: Icons.email_outlined,
                  title: 'Email notifications',
                  subtitle: 'Receive email updates and alerts',
                  value: emailNotif,
                  onChanged: (v) => setState(() => emailNotif = v),
                ),
                const SizedBox(height: 8),
                _SwitchTile(
                  icon: Icons.notifications_none_outlined,
                  title: 'Push notifications',
                  subtitle: 'Receive push notifications on your device',
                  value: pushNotif,
                  onChanged: (v) => setState(() => pushNotif = v),
                ),
                const SizedBox(height: 8),
                _DropdownTile<String>(
                  icon: Icons.schedule_send_outlined,
                  label: 'Digest frequency',
                  value: digest,
                  items: const ['Off', 'Daily', 'Weekly', 'Monthly'],
                  onChanged: (v) => setState(() => digest = v!),
                ),
              ],
            ),
          ),

          // Appearance
          _SectionCard(
            title: 'Appearance',
            child: Column(
              children: [
                _DropdownTile<ThemeMode>(
                  icon: Icons.dark_mode_outlined,
                  label: 'Theme',
                  value: themeMode,
                  items: const [
                    ThemeMode.light,
                    ThemeMode.dark,
                    ThemeMode.system,
                  ],
                  itemBuilder: (m) =>
                      m.name[0].toUpperCase() + m.name.substring(1),
                  onChanged: (v) => setState(() => themeMode = v!),
                ),
                const SizedBox(height: 8),
                _DropdownTile<String>(
                  icon: Icons.view_agenda_outlined,
                  label: 'Density',
                  value: density,
                  items: const ['Compact', 'Comfortable'],
                  onChanged: (v) => setState(() => density = v!),
                ),
              ],
            ),
          ),

          // Permissions (summary)
          _SectionCard(
            title: 'Permissions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roles
                      .map(
                        (r) => Chip(
                          label: Text(r),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: navy.withOpacity(.06),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      // TODO: navigate to roles/permissions screen
                    },
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Manage roles'),
                  ),
                ),
              ],
            ),
          ),

          // Team & Staff (NEW)
          _SectionCard(
            title: 'Team & Staff',
            child: Column(
              children: [
                // Add staff button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _openAddStaffDialog,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add staff'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Staff list
                if (staff.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No staff yet',
                      style: TextStyle(color: subtitle),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: staff.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (_, i) {
                      final s = staff[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: navy.withOpacity(.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_outline, color: navy),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: navy,
                                ),
                              ),
                            ),
                            _ActiveBadge(active: s.active),
                          ],
                        ),
                        subtitle: Text('${s.email} • ${s.role}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            switch (val) {
                              case 'reset':
                                _resetPassword(s);
                                break;
                              case 'toggle':
                                _toggleActive(s);
                                break;
                              case 'remove':
                                _removeStaff(s);
                                break;
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'reset',
                              child: ListTile(
                                leading: Icon(Icons.refresh),
                                title: Text('Reset password'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: ListTile(
                                leading: Icon(
                                  s.active
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                                ),
                                title: Text(
                                  s.active ? 'Deactivate' : 'Reactivate',
                                ),
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'remove',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Remove'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // About / Danger Zone
          _SectionCard(
            title: 'About',
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  value: '1.0.0 (100)',
                ),
                const SizedBox(height: 8),
                _ButtonTile(
                  icon: Icons.logout,
                  title: 'Sign out',
                  subtitle: 'Sign out from this device',
                  onTap: () {
                    // TODO: handle sign out
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Signed out')));
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(.2)),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.delete_forever_outlined,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Delete organization',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Permanently remove all org data (irreversible)',
                    ),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete organization?'),
                          content: const Text(
                            'This action cannot be undone. Type DELETE to confirm.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'DELETE',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        // TODO: call backend
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Organization queued for deletion'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAll,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save),
        label: const Text('Save changes'),
      ),
    );
  }

  // ---------- Small UI helpers ----------
  InputDecoration _field(String label, {Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

// ===== Models & small widgets =====

class _Staff {
  final String name;
  final String email;
  final String role;
  bool active;
  _Staff({
    required this.name,
    required this.email,
    required this.role,
    this.active = true,
  });
}

class _ActiveBadge extends StatelessWidget {
  final bool active;
  const _ActiveBadge({required this.active});
  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : Colors.grey;
    final bg = active
        ? Colors.green.withOpacity(.1)
        : Colors.grey.withOpacity(.15);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.pause_circle_filled,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  static const navy = Color(0xFF0F2D50);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  static const navy = Color(0xFF0F2D50);

  @override
  Widget build(BuildContext context) {
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
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Switch(value: value, activeColor: navy, onChanged: onChanged),
    );
  }
}

class _ButtonTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ButtonTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  static const navy = Color(0xFF0F2D50);

  @override
  Widget build(BuildContext context) {
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
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  static const navy = Color(0xFF0F2D50);

  @override
  Widget build(BuildContext context) {
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
      trailing: Text(
        value,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final List<T> items;
  final String Function(T)? itemBuilder;
  final ValueChanged<T?> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemBuilder,
  });

  static const navy = Color(0xFF0F2D50);

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(
                    itemBuilder != null ? itemBuilder!(e) : e.toString(),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _TwoCol extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _TwoCol({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 640) {
          return Column(children: [left, const SizedBox(height: 10), right]);
        }
        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
