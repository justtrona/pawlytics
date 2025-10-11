import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/admin/model/pet-profiles-model.dart';

class PetDetailPage extends StatefulWidget {
  const PetDetailPage({super.key, required this.pet});
  final PetProfile pet;

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _brand = const Color(0xFF0F2D50);

  late TextEditingController _name;
  late TextEditingController _imageUrl;
  late TextEditingController _story;

  late String _species; // Dog | Cat
  late String _ageGroup; // Puppy/Kitten | Adult | Senior
  late String _status; // For Adoption | Needs Medical Care | Adopted

  // medical / care flags
  late bool _surgery;
  late bool _dentalCare;
  late bool _vaccination;
  late bool _injuryTreatment;
  late bool _deworming;
  late bool _skinTreatment;
  late bool _spayNeuter;

  // funds
  double? _funds; // null while loading / unavailable
  bool _loadingFunds = false;
  String? _fundsError;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    _name = TextEditingController(text: p.name);
    _imageUrl = TextEditingController(text: p.imageUrl ?? '');
    _story = TextEditingController(text: p.story ?? '');
    _story.addListener(() => setState(() {})); // live counter

    _species = p.species;
    _ageGroup = p.ageGroup;
    _status = p.status;

    _surgery = p.surgery;
    _dentalCare = p.dentalCare;
    _vaccination = p.vaccination;
    _injuryTreatment = p.injuryTreatment;
    _deworming = p.deworming;
    _skinTreatment = p.skinTreatment;
    _spayNeuter = p.spayNeuter;

    _fetchFunds();
  }

  @override
  void dispose() {
    _name.dispose();
    _imageUrl.dispose();
    _story.dispose();
    super.dispose();
  }

  /* ---------------------- funds ---------------------- */

  Future<void> _fetchFunds() async {
    final pid = widget.pet.id;
    if (pid == null || pid.isEmpty) return;

    setState(() {
      _loadingFunds = true;
      _fundsError = null;
    });

    try {
      final sb = Supabase.instance.client;

      // First, try by 'id'
      Map<String, dynamic>? row = await sb
          .from('pet_profiles')
          .select('funds')
          .eq('id', pid)
          .maybeSingle();

      // Fallback to 'uuid' only if not found AND column exists
      if (row == null) {
        try {
          row = await sb
              .from('pet_profiles')
              .select('funds')
              .eq('uuid', pid)
              .maybeSingle();
        } on PostgrestException catch (e) {
          if (e.code != '42703') rethrow; // ignore "column does not exist"
        }
      }

      final raw = row?['funds'];
      final parsed = raw == null
          ? 0.0
          : (raw is num
                ? raw.toDouble()
                : double.tryParse(raw.toString()) ?? 0.0);

      if (!mounted) return;
      setState(() => _funds = parsed);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _fundsError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _fundsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingFunds = false);
    }
  }

  /* ---------------------- actions ---------------------- */

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final pid = widget.pet.id;
    if (pid == null || pid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save: missing pet id')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final sb = Supabase.instance.client;

      // Build payload map (keep it, don't rely on a builder "payload")
      final updates = <String, dynamic>{
        'name': _name.text.trim(),
        'species': _species.trim(),
        'age_group': _ageGroup.trim(),
        'status': _status.trim(),
        'image': _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
        'story': _story.text.trim().isEmpty ? null : _story.text.trim(),
        'surgery': _surgery ? 1 : 0,
        'dental_care': _dentalCare ? 1 : 0,
        'vaccination': _vaccination ? 1 : 0,
        'injury_treatment': _injuryTreatment ? 1 : 0,
        'deworming': _deworming ? 1 : 0,
        'skin_treatment': _skinTreatment ? 1 : 0,
        'spay_neuter': _spayNeuter ? 1 : 0,
      };

      // Decide whether to update by id or uuid based on existence
      final existsById = await sb
          .from('pet_profiles')
          .select('id')
          .eq('id', pid)
          .maybeSingle();

      if (existsById != null) {
        await sb.from('pet_profiles').update(updates).eq('id', pid);
      } else {
        // Try uuid (if column exists)
        try {
          await sb.from('pet_profiles').update(updates).eq('uuid', pid);
        } on PostgrestException catch (e) {
          if (e.code != '42703') rethrow;
          // If uuid column doesn't exist, rethrow a helpful error
          throw Exception(
            'No pet row found by id, and column "uuid" not present.',
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pet saved')));
      _fetchFunds(); // refresh funds just in case
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete pet?'),
        content: const Text(
          'This will permanently remove the pet profile. This cannot be undone.',
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
    if (ok == true) await _delete();
  }

  Future<void> _delete() async {
    final pid = widget.pet.id;
    if (pid == null || pid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: missing pet id')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final sb = Supabase.instance.client;

      final existsById = await sb
          .from('pet_profiles')
          .select('id')
          .eq('id', pid)
          .maybeSingle();

      if (existsById != null) {
        await sb.from('pet_profiles').delete().eq('id', pid);
      } else {
        try {
          await sb.from('pet_profiles').delete().eq('uuid', pid);
        } on PostgrestException catch (e) {
          if (e.code != '42703') rethrow;
          throw Exception(
            'No pet row found by id, and column "uuid" not present.',
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pet deleted')));
      Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /* ---------------------- UI helpers ---------------------- */

  Widget _sectionTitle(String text, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 18, color: _brand),
          if (icon != null) const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: _brand,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration get _cardDeco => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE5E7EB)),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 8)),
    ],
  );

  Widget _statusPill(String s) {
    final st = _statusStyle(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: st.bg,
        border: Border.all(color: st.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(st.icon, size: 14, color: st.fg),
          const SizedBox(width: 6),
          Text(
            st.label,
            style: TextStyle(color: st.fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  _StatusStyle _statusStyle(String s) {
    final lower = s.toLowerCase();
    Color bg, border, fg;
    IconData icon;
    if (lower.contains('adopted')) {
      bg = const Color(0xFFEDE9FE);
      border = const Color(0xFFD9D6FE);
      fg = const Color(0xFF5B21B6);
      icon = Icons.verified;
    } else if (lower.contains('for adoption') ||
        (lower.contains('adopt') && !lower.contains('ed'))) {
      bg = const Color(0xEFFDF5);
      border = const Color(0xD1FAE5);
      fg = const Color(0xFF065F46);
      icon = Icons.home;
    } else if (lower.contains('medical') ||
        lower.contains('treatment') ||
        lower.contains('rehab')) {
      bg = const Color(0xFFFFF1F2);
      border = const Color(0xFFFECACA);
      fg = const Color(0xFF9F1239);
      icon = Icons.healing;
    } else {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFBFDBFE);
      fg = const Color(0xFF1D4ED8);
      icon = Icons.info_outline;
    }
    return _StatusStyle(
      _titleCase(s.isEmpty ? 'Status' : s),
      bg,
      border,
      fg,
      icon,
    );
  }

  String _titleCase(String input) {
    final t = input.trim();
    if (t.isEmpty) return '';
    return t
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _money(double v) => '₱${v.toStringAsFixed(0)}';

  Widget _fundsTile() {
    if (_loadingFunds && _funds == null) {
      return Row(
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading funds…'),
        ],
      );
    }
    if (_fundsError != null) {
      return Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _fundsError!,
              style: const TextStyle(color: Colors.red),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: _fetchFunds,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }
    final v = _funds ?? 0.0;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _brand.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.account_balance_wallet_outlined, color: _brand),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Funds Raised',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _money(v),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: _fetchFunds,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Row(
        children: [
          Icon(icon, color: _brand),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  /* ---------------------- build ---------------------- */

  @override
  Widget build(BuildContext context) {
    final img = _imageUrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Info'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _saving ? null : _confirmDelete,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),

      // Sticky bottom save bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving…' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),

      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /* ---------- Header card: preview + status ---------- */
                Container(
                  decoration: _cardDeco,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        'Preview',
                        icon: Icons.photo_library_outlined,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: img.isEmpty
                            ? Container(
                                height: 240,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.pets, size: 48),
                                ),
                              )
                            : Image.network(
                                img,
                                fit: BoxFit
                                    .contain, // 👈 shows full image without cropping
                                height:
                                    240, // fixed height for consistent layout
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 240,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.pets, size: 48),
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _statusPill(_status),
                          const Spacer(),
                          const Icon(
                            Icons.link,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              img.isEmpty ? 'No image URL' : img,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /* ---------- Support so far (FUNDS) ---------- */
                Container(
                  decoration: _cardDeco,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        'Support so far',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      _fundsTile(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /* ---------- Basic info ---------- */
                Container(
                  decoration: _cardDeco,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Basic info', icon: Icons.badge_outlined),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _imageUrl,
                        decoration: const InputDecoration(
                          labelText: 'Image URL (optional)',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.pets_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _species.isEmpty ? null : _species,
                              decoration: const InputDecoration(
                                labelText: 'Species',
                                prefixIcon: Icon(Icons.pets_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Dog',
                                  child: Text('Dog'),
                                ),
                                DropdownMenuItem(
                                  value: 'Cat',
                                  child: Text('Cat'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _species = v ?? _species),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _ageGroup.isEmpty ? null : _ageGroup,
                              decoration: const InputDecoration(
                                labelText: 'Age Group',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Puppy/Kitten',
                                  child: Text('Puppy/Kitten'),
                                ),
                                DropdownMenuItem(
                                  value: 'Adult',
                                  child: Text('Adult'),
                                ),
                                DropdownMenuItem(
                                  value: 'Senior',
                                  child: Text('Senior'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _ageGroup = v ?? _ageGroup),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _status.isEmpty ? null : _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'For Adoption',
                            child: Text('For Adoption'),
                          ),
                          DropdownMenuItem(
                            value: 'Needs Medical Care',
                            child: Text('Needs Medical Care'),
                          ),
                          DropdownMenuItem(
                            value: 'Adopted',
                            child: Text('Adopted'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _status = v ?? _status),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /* ---------- Medical / care ---------- */
                Container(
                  decoration: _cardDeco,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        'Medical & Care',
                        icon: Icons.health_and_safety_outlined,
                      ),
                      _switchTile(
                        icon: Icons.healing,
                        label: 'Surgery',
                        value: _surgery,
                        onChanged: (v) => setState(() => _surgery = v),
                        subtitle: 'Mark if the pet has had / needs surgery',
                      ),
                      _switchTile(
                        icon: Icons.medical_services,
                        label: 'Dental Care',
                        value: _dentalCare,
                        onChanged: (v) => setState(() => _dentalCare = v),
                        subtitle: 'Teeth cleaning / dental procedures',
                      ),
                      _switchTile(
                        icon: Icons.vaccines,
                        label: 'Vaccination',
                        value: _vaccination,
                        onChanged: (v) => setState(() => _vaccination = v),
                        subtitle: 'Core vaccines completed',
                      ),
                      _switchTile(
                        icon: Icons.local_hospital,
                        label: 'Injury Treatment',
                        value: _injuryTreatment,
                        onChanged: (v) => setState(() => _injuryTreatment = v),
                      ),
                      _switchTile(
                        icon: Icons.pest_control,
                        label: 'Deworming',
                        value: _deworming,
                        onChanged: (v) => setState(() => _deworming = v),
                      ),
                      _switchTile(
                        icon: Icons.healing_outlined,
                        label: 'Skin Treatment',
                        value: _skinTreatment,
                        onChanged: (v) => setState(() => _skinTreatment = v),
                      ),
                      _switchTile(
                        icon: Icons.pets,
                        label: 'Spay / Neuter',
                        value: _spayNeuter,
                        onChanged: (v) => setState(() => _spayNeuter = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /* ---------- Story ---------- */
                Container(
                  decoration: _cardDeco,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        'Story (optional)',
                        icon: Icons.menu_book_outlined,
                      ),
                      TextFormField(
                        controller: _story,
                        minLines: 4,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          alignLabelWithHint: true,
                          hintText:
                              "Share this pet's rescue background, personality, and adoption notes…",
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_story.text.length}/1000',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
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

/* ---------------------- small types ---------------------- */

class _StatusStyle {
  final String label;
  final Color bg, border, fg;
  final IconData icon;
  _StatusStyle(this.label, this.bg, this.border, this.fg, this.icon);
}
