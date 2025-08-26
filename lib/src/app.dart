import 'package:flutter/material.dart';
import 'screens/apartments_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Renting CRUD Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const ApartmentsPage(),
    );
  }
}
