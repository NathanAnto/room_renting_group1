
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'firebase_options.dart';

// Pages principales
import 'features/apartments/screens/apartments_page.dart';
import 'features/apartments/screens/edit_apartment_page.dart';

// Auth
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/sign_up_screen.dart';
import 'features/authentication/screens/forgot_password_screen.dart';
import 'auth_gate.dart';


// Settings / About
import 'features/profile/screens/settings_screen.dart';
import 'features/profile/screens/about_screens.dart';

// Modèles
import 'core/models/apartment.dart';

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
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup' ||
            state.matchedLocation == '/forgot';

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

        // Settings & About
        GoRoute(path: SettingsScreen.route, builder: (ctx, s) => const SettingsScreen()),
        GoRoute(path: AboutScreen.route, builder: (ctx, s) => const AboutScreen()),

        // Edit apartment (ouverture via context.push('/edit-apartment', extra: Apartment?))
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
    return ShadApp.custom(
      theme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: ShadSlateColorScheme.dark(),
      ),
      appBuilder: (context) {
        return MaterialApp.router(
          title: 'Room Renting',
          debugShowCheckedModeBanner: false,
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
