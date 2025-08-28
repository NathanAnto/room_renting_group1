// main.dart
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/listings/screens/create_listing_screen.dart';
import 'firebase_options.dart';
import 'features/listings/screens/listings_screen.dart'; // Import the new screen

import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'main_shell.dart';

// Imports relatifs
import 'features/apartments/screens/apartments_page.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/sign_up_screen.dart';
import 'features/authentication/screens/forgot_password_screen.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // Écoute des changements d'état d'authentification
    final authStream = FirebaseAuth.instance.authStateChanges();

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: GoRouterRefreshStream(authStream),
      redirect: (context, state) {
        final isLoggedIn = FirebaseAuth.instance.currentUser != null;
        final loggingRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup' ||
            state.matchedLocation == '/forgot';

        if (!isLoggedIn && !loggingRoute) return '/login';
        if (isLoggedIn && loggingRoute) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (ctx, s) => const ApartmentsPage()),
        GoRoute(path: '/login', builder: (ctx, s) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (ctx, s) => const SignUpScreen()),
        GoRoute(path: '/forgot', builder: (ctx, s) => const ForgotPasswordScreen()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShadApp.custom
      theme: ShadThemeData(
      themeMode: ThemeMode.dark,
      darkTheme: ShadThemeData(
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
          routerConfig: _router,
        );
      },
    );
  }
}


/// Permet à GoRouter de se rafraîchir quand l'état Firebase Auth change
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}