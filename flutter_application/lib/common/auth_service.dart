import 'package:flutter/material.dart';
import 'package:flutter_application/common/otp_verification_screen.dart';
import 'package:flutter_application/utils/firebase_token_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application/Registration/login.dart';

class AuthService {

  final FirebaseTokenService _firebaseTokenService = FirebaseTokenService();

  final SupabaseClient supabase = Supabase.instance.client;
  Future<bool> signUpWithOtp({
    required BuildContext context,
    required String email,
    required String password,
    required String username,
    required String phone,
  }) async {
    try {
      await supabase.auth.signInWithOtp(
        email: email.trim(),
        data: {
          'username': username.trim(),
          'phone': phone.trim(),
        },
      );

      // Store all registration data temporarily
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('temp_password', password.trim());
      await prefs.setString('temp_username', username.trim());
      await prefs.setString('temp_phone', phone.trim());

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyEmailOtpPage(email: email),
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending OTP: ${e.toString()}')),
        );
      }
      return false;
    }
  }






  Future<bool> verifyEmailAndSignup({
    required BuildContext context,
    required String email,
    required String token,
  }) async {
    try {
      // Verify OTP
      final authResponse = await supabase.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.signup,
      );

      if (authResponse.user == null) {
        throw Exception('User not created after OTP verification');
      }

      // Get the stored data
      final prefs = await SharedPreferences.getInstance();
      final password = prefs.getString('temp_password');
      final username = prefs.getString('temp_username');
      final phone = prefs.getString('temp_phone');

      if (password == null || username == null || phone == null) {
        throw Exception('Registration data not found');
      }

      // Update user's password
      await supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      // Create or update user profile
      await _ensureUserProfile(
        userId: authResponse.user!.id,
        email: email,
        username: username,
        phone: phone,
      );

     
      await prefs.remove('temp_password');
      await prefs.remove('temp_username');
      await prefs.remove('temp_phone');

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.toString()}')),
        );
      }
      return false;
    }
  }

  Future<void> _ensureUserProfile({
    required String userId,
    required String email,
    required String username,
    required String phone,
  }) async {
    try {
      // Upsert profile data (insert or update if exists)
      await supabase.from('profiles').upsert({
        'id': userId,
        'email': email.trim(),
        'username': username.trim(),
        'phone': phone.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'email_verified': true,
      });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }



  Future<Map<String, String>> getCurrentUser() async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception("No user is logged in");
  }

  final response = await supabase
    .from('profiles')
    .select('username, email, phone, bio')
    .eq('id', user.id)
    .single();

  return {
  'username': response['username'] ?? 'User',
  'email': response['email'] ?? '',
  'phone': response['phone'] ?? '',
  'bio': response['bio'] ?? '',
};
}


  Future<bool> isEmailVerified(String userId) async {
    try {
      final userResponse = await supabase
          .from('profiles')
          .select('email_confirmed_at')
          .eq('id', userId)
          .single();

      return userResponse['email_confirmed_at'] != null;
    } catch (e) {
      debugPrint("Error checking email verification: $e");
      return false;
    }
  }

  Future<bool> resendOtp({
    required BuildContext context,
    required String email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('temp_username') ?? '';
      final phone = prefs.getString('temp_phone') ?? '';

      await supabase.auth.signInWithOtp(
        email: email.trim(),
        data: {
          'username': username.trim(),
          'phone': phone.trim(),
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP resent successfully")),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Resend OTP failed: ${e.toString()}")),
        );
      }
      return false;
    }
  }

  Future<bool> login(
      BuildContext context, String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.session != null && response.user != null) {
        // Check if email is verified
        if (response.user?.emailConfirmedAt == null) {
          await supabase.auth.signOut();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please verify your email before logging in.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          throw Exception("Email not verified");
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
          await _firebaseTokenService.saveDeviceToken(response.user!.id);

        return true;
      }

      throw Exception("Login failed - no session or user returned");
    } catch (e) {
      String errorMessage = "Login failed";
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = "Invalid email or password";
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = "Please verify your email first";
      } else if (e.toString().contains('too many requests')) {
        errorMessage = "Too many attempts. Please try again later";
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Logout
  Future<bool> logout(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint("Logout error: $e");
      return false;
    }
  }

  // Check login status
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final session = supabase.auth.currentSession;
      return isLoggedIn && session != null;
    } catch (e) {
      debugPrint("Session check error: $e");
      return false;
    }
  }


Future<bool> sendPasswordResetOtp({
  required BuildContext context,
  required String email,
}) async {
  try {
    await supabase.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: false, // Important: don't create new user
    );

    // Store email temporarily for verification
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reset_email', email.trim());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your email'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending OTP: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return false;
  }
}

Future<bool> verifyResetOtp({
  required BuildContext context,
  required String otp,
}) async {
  try {
    // Get the stored email
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('reset_email');
    
    if (email == null) {
      throw Exception('Email not found for password reset');
    }

  
    final authResponse = await supabase.auth.verifyOTP(
      email: email,
      token: otp.trim(),
      type: OtpType.recovery, // Important: use recovery type
    );

    return authResponse.user != null;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP verification failed: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return false;
  }
}

Future<bool> updatePassword({
  required BuildContext context,
  required String newPassword,
}) async {
  try {
    // Update password
    await supabase.auth.updateUser(
      UserAttributes(password: newPassword.trim()),
    );

    // Clear temporary data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reset_email');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password update failed: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return false;
  }
}
Future<bool> signInWithGoogle(BuildContext context) async {
  try {
    const webClientId = '961062848288-n647f8mdhvbpjdj32s5ndfko742b30jo.apps.googleusercontent.com';
    const iosClientId = 'YOUR-IOS-CLIENT-ID.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId, // Optional: use only if targeting iOS
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in aborted');
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Missing Google credentials');
    }

    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    if (response.session != null && response.user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Sign-in successful!")),
        );
      }
      return true;
    } else {
      throw Exception('Supabase Google sign-in failed');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-in Error: ${e.toString()}')),
      );
    }
    return false;
  }
}
 
Future<bool> signInWithFacebook(BuildContext context) async {
  try {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'io.supabase.flutter://login-callback', 
    );
    
    return true;
    
  } catch (e) {
    
    debugPrint('Facebook login error: $e');
    
     if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facebook login failed.')),
      );
    }
    return false;
  }
}
Future<void> updateUserProfile(Map<String, dynamic> updatedData) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception("No user is logged in");
  }

  // Ensure the ID is attached
  updatedData['id'] = user.id;

  try {
    await supabase.from('profiles').upsert(updatedData);
  } catch (e) {
    debugPrint("Error updating profile: $e");
    rethrow;
  }
}


}