import 'package:flutter/material.dart';
import 'package:flutter_application/common/auth_service.dart';
import 'package:flutter_application/screen/your_orders_page.dart';
import 'package:flutter_application/theme.dart';
import 'package:flutter_application/utils/profile.dart';
import 'package:flutter_application/utils/reviews.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
 State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();

  String? username;
  String? email;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final user = await _authService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      username = user['username'];
      email = user['email'];
    });
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout(context);
  }

  void _showPlaceholderMessage(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title page is not implemented yet')),
    );
  }

  void _navigateWithFade(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        pageBuilder: (_, __, ___) => page,
      ),
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
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const int avatarCount = 5;
    int avatarIndex = 0;

    if (username != null && username!.isNotEmpty) {
      avatarIndex = username!.hashCode.abs() % avatarCount;
    }

    final avatarPath = 'assets/avatar/image${avatarIndex + 1}.jpg';
    final backgroundColor =
        Theme.of(context).bottomAppBarTheme.color ?? Colors.white;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
            child: Container(
              width: double.infinity,
              color: backgroundColor,
              padding: const EdgeInsets.only(top: 60, bottom: 40, left: 20, right: 20),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      avatarPath,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, size: 45, color: AppTheme.defaultIconColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username ?? 'Loading...',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 5),
                        Text(email ?? '',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  _buildMainSection(backgroundColor),
                  const SizedBox(height: 20),
                  _buildSecondarySection(backgroundColor),
                  const SizedBox(height: 20),
                  _buildLogoutButton(backgroundColor),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection(Color backgroundColor) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildMenuItem(
              Icons.person_outline,
              'Personal Information',
              iconColor: Colors.blue,
              onTap: () => _navigateWithFade(const EditProfilePage()),
            ),
            const Divider(height: 1, color: Colors.transparent),
            _buildMenuItem(
              Icons.shopping_bag_outlined,
              'My Orders',
              iconColor: Colors.green,
            onTap: () => _navigateWithFade(const MyOrdersPage()),
            ),
          ],
        ),
      );

  Widget _buildSecondarySection(Color backgroundColor) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildMenuItem(
              Icons.star_border,
              'User Reviews',
              iconColor: Colors.orange,
              onTap: () => _navigateWithFade(const ReviewPage()),
            ),
            const Divider(height: 1, color: Colors.transparent),
            _buildMenuItem(
              Icons.notifications_none,
              'Notification',
              iconColor: Colors.purple,
              onTap: () => _showPlaceholderMessage('Notification'),
            ),
            const Divider(height: 1, color: Colors.transparent),
            _buildMenuItem(
              Icons.call_end_outlined,
              'Contact',
              iconColor: Colors.green,
              onTap: () => _showPlaceholderMessage('Contact'),
            ),
            const Divider(height: 1, color: Colors.transparent),
            _buildMenuItem(
              Icons.info_outline,
              'About Us',
              iconColor: Colors.teal,
              onTap: () => _showPlaceholderMessage('About Us'),
            ),
          ],
        ),
      );

  Widget _buildLogoutButton(Color backgroundColor) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
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
