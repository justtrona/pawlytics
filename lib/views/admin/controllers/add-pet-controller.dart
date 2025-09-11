// lib/controllers/add_pet_controller.dart
import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/model/pet-profiles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:pawlytics/models/pet_profile.dart';

class PetProfileController {
  final TextEditingController nameController = TextEditingController();

  PetProfile petProfile = PetProfile(
    name: 'Peter',
    species: 'cat',
    ageGroup: 'Adult',
    status: 'For Adoption',
  );

  void dispose() => nameController.dispose();

  void updateName() =>
      petProfile = petProfile.copyWith(name: nameController.text);
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

  Future<void> savePet() async {
    updateName();

    final payload = petProfile.toMapInsert();

    try {
      // Insert and request returned row(s)
      final inserted = await Supabase.instance.client
          .from('pet_profiles')
          .insert(payload)
          .select()
          .maybeSingle(); // maybeSingle avoids exceptions if nothing returned

      String? newId;

      if (inserted == null) {
        // no row returned — still may be fine; leave id null
        newId = null;
      } else if (inserted is Map) {
        newId = inserted['id']?.toString();
      } else if (inserted is List && inserted.isNotEmpty) {
        final first = inserted[0];
        if (first is Map) newId = first['id']?.toString();
      } else {
        try {
          newId = inserted['id']?.toString();
        } catch (_) {
          newId = null;
        }
      }

      // only set id if we successfully found one
      if (newId != null && newId.isNotEmpty) {
        petProfile = petProfile.copyWith(id: newId);
      }
    } catch (e) {
      rethrow;
    }
  }
}
