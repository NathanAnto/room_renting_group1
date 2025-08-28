// lib/main_shell.dart

import 'package:flutter/material.dart';
import 'package:room_renting_group1/features/listings/screens/listings_screen.dart';
import 'package:room_renting_group1/features/profile/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0; // Index de la page actuellement affichée

  // Liste des pages principales de l'application
  static const List<Widget> _pages = <Widget>[
    ListingsScreen(),
    ProfileScreen(),
    // Ajoutez d'autres pages principales ici
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // La AppBar peut aussi être ici pour être persistante
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Logements' : 'Mon Profil'),
      ),
      // Le corps de la page change en fonction de l'index sélectionné
      body: _pages.elementAt(_selectedIndex),
      // La barre de navigation en bas
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Logements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}