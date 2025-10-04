// lib/views/admin/controllers/add-pet-controller.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/admin/model/pet-profiles-model.dart';

class PetProfileController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController storyController = TextEditingController();

  /// Local working copy
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

  /* ---------------- persistence ---------------- */

  /// Insert a new pet. Returns `true` on success.
  ///
  /// - Saves `story` as NULL if the text is empty.
  /// - Uses `select('id,uuid,funds,created_at')` to get identifiers and funds back.
  Future<bool> savePet() async {
    updateName();
    updateStory();

    // base payload from the model
    final payload = petProfile.toMapInsert();

    // ensure empty story isn't stored as an empty string
    final story = (petProfile.story ?? '').trim();
    payload['story'] = story.isEmpty ? null : story;

    try {
      final res = await Supabase.instance.client
          .from('pet_profiles')
          .insert(payload)
          .select('id,uuid,funds,created_at') // grab both ids + funds
          .single();

      String? newId = res['id']?.toString();
      String? newUuid = res['uuid']?.toString();

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
        uuid: newUuid,
        createdAt: res['created_at'] != null
            ? DateTime.tryParse(res['created_at'].toString())
            : null,
        funds: newFunds, // will be kept if your model includes funds
      );

      // also sync text controllers in case UI reflects server state
      nameController.text = petProfile.name;
      storyController.text = petProfile.story ?? '';

      return true;
    } on PostgrestException catch (e) {
      debugPrint('Save pet error (Postgrest): ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Save pet error: $e');
      return false;
    }
  }

  /// Update existing pet. Uses a robust `OR` filter so either `id` or `uuid`
  /// can be used as the identifier (whichever is present).
  Future<bool> updatePet() async {
    updateName();
    updateStory();

    final pid = petProfile.dbId; // prefers id, falls back to uuid
    if (pid == null || pid.isEmpty) {
      debugPrint('Update pet error: missing pet id/uuid');
      return false;
    }

    final payload = petProfile.toMapInsert();
    final story = (petProfile.story ?? '').trim();
    payload['story'] = story.isEmpty ? null : story;

    try {
      await Supabase.instance.client
          .from('pet_profiles')
          .update(payload)
          .or('id.eq.$pid,uuid.eq.$pid');

      return true;
    } on PostgrestException catch (e) {
      debugPrint('Update pet error (Postgrest): ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Update pet error: $e');
      return false;
    }
  }
}
