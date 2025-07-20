import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/common/fav_provider.dart';
import 'package:flutter_application/common/provider.dart';
import 'package:flutter_application/supabase_init.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/utils/firebase_messaging_service.dart';

import 'package:flutter_application/welcome_page.dart';

import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 debugPrint("Initializing Firebase...");
await Firebase.initializeApp();
debugPrint("Firebase initialized");

 debugPrint("Initializing Supabase...");
await SupabaseInitializer.initialize();
debugPrint("Supabase initialized");

  
  
debugPrint("Running app...");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),

       
      ],
      child: const MyApp(),
    ),
  );
   final firebaseMessagingService = FirebaseMessagingService();
  await firebaseMessagingService.initialize();
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Welcome',
      home:const WelcomePage(),
      theme: AppTheme.darkTheme(),
      debugShowCheckedModeBanner: false,
  
    );
  }
}
