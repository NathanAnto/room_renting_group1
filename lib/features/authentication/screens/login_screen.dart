// lib/features/authentication/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _auth.signInWithEmail(_emailController.text.trim(), _passwordController.text.trim());
    } catch (e) {
      setState(() => _error = 'Login failed. Please check your credentials.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    const primaryBlue = Color(0xFF0D47A1);
    final lightGreyBackground = Colors.grey[200];

    return Scaffold(
      backgroundColor: lightGreyBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(textTheme, primaryBlue),
                  const SizedBox(height: 48),
                  _buildLoginForm(textTheme, primaryBlue),
                  const SizedBox(height: 24), // Increased spacing for better separation
                  _buildSignUpLink(context, textTheme, primaryBlue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme, Color primaryColor) {
    final titleStyle = textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: -1,
    );

    return Column(
      children: [
        Text.rich(
          TextSpan(
            style: titleStyle?.copyWith(color: Colors.black87), // Default style for the span
            children: [
              const TextSpan(text: 'G'),
              TextSpan(
                text: '1',
                style: TextStyle(color: primaryColor), // Blue color for the "1"
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ease your student renting',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(TextTheme textTheme, Color primaryColor) {
    // MODIFICATION: Définition du style pour le texte saisi par l'utilisateur.
    final inputTextStyle = TextStyle(
      color: Colors.grey[900], 
      fontWeight: FontWeight.w500
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            cursorColor: Colors.grey[800],
            style: inputTextStyle, // Appliquer le style ici
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
              prefixIcon: Icon(Icons.alternate_email_rounded, color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            cursorColor: Colors.grey[800],
            style: inputTextStyle, // Appliquer le style ici
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
              prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            obscureText: true,
            validator: (value) {
               if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/forgot'),
              child: Text(
                'Forgot Password?',
                style: textTheme.bodyMedium?.copyWith(color: primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
              ),
            ),

          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: primaryColor,
            ),
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : Text(
                    'Sign In',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context, TextTheme textTheme, Color primaryColor) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey[400]!),
      ),
      onPressed: () => context.go('/signup'),
      child: Text.rich(
        TextSpan(
          text: "Don't have an account? ",
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
          children: [
            TextSpan(
              text: 'Sign Up',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

