import 'package:flutter/material.dart';

class AddPetProfile extends StatefulWidget {
  const AddPetProfile({super.key});

  @override
  State<AddPetProfile> createState() => _AddPetProfileState();
}

class _AddPetProfileState extends State<AddPetProfile> {
  // Theme
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFE9EEF3);

  final _nameCtrl = TextEditingController(text: 'Peter');

  String _species = 'Dog'; // Dog | Cat
  String _ageGroup = 'Senior'; // Puppy/Kitten | Senior
  String _status = 'For Adoption';

  final Map<String, bool> _needs = {
    'Surgery': true,
    'Deworming': false,
    'Dental Care': true,
    'Skin Treatment': false,
    'Vaccination': true,
    'Spay/Neuter': true,
    'Injury Treatment': false,
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: 1.2),
  );

  InputDecoration _input({String? hint}) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    filled: true,
    fillColor: Colors.white,
    enabledBorder: _border(Colors.blueGrey.shade200),
    focusedBorder: _border(brand),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Add New Pet'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  // TODO: Save logic
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Pet saved')));
                },
                child: const Text('Save Pet'),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Photo placeholder
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: softGrey,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: pick image
                    },
                    icon: const Icon(
                      Icons.photo_camera_outlined,
                      size: 36,
                      color: brand,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pet name
              const Text(
                'Pet Name',
                style: TextStyle(color: brand, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                decoration: _input(hint: 'Peter'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),

              // Species pills
              Row(
                children: [
                  Expanded(
                    child: _Pill(
                      label: 'Dog',
                      selected: _species == 'Dog',
                      onTap: () => setState(() => _species = 'Dog'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Pill(
                      label: 'Cat',
                      selected: _species == 'Cat',
                      outlineOnly: true,
                      onTap: () => setState(() => _species = 'Cat'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Age pills
              Row(
                children: [
                  Expanded(
                    child: _Pill(
                      label: 'Puppy/Kitten',
                      selected: _ageGroup == 'Puppy/Kitten',
                      outlineOnly: true,
                      onTap: () => setState(() => _ageGroup = 'Puppy/Kitten'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Pill(
                      label: 'Senior',
                      selected: _ageGroup == 'Senior',
                      onTap: () => setState(() => _ageGroup = 'Senior'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Health & Care Needs
              const Text(
                'Health & Care Needs',
                style: TextStyle(color: brand, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _NeedsGrid(
                items: _needs,
                onToggle: (k, v) => setState(() => _needs[k] = v),
              ),
              const SizedBox(height: 16),

              // Status
              const Text(
                'Status',
                style: TextStyle(color: brand, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _status,
                isExpanded: true,
                decoration: _input(hint: 'For Adoption'),
                items: const [
                  DropdownMenuItem(
                    value: 'For Adoption',
                    child: Text('For Adoption'),
                  ),
                  DropdownMenuItem(value: 'Adopted', child: Text('Adopted')),
                  DropdownMenuItem(
                    value: 'Needs Medical Care',
                    child: Text('Needs Medical Care'),
                  ),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'For Adoption'),
              ),
              const SizedBox(height: 80), // breathing room above Save button
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Small widgets ----------

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool outlineOnly;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.outlineOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected && !outlineOnly
        ? _AddPetProfileState.brand
        : Colors.white;
    final fg = selected && !outlineOnly
        ? Colors.white
        : _AddPetProfileState.brand;
    final side = BorderSide(color: _AddPetProfileState.brand, width: 1.3);

    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: side,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}

class _NeedsGrid extends StatelessWidget {
  final Map<String, bool> items;
  final void Function(String, bool) onToggle;

  const _NeedsGrid({required this.items, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final keys = items.keys.toList();

    // Render as a 2-column table like the mock
    List<TableRow> rows = [];
    for (int i = 0; i < keys.length; i += 2) {
      final k1 = keys[i];
      final k2 = (i + 1 < keys.length) ? keys[i + 1] : null;

      rows.add(
        TableRow(
          children: [
            _NeedCheck(
              label: k1,
              value: items[k1]!,
              onChanged: (v) => onToggle(k1, v),
            ),
            if (k2 != null)
              _NeedCheck(
                label: k2,
                value: items[k2]!,
                onChanged: (v) => onToggle(k2, v),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      );
    }

    return Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }
}

class _NeedCheck extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NeedCheck({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.only(right: 12),
      dense: true,
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      activeColor: _AddPetProfileState.brand,
      checkColor: Colors.white,
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF212C36),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
