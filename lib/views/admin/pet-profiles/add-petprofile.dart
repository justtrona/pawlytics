import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawlytics/views/admin/controllers/add-pet-controller.dart';
import 'package:pawlytics/views/admin/pet-profiles/pet-widgets/pill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPetProfile extends StatefulWidget {
  const AddPetProfile({super.key});

  @override
  State<AddPetProfile> createState() => _AddPetProfileState();
}

class _AddPetProfileState extends State<AddPetProfile> {
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFE9EEF3);

  final controller = PetProfileController();
  final ImagePicker _picker = ImagePicker();

  io.File? _selectedImage;
  Uint8List? _webImageBytes;
  bool _uploading = false;

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

  /// 🧩 Pick and upload image (web + mobile compatible)
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _uploading = true);

    try {
      final client = Supabase.instance.client;
      final fileName =
          'pets/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      String? publicUrl;

      if (kIsWeb) {
        // 🕸️ Web: Upload as bytes
        final bytes = await pickedFile.readAsBytes();
        await client.storage.from('pet_images').uploadBinary(fileName, bytes);
        publicUrl = client.storage.from('pet_images').getPublicUrl(fileName);
        setState(() => _webImageBytes = bytes);
      } else {
        // 📱 Mobile: Upload file directly
        final file = io.File(pickedFile.path);
        await client.storage.from('pet_images').upload(fileName, file);
        publicUrl = client.storage.from('pet_images').getPublicUrl(fileName);
        setState(() => _selectedImage = file);
      }

      if (publicUrl != null) {
        controller.updateImagePath(publicUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get image URL.')),
        );
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      setState(() => _uploading = false);
    }
  }

  /// Helper to display correct image (web or mobile)
  ImageProvider? _getPetImage() {
    if (kIsWeb) {
      return _webImageBytes != null ? MemoryImage(_webImageBytes!) : null;
    } else if (_selectedImage != null) {
      return Image.file(_selectedImage!).image;
    }
    return null;
  }

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
                onPressed: _uploading
                    ? null
                    : () async {
                        final success = await controller.savePet();
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pet saved successfully!'),
                            ),
                          );
                          Navigator.of(context).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to save pet. Please try again.',
                              ),
                            ),
                          );
                        }
                      },
                child: _uploading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Save Pet'),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // 🐾 Pet Image Uploader
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: softGrey,
                      backgroundImage: _getPetImage(),
                      child: (_selectedImage == null && _webImageBytes == null)
                          ? const Icon(Icons.pets, size: 48, color: brand)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: brand,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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

              // 🐶 Species
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
                      onTap: () =>
                          setState(() => controller.updateSpecies('Cat')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 🐾 Age Group
              Row(
                children: [
                  Expanded(
                    child: Pill(
                      label: 'Puppy/Kitten',
                      selected: pet.ageGroup == 'Puppy/Kitten',
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

              // 💊 Health & Care Needs
              const Text(
                'Health & Care Needs',
                style: TextStyle(color: brand, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Surgery'),
                    value: pet.surgery,
                    onChanged: (v) =>
                        setState(() => controller.toggleSurgery(v ?? false)),
                  ),
                  CheckboxListTile(
                    title: const Text('Dental Care'),
                    value: pet.dentalCare,
                    onChanged: (v) =>
                        setState(() => controller.toggleDentalCare(v ?? false)),
                  ),
                  CheckboxListTile(
                    title: const Text('Vaccination'),
                    value: pet.vaccination,
                    onChanged: (v) => setState(
                      () => controller.toggleVaccination(v ?? false),
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('Injury Treatment'),
                    value: pet.injuryTreatment,
                    onChanged: (v) => setState(
                      () => controller.toggleInjuryTreatment(v ?? false),
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('Deworming'),
                    value: pet.deworming,
                    onChanged: (v) =>
                        setState(() => controller.toggleDeworming(v ?? false)),
                  ),
                  CheckboxListTile(
                    title: const Text('Skin Treatment'),
                    value: pet.skinTreatment,
                    onChanged: (v) => setState(
                      () => controller.toggleSkinTreatment(v ?? false),
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('Spay/Neuter'),
                    value: pet.spayNeuter,
                    onChanged: (v) =>
                        setState(() => controller.toggleSpayNeuter(v ?? false)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 🩺 Status
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
              const SizedBox(height: 16),

              // ✍️ Story
              const Text(
                'Story',
                style: TextStyle(color: brand, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller.storyController,
                decoration: _input(
                  hint:
                      "Share this pet's rescue background, personality, and adoption notes…",
                ),
                minLines: 4,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
