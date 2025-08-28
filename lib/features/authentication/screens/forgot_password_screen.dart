// lib/features/authentication/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _auth = AuthService();
  String? _msg;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réinitialiser le mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading
                ? null
                : () async {
                    setState(() { _loading = true; _msg = null; });
                    try {
                      await _auth.sendPasswordReset(_email.text.trim());
                      setState(() { _msg = 'Email envoyé (si le compte existe).'; });
                    } catch (_) {
                      setState(() { _msg = 'Erreur lors de l’envoi.'; });
                    } finally {
                      setState(() { _loading = false; });
                    }
                  },
            child: _loading 
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Text('Envoyer'),
          ),
          const SizedBox(height: 8),
          if (_msg != null) Text(_msg!),
          const Spacer(),
          
          // ✅ CORRECTION : Remplacement de context.go par Navigator.pop
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Retour')
          ),
        ]),
      ),
    );
  }
}