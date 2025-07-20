import 'package:admin_panel/pages/aboutpage.dart';
import 'package:admin_panel/screen/admin_login.dart';
import 'package:admin_panel/screen/completedorderpage.dart';
import 'package:admin_panel/screen/addfood.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
   State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
 
Future<void> _logout(BuildContext context) async {
  try {
    // Sign out from Supabase
    await Supabase.instance.client.auth.signOut();

    // Clear isLoggedIn from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn'); // <-- This line is important

    // Navigate to login screen and remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
      (route) => false,
    );
  } catch (e) {
    debugPrint('❌ Logout error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logout failed. Please try again.')),
    );
  }
}


  void _showPlaceholderMessage(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title page is not implemented yet')),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Color? iconBgColor,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconBgColor ?? Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: iconColor ?? Colors.black87, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: textColor),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            _buildMainSection(),
            const SizedBox(height: 20),
            _buildSecondarySection(),
            const SizedBox(height: 20),
            _buildLogoutButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSection() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomAppBarTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildMenuItem(
              Icons.food_bank_outlined,
              'AddFood',
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminAddFoodPage ()),
                );
              }
            ),
            const Divider(height: 1, color: Colors.transparent),
            _buildMenuItem(
              Icons.analytics,
              'Completed Orders',
              iconColor: Colors.green,
            onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CompletedOrdersPage  ()),
                );
              }
            ),
          ],
        ),
      );

  Widget _buildSecondarySection() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomAppBarTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildMenuItem(
              Icons.settings,
              'Preferences',
              iconColor: Colors.orange,
              onTap: () => _showPlaceholderMessage('Preferences'),
            ),
            const Divider(height: 1, color: Colors.transparent),
            _buildMenuItem(
              Icons.support_agent,
              'Support',
              iconColor: Colors.purple,
              onTap: () => _showPlaceholderMessage('Support'),
            ),
            const Divider(height: 1, color: Colors.transparent),
            _buildMenuItem(
              Icons.info_outline,
              'About App',
              iconColor: Colors.teal,
              onTap: ()  {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Aboutpage()),
                );
              },
            ),
          ],
        ),
      );

  Widget _buildLogoutButton() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomAppBarTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildMenuItem(
          Icons.logout,
          'Logout',
          textColor: Colors.red,
          iconColor: Colors.red,
          onTap: () => _logout(context),
        ),
      );
}
