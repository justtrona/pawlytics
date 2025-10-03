// lib/views/admin/controllers/add-pet-controller.dart
import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/model/pet-profiles-model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetProfileController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController storyController =
      TextEditingController(); // 👈 NEW

  PetProfile petProfile = PetProfile(
    name: '',
    species: 'Dog',
    ageGroup: 'Puppy/Kitten',
    status: 'For Adoption',
    story: '', // 👈 NEW
  );

  void dispose() {
    nameController.dispose();
    storyController.dispose(); // 👈 NEW
  }

  void updateName() =>
      petProfile = petProfile.copyWith(name: nameController.text);
  void updateStory() =>
      petProfile = petProfile.copyWith(story: storyController.text); // 👈 NEW

  void updateSpecies(String value) =>
      petProfile = petProfile.copyWith(species: value);
  void updateAgeGroup(String value) =>
      petProfile = petProfile.copyWith(ageGroup: value);
  void updateStatus(String value) =>
      petProfile = petProfile.copyWith(status: value);

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

  Future<bool> savePet() async {
    updateName();
    updateStory(); // 👈 NEW

    final payload = petProfile.toMapInsert();

    try {
      final inserted = await Supabase.instance.client
          .from('pet_profiles')
          .insert(payload)
          .select()
          .maybeSingle();

      String? newId;
      if (inserted == null) {
        newId = null;
      } else if (inserted is Map) {
        newId = inserted['id']?.toString();
      } else if (inserted is List && inserted.isNotEmpty) {
        final first = inserted[0];
        if (first is Map) newId = first['id']?.toString();
      }
      if (newId != null && newId.isNotEmpty) {
        petProfile = petProfile.copyWith(id: newId);
      }
      return true;
    } catch (e) {
      debugPrint("Save pet error: $e");
      return false;
    }
  }
}
