import 'package:admin_panel/navbar/menu.dart';
import 'package:admin_panel/navbar/orderpage.dart';
import 'package:admin_panel/screen/admin_dashboard.dart';

import 'package:admin_panel/screen/notification_panel.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showNotificationPanel = false;
  int _selectedIndex = 0;

  void _toggleNotificationPanel() {
    setState(() {
      _showNotificationPanel = !_showNotificationPanel;
    });
  }

  void _closeNotificationPanel() {
    setState(() {
      _showNotificationPanel = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _showNotificationPanel = false;
    });
  }

  final List<String> _titles = ['Admin Dashboard', 'Orders','Menu'];

  final List<Widget> _pages = const [
    AdminDashboardPage(),
    AdminOrdersPage (),
    MenuPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      extendBody: true, 
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: Theme.of(context).textTheme.titleLarge,
        ),
        elevation: 0,
        toolbarHeight: 45,
     
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _toggleNotificationPanel,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          if (_showNotificationPanel)
            NotificationPanel(onClose: _closeNotificationPanel),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: const Color(0xFFD6E0D5),
          elevation: 10,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Admin',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_basket),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shop),
              label: 'Menu',
            ),
          ],
        ),
      ),
      
    );
  }
}
