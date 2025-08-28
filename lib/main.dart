// Fichier : lib/main.dart (Mis à jour)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'firebase_options.dart';

// Importez le nouveau widget AuthGate
import 'auth_gate.dart';

Future<void> main() async {
  // Assure l'initialisation des bindings Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialise Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Le code de connexion de test a été retiré.
  // La gestion se fait maintenant dans AuthGate.
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.custom(
      theme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      appBuilder: (context) {
        return MaterialApp(
          theme: Theme.of(context),
          builder: (context, child) {
            return ShadAppBuilder(child: child!);
          },
          // On remplace MainShell par AuthGate comme point d'entrée de l'application
          home: const AuthGate(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}