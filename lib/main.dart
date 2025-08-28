// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // On remet le code de connexion, il est obligatoire pour l'upload
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: "test_user@gmail.com",
      password: "Test123456"
    );
    print("✅ Connexion de test réussie !");
  } on FirebaseAuthException catch (e) {
    print("🔥 Erreur de connexion de test: ${e.message}");
  }
  
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
          home: const MainShell(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}