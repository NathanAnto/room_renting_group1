// lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shadcn_ui/shadcn_ui.dart';

import 'firebase_options.dart';

// Pages principales
import 'features/apartments/screens/apartments_page.dart';
import 'features/apartments/screens/edit_apartment_page.dart';

// Auth
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/sign_up_screen.dart';
import 'features/authentication/screens/forgot_password_screen.dart';

// Settings / About
import 'features/profile/screens/settings_screen.dart';
import 'features/profile/screens/about_screens.dart';

// Modèles
import 'core/models/apartment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

    final authStream = FirebaseAuth.instance.authStateChanges();

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: GoRouterRefreshStream(authStream),
      redirect: (context, state) {
        final isLoggedIn = FirebaseAuth.instance.currentUser != null;
        final isAuthRoute = {
          '/login',
          '/signup',
          '/forgot',
        }.contains(state.matchedLocation);

        if (!isLoggedIn && !isAuthRoute) return '/login';
        if (isLoggedIn && isAuthRoute) return '/';
        return null;
      },
      routes: [
        // Home
        GoRoute(path: '/', builder: (ctx, s) => const ApartmentsPage()),

        // Auth
        GoRoute(path: '/login', builder: (ctx, s) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (ctx, s) => const SignUpScreen()),
        GoRoute(path: '/forgot', builder: (ctx, s) => const ForgotPasswordScreen()),

        // Settings & About (en supposant des routes statiques dans les écrans)
        GoRoute(path: SettingsScreen.route, builder: (ctx, s) => const SettingsScreen()),
        GoRoute(path: AboutScreen.route, builder: (ctx, s) => const AboutScreen()),

        // Edit apartment (ouvrir via context.push('/edit-apartment', extra: Apartment?))
        GoRoute(
          path: '/edit-apartment',
          builder: (ctx, s) {
            final apt = s.extra is Apartment ? s.extra as Apartment : null;
            return EditApartmentPage(apartment: apt);
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Not found')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Route inconnue: ${state.matchedLocation}'),
              const SizedBox(height: 12),
              ShadButton(
                onPressed: () => context.go('/'),
                child: const Text('Retour à l’accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Matérialise l’appli avec le Router et injecte le thème shadcn_ui
    return MaterialApp.router(
      title: 'Room Renting',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      builder: (context, child) {
        // Fournit le thème shadcn_ui et ses utilitaires au dessous
      return ShadApp(
        theme: ShadThemeData(
          brightness: Brightness.dark,
          colorScheme: ShadSlateColorScheme.dark(),
        ),
        builder: (context, _) {
          return ShadAppBuilder(child: child!);
        },
      );
      },
    );
  }
}

/// Rafraîchit GoRouter lorsque l’état Firebase Auth change
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
