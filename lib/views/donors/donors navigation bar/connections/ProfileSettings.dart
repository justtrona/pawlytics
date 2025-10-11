import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final _sb = Supabase.instance.client;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _donateAnonymously = false;
  String? _avatarUrl;
  bool _avatarIsNetwork = false;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _sb.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'You are not signed in.';
        });
        return;
      }

      _emailCtrl.text = user.email ?? '';
      final md = user.userMetadata ?? {};

      final metaName =
          (md['fullName'] as String?) ??
          (md['full_name'] as String?) ??
          (md['name'] as String?) ??
          (md['username'] as String?) ??
          (md['display_name'] as String?);
      final metaPhone =
          (md['phone'] as String?) ?? (md['phone_number'] as String?);
      final metaAnon = (md['donate_anonymously'] as bool?) ?? false;
      final metaAvatar =
          (md['avatar_url'] as String?) ??
          (md['picture'] as String?) ??
          (md['photo_url'] as String?);

      if (metaName != null && metaName.trim().isNotEmpty) {
        _nameCtrl.text = metaName.trim();
      }
      if (metaPhone != null && metaPhone.trim().isNotEmpty) {
        _phoneCtrl.text = metaPhone.trim();
      }
      _donateAnonymously = metaAnon;
      if (metaAvatar != null && metaAvatar.trim().isNotEmpty) {
        _avatarUrl = metaAvatar.trim();
        _avatarIsNetwork = _avatarUrl!.startsWith('http');
      }

      // Registrations table
      try {
        Map<String, dynamic>? reg = await _sb
            .from('registrations')
            .select('fullName, email, phone_number')
            .eq('auth_user_id', user.id)
            .maybeSingle();

        if (reg == null && (user.email ?? '').isNotEmpty) {
          reg = await _sb
              .from('registrations')
              .select('fullName, email, phone_number')
              .eq('email', user.email!)
              .maybeSingle();
        }

        if (reg != null) {
          if ((reg['fullName'] as String?)?.isNotEmpty == true) {
            _nameCtrl.text = reg['fullName'];
          }
          if ((reg['email'] as String?)?.isNotEmpty == true) {
            _emailCtrl.text = reg['email'];
          }
          if ((reg['phone_number'] as String?)?.isNotEmpty == true) {
            _phoneCtrl.text = reg['phone_number'];
          }
        }
      } catch (_) {}

      // Profiles table
      try {
        final res = await _sb
            .from('profiles')
            .select('full_name, phone, donate_anonymously, avatar_url')
            .eq('id', user.id)
            .maybeSingle();

        if (res != null) {
          if ((res['full_name'] as String?)?.isNotEmpty == true) {
            _nameCtrl.text = res['full_name'];
          }
          if ((res['phone'] as String?)?.isNotEmpty == true) {
            _phoneCtrl.text = res['phone'];
          }
          if ((res['donate_anonymously'] as bool?) != null) {
            _donateAnonymously = res['donate_anonymously'];
          }
          if ((res['avatar_url'] as String?)?.isNotEmpty == true) {
            _avatarUrl = res['avatar_url'];
            _avatarIsNetwork = _avatarUrl!.startsWith('http');
          }
        }
      } catch (_) {}
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final user = _sb.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Use Anonymous name if toggle is ON
      final displayName = _donateAnonymously
          ? 'Anonymous Donor'
          : _nameCtrl.text.trim();

      // ---------------- 1) Update Auth ----------------
      final meta = <String, dynamic>{
        'fullName': displayName,
        'full_name': displayName,
        'phone': _phoneCtrl.text.trim(),
        'donate_anonymously': _donateAnonymously,
        if (_avatarUrl != null) 'avatar_url': _avatarUrl,
      };

      final newEmail = _emailCtrl.text.trim();
      if (newEmail.isNotEmpty && newEmail != (user.email ?? '')) {
        await _sb.auth.updateUser(UserAttributes(email: newEmail, data: meta));
      } else {
        await _sb.auth.updateUser(UserAttributes(data: meta));
      }

      // ---------------- 2) registrations ----------------
      try {
        await _sb.from('registrations').upsert({
          'auth_user_id': user.id,
          'fullName': displayName,
          'email': _emailCtrl.text.trim(),
          'phone_number': _phoneCtrl.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'auth_user_id');
      } catch (_) {}

      // ---------------- 3) profiles ----------------
      try {
        await _sb.from('profiles').upsert({
          'id': user.id,
          'full_name': displayName,
          'phone': _phoneCtrl.text.trim(),
          'donate_anonymously': _donateAnonymously,
          'avatar_url': _avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      // ---------------- 4) Update past donations ----------------
      try {
        await _sb
            .from('donations')
            .update({'donor_name': displayName})
            .eq('user_id', user.id);
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _donateAnonymously
                ? 'Your donations will now appear as Anonymous.'
                : 'Your name will now appear on your donations.',
          ),
        ),
      );

      Navigator.pop(context);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Auth error: ${e.message}')));
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Database error: ${e.message}')));
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _avatarUrl == null
        ? const AssetImage("assets/images/donors/dog3.png") as ImageProvider
        : (_avatarIsNetwork
                  ? NetworkImage(_avatarUrl!)
                  : AssetImage(_avatarUrl!))
              as ImageProvider;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Settings"),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: avatarProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Disable name field if anonymous toggle is ON
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_donateAnonymously,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      border: const UnderlineInputBorder(),
                      labelStyle: TextStyle(
                        color: _donateAnonymously
                            ? Colors.grey
                            : Colors.grey.shade800,
                      ),
                      helperText: _donateAnonymously
                          ? "Disabled while anonymous"
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email Address",
                      border: UnderlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Donate Anonymously",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Your name will appear as 'Anonymous Donor' in public donations and records.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF23344E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _donateAnonymously,
                          onChanged: (value) =>
                              setState(() => _donateAnonymously = value),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23344E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
