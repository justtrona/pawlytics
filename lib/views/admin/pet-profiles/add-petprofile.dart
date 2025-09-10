// lib/screens/add_pet_profile.dart

import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/controllers/add-pet-controller.dart';
import 'package:pawlytics/views/admin/pet-profiles/pet-widgets/needs_grid.dart';
import 'package:pawlytics/views/admin/pet-profiles/pet-widgets/pill.dart';

class AddPetProfile extends StatefulWidget {
  const AddPetProfile({super.key});

  @override
  State<AddPetProfile> createState() => _AddPetProfileState();
}

class _AddPetProfileState extends State<AddPetProfile> {
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFE9EEF3);

  final controller = PetProfileController();

  @override
  void dispose() {
    controller.dispose();
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
    final pet = controller.petProfile;

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
                  controller.updateName();
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
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: softGrey,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.photo_camera_outlined,
                      size: 36,
                      color: brand,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Pet Name',
                style: TextStyle(color: brand, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller.nameController,
                decoration: _input(hint: 'Peter'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),

              // Species
              Row(
                children: [
                  Expanded(
                    child: Pill(
                      label: 'Dog',
                      selected: pet.species == 'Dog',
                      onTap: () =>
                          setState(() => controller.updateSpecies('Dog')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Pill(
                      label: 'Cat',
                      selected: pet.species == 'Cat',
                      outlineOnly: true,
                      onTap: () =>
                          setState(() => controller.updateSpecies('Cat')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Age Group
              Row(
                children: [
                  Expanded(
                    child: Pill(
                      label: 'Puppy/Kitten',
                      selected: pet.ageGroup == 'Puppy/Kitten',
                      outlineOnly: true,
                      onTap: () => setState(
                        () => controller.updateAgeGroup('Puppy/Kitten'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Pill(
                      label: 'Senior',
                      selected: pet.ageGroup == 'Senior',
                      onTap: () =>
                          setState(() => controller.updateAgeGroup('Senior')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Health & Care Needs',
                style: TextStyle(color: brand, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              NeedsGrid(
                items: pet.healthNeeds,
                onToggle: (k, v) =>
                    setState(() => controller.toggleHealthNeed(k, v)),
              ),
              const SizedBox(height: 16),

              const Text(
                'Status',
                style: TextStyle(color: brand, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: pet.status,
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
                onChanged: (v) => setState(
                  () => controller.updateStatus(v ?? 'For Adoption'),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
