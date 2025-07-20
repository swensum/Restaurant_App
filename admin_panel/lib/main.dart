import 'package:admin_panel/utils/supabase_init.dart';
import 'package:admin_panel/utils/theme.dart';
import 'package:admin_panel/welcome_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';



final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(); 
  await SupabaseInitializer.initialize();
  
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      home: const WelcomePage(),
      theme: AppTheme.darkTheme(),
      debugShowCheckedModeBanner: false,
      
    );
  }
}
