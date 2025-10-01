import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/admin-dashboard.dart';
import 'package:pawlytics/views/admin/admin-menu.dart';
import 'package:pawlytics/views/admin/pet-profiles/pet-profiles.dart';

class NavigationButtonAdmin extends StatefulWidget {
  const NavigationButtonAdmin({super.key});

  @override
  State<NavigationButtonAdmin> createState() => _NavigationButtonAdminState();
}

class _NavigationButtonAdminState extends State<NavigationButtonAdmin> {
  static const brandColor = Color(0xA627374D);

  int _currentIndex = 0;

  final _pages = const <Widget>[
    AdminDashboard(),
    PetProfiles(),
    // _Stub(title: 'Pet Profiles'),
    _Stub(title: 'Notifications'),
    menuBar(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Color.fromARGB(255, 15, 45, 80),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          currentIndex: _currentIndex,

          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: "Pet Profiles",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: "Notifications",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
          ],
        ),
      ),
    );
  }
}

class _Stub extends StatelessWidget {
  final String title;
  const _Stub({required this.title, super.key});
  @override
  Widget build(BuildContext context) => Center(child: Text(title));
}
