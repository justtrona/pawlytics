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

  String? _avatarUrl; // can be http(s) or asset path
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

      // ---------------- Prefill from Auth ----------------
      _emailCtrl.text = user.email ?? '';
      final md = user.userMetadata ?? {};
      final metaName =
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

      // ---------------- Enrich from registrations (preferred DB source) ----------------
      try {
        final Map<String, dynamic>? reg = await _sb
            .from('registrations')
            .select('fullName, email, phone_number')
            .eq('auth_user_id', user.id)
            .maybeSingle();

        if (reg != null) {
          final rName = (reg['fullName'] as String?);
          final rEmail = (reg['email'] as String?);
          final rPhone = (reg['phone_number'] as String?);

          if (rName != null && rName.trim().isNotEmpty) {
            _nameCtrl.text = rName
                .trim(); // <-- show full name from registrations
          }
          if (rEmail != null && rEmail.trim().isNotEmpty) {
            _emailCtrl.text = rEmail.trim();
          }
          if (rPhone != null && rPhone.trim().isNotEmpty) {
            _phoneCtrl.text = rPhone.trim();
          }
        }
      } catch (_) {
        // table/columns may not exist or RLS; ignore to keep UX smooth
      }

      // ---------------- Enrich from profiles (optional fallback) ----------------
      try {
        final Map<String, dynamic>? res = await _sb
            .from('profiles')
            .select('full_name, phone, donate_anonymously, avatar_url')
            .eq('id', user.id)
            .maybeSingle();

        if (res != null) {
          final pName = (res['full_name'] as String?);
          final pPhone = (res['phone'] as String?);
          final pAnon = (res['donate_anonymously'] as bool?);
          final pAvatar = (res['avatar_url'] as String?);

          if (pName != null && pName.trim().isNotEmpty) {
            _nameCtrl.text = pName.trim();
          }
          if (pPhone != null && pPhone.trim().isNotEmpty) {
            _phoneCtrl.text = pPhone.trim();
          }
          if (pAnon != null) _donateAnonymously = pAnon;

          if (pAvatar != null && pAvatar.trim().isNotEmpty) {
            _avatarUrl = pAvatar.trim();
            _avatarIsNetwork = _avatarUrl!.startsWith('http');
          }
        }
      } catch (_) {
        // profiles table may not exist; ignore
      }
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
      // ---------------- 1) Update Auth (email + metadata) ----------------
      final meta = <String, dynamic>{
        'full_name': _nameCtrl.text.trim(),
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

      // ---------------- 2) Upsert into registrations (preferred) ----------------
      try {
        await _sb.from('registrations').upsert({
          'auth_user_id': user.id,
          'fullName': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone_number': _phoneCtrl.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'auth_user_id');
      } catch (_) {
        // table may not exist or no permission; skip silently
      }

      // ---------------- 3) Upsert into profiles (optional) ----------------
      try {
        await _sb.from('profiles').upsert({
          'id': user.id,
          'full_name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'donate_anonymously': _donateAnonymously,
          'avatar_url': _avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // ignore if table not present
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
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
                  const SizedBox(height: 30),

                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      border: UnderlineInputBorder(),
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
                                "When enabled, your name will not appear on public donation records or certificate.",
                                style: TextStyle(
                                  fontSize: 15,
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
                                color: Color.fromARGB(255, 225, 227, 232),
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
