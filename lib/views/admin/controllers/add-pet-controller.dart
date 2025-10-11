import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/admin/model/pet-profiles-model.dart';

class PetProfileController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController storyController = TextEditingController();

  /// Local working copy of the pet profile
  PetProfile petProfile = PetProfile(
    name: '',
    species: 'Dog',
    ageGroup: 'Puppy/Kitten',
    status: 'For Adoption',
    story: '',
  );

  void dispose() {
    nameController.dispose();
    storyController.dispose();
  }

  /* ---------------- field updaters ---------------- */

  void updateName() =>
      petProfile = petProfile.copyWith(name: nameController.text);

  void updateStory() =>
      petProfile = petProfile.copyWith(story: storyController.text);

  void updateSpecies(String value) =>
      petProfile = petProfile.copyWith(species: value);

  void updateAgeGroup(String value) =>
      petProfile = petProfile.copyWith(ageGroup: value);

  void updateStatus(String value) =>
      petProfile = petProfile.copyWith(status: value);

  void updateImagePath(String path) =>
      petProfile = petProfile.copyWith(imageUrl: path);

  void toggleSurgery(bool value) =>
      petProfile = petProfile.copyWith(surgery: value);

  void toggleDentalCare(bool value) =>
      petProfile = petProfile.copyWith(dentalCare: value);

  void toggleVaccination(bool value) =>
      petProfile = petProfile.copyWith(vaccination: value);

  void toggleInjuryTreatment(bool value) =>
      petProfile = petProfile.copyWith(injuryTreatment: value);

  void toggleDeworming(bool value) =>
      petProfile = petProfile.copyWith(deworming: value);

  void toggleSkinTreatment(bool value) =>
      petProfile = petProfile.copyWith(skinTreatment: value);

  void toggleSpayNeuter(bool value) =>
      petProfile = petProfile.copyWith(spayNeuter: value);

  /* ---------------- image upload ---------------- */

  Future<String?> uploadPetImage(File imageFile) async {
    final client = Supabase.instance.client;
    final bucket = 'pet_images'; // Your Supabase bucket name
    final fileName =
        'pets/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

    try {
      // Upload file to Supabase storage
      await client.storage.from(bucket).upload(fileName, imageFile);

      // Get the public URL
      final publicUrl = client.storage.from(bucket).getPublicUrl(fileName);

      // Update local petProfile
      petProfile = petProfile.copyWith(imageUrl: publicUrl);

      debugPrint('✅ Image uploaded successfully: $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('❌ Storage upload error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected upload error: $e');
      return null;
    }
  }

  /* ---------------- persistence ---------------- */

  Future<bool> savePet() async {
    updateName();
    updateStory();

    final payload = petProfile.toMapInsert();
    final story = (petProfile.story ?? '').trim();
    payload['story'] = story.isEmpty ? null : story;

    try {
      debugPrint('🟨 Saving pet profile to Supabase...');

      // Insert pet record
      final res = await Supabase.instance.client
          .from('pet_profiles')
          .insert(payload)
          .select('id,funds,created_at') // ✅ Fixed (removed `uuid`)
          .single();

      // Parse response
      String? newId = res['id']?.toString();

      double? newFunds;
      final rawFunds = res['funds'];
      if (rawFunds != null) {
        if (rawFunds is num) {
          newFunds = rawFunds.toDouble();
        } else {
          newFunds = double.tryParse(rawFunds.toString());
        }
      }

      petProfile = petProfile.copyWith(
        id: newId,
        createdAt: res['created_at'] != null
            ? DateTime.tryParse(res['created_at'].toString())
            : null,
        funds: newFunds,
      );

      // Sync controllers (optional)
      nameController.text = petProfile.name;
      storyController.text = petProfile.story ?? '';

      debugPrint('✅ Pet saved successfully! ID: $newId');
      return true;
    } on PostgrestException catch (e) {
      debugPrint('❌ Save pet error (Postgrest): ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Save pet error: $e');
      return false;
    }
  }

  Future<bool> updatePet() async {
    updateName();
    updateStory();

    final pid = petProfile.dbId;
    if (pid == null || pid.isEmpty) {
      debugPrint('❌ Update pet error: missing pet id');
      return false;
    }

    final payload = petProfile.toMapInsert();
    final story = (petProfile.story ?? '').trim();
    payload['story'] = story.isEmpty ? null : story;

    try {
      await Supabase.instance.client
          .from('pet_profiles')
          .update(payload)
          .eq('id', pid);

      debugPrint('✅ Pet updated successfully.');
      return true;
    } on PostgrestException catch (e) {
      debugPrint('❌ Update pet error (Postgrest): ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Update pet error: $e');
      return false;
    }
  }
}
