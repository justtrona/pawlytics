import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailAndPassword(
    String email,
    String password,
    String fullName,
  ) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    return response;
  }

  Future<void> signOut() async {
    return await _supabase.auth.signOut();
  }

  Future<void> updateUserName(String fullName) async {
    await _supabase.auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );
  }
}
