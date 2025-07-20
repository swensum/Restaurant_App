import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseTokenService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveDeviceToken(String userId) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken != null) {
      try {
        await _supabase
            .from('user_tokens')
            .upsert({
              'user_id': userId,
              'fcm_token': fcmToken,
            }, onConflict: 'user_id')
            .then((response) {
              debugPrint('FCM token saved to Supabase!');
            });
      } catch (error) {
        debugPrint('Failed to save token: $error');
      }
    } else {
      debugPrint('Failed to get FCM token.');
    }
  }
}