import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Créer un compte', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Mot de passe'),
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                    obscureText: true,
                    validator: (v) => (v != _password.text) ? 'Les mots de passe ne correspondent pas' : null,
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            setState(() { _loading = true; _error = null; });
                            try {
                              await _auth.signUpWithEmail(_email.text.trim(), _password.text.trim());
                              if (mounted) context.go('/');
                            } catch (e) {
                              setState(() => _error = 'Création de compte échouée');
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Créer mon compte'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => context.go('/login'), child: const Text('Déjà inscrit ? Se connecter')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
