import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/model/register-model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🔹 Sign in existing user
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 🔹 Sign up new user + store in `users` table
  Future<AuthResponse> signUpWithEmailAndPassword(
    RegisterModel userModel,
  ) async {
    final response = await _supabase.auth.signUp(
      email: userModel.email,
      password: userModel.password,
      data: {
        'fullName': userModel.fullName,
        'phone_number': userModel.phoneNumber,
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception("Signup failed: User not created.");
    }

    // Insert into your custom `users` table
    await _supabase.from('registration').insert({
      'id': user.id, // same as Supabase Auth user ID
      'fullName': userModel.fullName,
      'email': userModel.email,
      'phone_number': userModel.phoneNumber,
      'created_at': userModel.createdAt.toIso8601String(),
    });

    return response;
  }

  /// 🔹 Sign out
  Future<void> signOut() async {
    return await _supabase.auth.signOut();
  }

  /// 🔹 Update user metadata (in `auth.users` + optional in custom table)
  Future<void> updateUserName(String fullName) async {
    await _supabase.auth.updateUser(
      UserAttributes(data: {'fullName': fullName}),
    );

    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase
          .from('registration')
          .update({'fullName': fullName})
          .eq('id', user.id);
    }
  }

  /// 🔹 Get full user info from `users` table
  Future<RegisterModel?> getUserProfile(String userId) async {
    final data = await _supabase
        .from('registration')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return RegisterModel.fromMap(data);
  }

  /// 🔹 Get current logged-in user
  User? get currentUser => _supabase.auth.currentUser;
}
