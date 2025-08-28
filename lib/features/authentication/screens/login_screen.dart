// lib/features/authentication/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:room_renting_group1/features/authentication/screens/sign_up_screen.dart';
import 'package:room_renting_group1/features/authentication/screens/forgot_password_screen.dart';
import '../../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView( // Permet de scroller si le clavier apparaît
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ TITRE ET SLOGAN DE L'APPLICATION
                Column(
                  children: [
                    Icon(Icons.home_work_outlined, size: 80, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'G1',
                      style: theme.textTheme.displayMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ease your room renting',
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                  ],
                ),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 8, // Ajoute un peu d'ombre pour le style
                  child: Padding(
                    padding: const EdgeInsets.all(28), // Padding légèrement augmenté
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bienvenue',
                            style: theme.textTheme.headlineSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connectez-vous pour continuer',
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 24), // Espacement plus grand

                          TextFormField(
                            controller: _email,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                          ),
                          const SizedBox(height: 16), // Espacement standard
                          TextFormField(
                            controller: _password,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
                          ),
                          const SizedBox(height: 16),

                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                            ),
                          
                          SizedBox(
                            width: double.infinity, // Bouton pleine largeur
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: theme.colorScheme.primary,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate()) return;
                                      setState(() { _isLoading = true; _error = null; });
                                      try {
                                        await _auth.signInWithEmail(_email.text.trim(), _password.text.trim());
                                      } catch (e) {
                                        setState(() => _error = 'Échec de connexion');
                                      } finally {
                                        if (mounted) setState(() => _isLoading = false);
                                      }
                                    },
                              child: _isLoading
                                  ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text('Se connecter', style: theme.textTheme.titleMedium!.copyWith(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.primary,
                              ),
                              child: const Text('Mot de passe oublié ?'),
                            ),
                          ),
                          
                          const SizedBox(height: 12), // Espacement avant le lien de création de compte
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Pas de compte ?", style: theme.textTheme.bodyMedium),
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                ),
                                child: const Text('Créer un compte'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}