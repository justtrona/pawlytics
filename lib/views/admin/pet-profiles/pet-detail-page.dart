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

  late TextEditingController _name;
  late TextEditingController _imageUrl;
  late TextEditingController _story; // 👈 NEW: story controller

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

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    _name = TextEditingController(text: p.name);
    _imageUrl = TextEditingController(text: p.imageUrl ?? '');
    _story = TextEditingController(text: p.story ?? ''); // 👈 NEW

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
  }

  @override
  void dispose() {
    _name.dispose();
    _imageUrl.dispose();
    _story.dispose(); // 👈 NEW
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.pet.id;
    if (id == null || id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save: missing pet id')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('pet_profiles')
          .update({
            'name': _name.text.trim(),
            'species': _species.trim(),
            'age_group': _ageGroup.trim(),
            'status': _status.trim(),
            'image': _imageUrl.text.trim().isEmpty
                ? null
                : _imageUrl.text.trim(),
            'story':
                _story.text
                    .trim()
                    .isEmpty // 👈 NEW
                ? null
                : _story.text.trim(),
            'surgery': _surgery ? 1 : 0,
            'dental_care': _dentalCare ? 1 : 0,
            'vaccination': _vaccination ? 1 : 0,
            'injury_treatment': _injuryTreatment ? 1 : 0,
            'deworming': _deworming ? 1 : 0,
            'skin_treatment': _skinTreatment ? 1 : 0,
            'spay_neuter': _spayNeuter ? 1 : 0,
          })
          .eq('id', id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pet saved')));
      Navigator.pop(context, true); // signal caller to refresh
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

    if (ok == true) {
      await _delete();
    }
  }

  Future<void> _delete() async {
    final id = widget.pet.id;
    if (id == null || id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: missing pet id')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('pet_profiles').delete().eq('id', id);

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
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Image preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: img.isEmpty
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.pets, size: 48),
                            ),
                          )
                        : Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.pets, size: 48),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Image URL
                TextFormField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Name
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a name'
                      : null,
                ),
                const SizedBox(height: 12),

                // Species
                DropdownButtonFormField<String>(
                  value: _species.isEmpty ? null : _species,
                  decoration: const InputDecoration(
                    labelText: 'Species',
                    prefixIcon: Icon(Icons.pets_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                    DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                  ],
                  onChanged: (v) => setState(() => _species = v ?? _species),
                ),
                const SizedBox(height: 12),

                // Age group
                DropdownButtonFormField<String>(
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
                    DropdownMenuItem(value: 'Adult', child: Text('Adult')),
                    DropdownMenuItem(value: 'Senior', child: Text('Senior')),
                  ],
                  onChanged: (v) => setState(() => _ageGroup = v ?? _ageGroup),
                ),
                const SizedBox(height: 12),

                // Status
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
                    DropdownMenuItem(value: 'Adopted', child: Text('Adopted')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),

                const SizedBox(height: 16),

                // Medical / care flags
                _SwitchRow(
                  label: 'Surgery',
                  value: _surgery,
                  onChanged: (v) => setState(() => _surgery = v),
                ),
                _SwitchRow(
                  label: 'Dental care',
                  value: _dentalCare,
                  onChanged: (v) => setState(() => _dentalCare = v),
                ),
                _SwitchRow(
                  label: 'Vaccination',
                  value: _vaccination,
                  onChanged: (v) => setState(() => _vaccination = v),
                ),
                _SwitchRow(
                  label: 'Injury treatment',
                  value: _injuryTreatment,
                  onChanged: (v) => setState(() => _injuryTreatment = v),
                ),
                _SwitchRow(
                  label: 'Deworming',
                  value: _deworming,
                  onChanged: (v) => setState(() => _deworming = v),
                ),
                _SwitchRow(
                  label: 'Skin treatment',
                  value: _skinTreatment,
                  onChanged: (v) => setState(() => _skinTreatment = v),
                ),
                _SwitchRow(
                  label: 'Spay / Neuter',
                  value: _spayNeuter,
                  onChanged: (v) => setState(() => _spayNeuter = v),
                ),

                const SizedBox(height: 16),

                // 👇 NEW: Story (display + edit)
                TextFormField(
                  controller: _story,
                  minLines: 4,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    alignLabelWithHint: true,
                    labelText: 'Story (optional)',
                    hintText:
                        "Share this pet's rescue background, personality, and adoption notes…",
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
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

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}
