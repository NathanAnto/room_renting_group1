// lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'firebase_options.dart';

// --- Main App Shell ---
import 'main_shell.dart';

// --- Screens ---
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/sign_up_screen.dart';
import 'features/authentication/screens/forgot_password_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/listings/screens/listings_screen.dart';
import 'features/profile/screens/create_profile_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/about_screen.dart';
import 'features/settings/screens/privacy_policy_screen.dart';
import 'features/settings/screens/terms_of_service_screen.dart';
import 'features/admin/screens/admin_users_screen.dart';


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
        // --- ROUTES WITH THE NAVIGATION BAR (INSIDE MAINSHELL) ---
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(child: child);
          },
          routes: [
            GoRoute(path: '/dashboard', builder: (ctx, s) => const DashboardScreen()),
            GoRoute(path: '/', builder: (ctx, s) => const ListingsScreen()),
            GoRoute(path: '/profile', builder: (ctx, s) => const ProfileScreen()),
          ],
        ),

        // --- ROUTES WITHOUT THE NAVIGATION BAR (FULL SCREEN) ---
        GoRoute(path: '/login', builder: (ctx, s) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (ctx, s) => const SignUpScreen()),
        GoRoute(path: '/forgot', builder: (ctx, s) => const ForgotPasswordScreen()),
        GoRoute(path: '/create-profile', builder: (ctx, s) => const CreateProfileScreen()),
        
        // --- OTHER FULL SCREEN ROUTES ---
        GoRoute(path: SettingsScreen.route, builder: (ctx, s) => const SettingsScreen()),
        GoRoute(path: AboutScreen.route, builder: (ctx, s) => const AboutScreen()),
        GoRoute(path: PrivacyPolicyScreen.route, builder: (ctx, s) => const PrivacyPolicyScreen()),
        GoRoute(path: TermsOfServiceScreen.route, builder: (ctx, s) => const TermsOfServiceScreen()),
        GoRoute(path: '/admin/users', builder: (ctx, s) => const AdminUsersScreen()),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Unknown route: ${state.matchedLocation}'),
              const SizedBox(height: 12),
              ShadButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to Home'),
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

