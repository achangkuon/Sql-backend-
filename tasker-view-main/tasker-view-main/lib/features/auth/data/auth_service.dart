import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'phone': phone,
      },
    );
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  // Sign in with OTP (Email)
  Future<void> signInWithOtp({required String email}) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'io.supabase.servitask://login-callback/',
    );
  }

  // Verify OTP token for email
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    return await _supabase.auth.verifyOTP(
      type: type,
      token: token,
      email: email,
    );
  }

  // Resend OTP token
  Future<void> resendOTP({
    required String email,
    OtpType type = OtpType.signup,
  }) async {
    await _supabase.auth.resend(
      type: type,
      email: email,
    );
  }

  // Check if user has a profile record
  Future<bool> isProfileComplete(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }
}



