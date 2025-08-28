// lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import pour Firestore

import 'package:shadcn_ui/shadcn_ui.dart';

import 'firebase_options.dart';

// Pages principales
import 'features/apartments/screens/apartments_page.dart';
import 'features/apartments/screens/edit_apartment_page.dart';

// Auth
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/sign_up_screen.dart';
import 'features/authentication/screens/forgot_password_screen.dart';
import 'features/profile/screens/create_profile_screen.dart'; // Import de l'écran de création

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
      // La redirection devient "async" pour appeler Firestore
      redirect: (context, state) async {
        final user = FirebaseAuth.instance.currentUser;
        final isLoggedIn = user != null;
        final isAuthRoute = {'/login', '/signup', '/forgot'}.contains(state.matchedLocation);
        
        // Si l'utilisateur n'est pas connecté, il ne peut accéder qu'aux routes d'authentification.
        if (!isLoggedIn) {
          return isAuthRoute ? null : '/login';
        }

        // Si l'utilisateur est connecté, on vérifie si son profil existe
        final profileDoc = await FirebaseFirestore.instance.collection('Profile').doc(user.uid).get();
        final profileExists = profileDoc.exists;
        final isCreatingProfile = state.matchedLocation == '/create-profile';

        // Si le profil n'existe pas ET que l'utilisateur n'est pas déjà sur la page de création,
        // on le force à y aller.
        if (!profileExists && !isCreatingProfile) {
          return '/create-profile';
        }

        // Si l'utilisateur est connecté ET qu'il a un profil (ou est en train d'en créer un),
        // on l'empêche de retourner sur les pages d'authentification.
        if (isAuthRoute) {
          return '/';
        }

        // Aucune redirection n'est nécessaire dans les autres cas.
        return null;
      },
      routes: [
        // Home (page d'accueil après connexion)
        GoRoute(path: '/', builder: (ctx, s) => const ApartmentsPage()),

        // Auth
        GoRoute(path: '/login', builder: (ctx, s) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (ctx, s) => const SignUpScreen()),
        GoRoute(path: '/forgot', builder: (ctx, s) => const ForgotPasswordScreen()),

        // Route pour la création de profil
        GoRoute(path: '/create-profile', builder: (ctx, s) => const CreateProfileScreen()),

        // Settings & About
        GoRoute(path: SettingsScreen.route, builder: (ctx, s) => const SettingsScreen()),
        GoRoute(path: AboutScreen.route, builder: (ctx, s) => const AboutScreen()),

        // Edit apartment
        GoRoute(
          path: '/edit-apartment',
          builder: (ctx, s) {
            final apt = s.extra is Apartment ? s.extra as Apartment : null;
            return EditApartmentPage(apartment: apt);
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page Introuvable')),
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
    return MaterialApp.router(
      title: 'Room Renting',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      builder: (context, child) {
        return ShadApp(
          theme: ShadThemeData(
            brightness: Brightness.dark,
            colorScheme: const ShadSlateColorScheme.dark(),
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