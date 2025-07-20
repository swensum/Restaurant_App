import 'package:admin_panel/utils/supabase_clients.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
final supabaseService = SupabaseService();

Future<void> initAdminFCM() async {
  // Request permission (iOS mostly)
  final NotificationSettings settings = await _firebaseMessaging.requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // Get initial token and save it
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      debugPrint('Admin FCM Token: $fcmToken');
      await supabaseService.saveAdminTokenToDB(fcmToken);
    }

    // Listen for token refresh and update DB
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('Admin FCM Token refreshed: $newToken');
      await supabaseService.saveAdminTokenToDB(newToken);
    });
  } else {
    debugPrint('FCM permission not granted');
  }
}
