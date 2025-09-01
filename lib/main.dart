// lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:room_renting_group1/features/dashboard/screens/dashboard_screen.dart';
import 'package:room_renting_group1/features/listings/screens/listings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:shadcn_ui/shadcn_ui.dart';

import 'firebase_options.dart';

// --- Pages ---
// Coquille principale
import 'main_shell.dart'; 
// Pages dans la coquille
import 'features/profile/screens/profile_screen.dart';
// Pages hors de la coquille
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/sign_up_screen.dart';
import 'features/authentication/screens/forgot_password_screen.dart';
import 'features/profile/screens/create_profile_screen.dart';
import 'features/apartments/screens/edit_apartment_page.dart';
import 'features/profile/screens/settings_screen.dart';
import 'features/profile/screens/about_screens.dart';
// --- Admin ---
import 'features/admin/screens/admin_users_screen.dart';

// --- Modèles ---
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
      redirect: (context, state) async {
        final user = FirebaseAuth.instance.currentUser;
        final isLoggedIn = user != null;
        final isAuthRoute = {'/login', '/signup', '/forgot'}.contains(state.matchedLocation);

        if (!isLoggedIn) {
          return isAuthRoute ? null : '/login';
        }

        final profileDoc = await FirebaseFirestore.instance.collection('Profile').doc(user.uid).get();
        final profileExists = profileDoc.exists;
        final isCreatingProfile = state.matchedLocation == '/create-profile';

        if (!profileExists && !isCreatingProfile) {
          return '/create-profile';
        }

        if (isAuthRoute) {
          return '/';
        }
        return null;
      },
      routes: [
        // --- ROUTES AVEC LA BARRE DE NAVIGATION (DANS LE MAINSHELL) ---
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (ctx, s) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/',
              builder: (ctx, s) => const ListingsScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (ctx, s) => const ProfileScreen(),
            ),
          ],
        ),

        // --- ROUTES SANS LA BARRE DE NAVIGATION (PLEIN ÉCRAN) ---
        GoRoute(path: '/login', builder: (ctx, s) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (ctx, s) => const SignUpScreen()),
        GoRoute(path: '/forgot', builder: (ctx, s) => const ForgotPasswordScreen()),
        GoRoute(path: '/create-profile', builder: (ctx, s) => const CreateProfileScreen()),
        
        // --- AUTRES ROUTES PLEIN ÉCRAN ---
        GoRoute(path: SettingsScreen.route, builder: (ctx, s) => const SettingsScreen()),
        GoRoute(path: AboutScreen.route, builder: (ctx, s) => const AboutScreen()),
        GoRoute(path: '/admin/users', builder: (ctx, s) => const AdminUsersScreen()),
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
