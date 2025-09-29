import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/donors%20navigation%20bar/FavoritePage.dart';
import 'package:pawlytics/views/donors/donors%20navigation%20bar/HomePage.dart';
import 'package:pawlytics/views/donors/donors%20navigation%20bar/MenuPage.dart';
import 'package:pawlytics/views/donors/donors%20navigation%20bar/TransactionPage.dart';

class RoutePage extends StatefulWidget {
  final int initialIndex;

  const RoutePage({super.key, this.initialIndex = 0});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _pages = const [
    HomePage(),
    TransactionsPage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF23344E),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz),
              label: "Transactions",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: "Favorites"),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: "Menu"),
          ],
        ),
      ),
    );
  }
}
