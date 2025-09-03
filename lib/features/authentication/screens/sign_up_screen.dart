// lib/features/authentication/screens/sign_up_screen.dart

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  String? _error;

  double _passwordStrength = 0.0;
  String _passwordFeedback = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _auth.signUpWithEmail(_emailController.text.trim(), _passwordController.text.trim());
    } catch (e) {
      setState(() => _error = 'Account creation failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      double strength = 0;
      String feedback = 'Weak';
      
      if (password.isEmpty) {
        strength = 0;
        feedback = '';
      } else {
        // MODIFICATION 2: La longueur minimale est maintenant de 16 caractères.
        if (password.length >= 16) strength += 0.25;
        if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
        if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.25;
        if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.125;
        if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.125;

        if (strength >= 0.8) {
            feedback = 'Strong';
        } else if (strength >= 0.4) {
            feedback = 'Medium';
        }
      }
      _passwordStrength = strength;
      _passwordFeedback = feedback;
    });
  }

  Color _getPasswordStrengthColor() {
    if (_passwordStrength < 0.4) return Colors.red;
    if (_passwordStrength < 0.8) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    const primaryBlue = Color(0xFF0D47A1);
    final lightGreyBackground = Colors.grey[200];

    return Scaffold(
      backgroundColor: lightGreyBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
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
                  _buildHeader(textTheme),
                  const SizedBox(height: 32),
                  _buildSignUpForm(textTheme, primaryBlue),
                  const SizedBox(height: 24),
                  _buildLoginLink(context, textTheme, primaryBlue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Column(
      children: [
        Text(
          'Create Account',
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Get started by filling out the form below.',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpForm(TextTheme textTheme, Color primaryColor) {
    final inputTextStyle = TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w500);
    final labelTextStyle = TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500);
    final iconColor = Colors.grey[500];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            cursorColor: Colors.grey[800],
            style: inputTextStyle,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: labelTextStyle,
              prefixIcon: Icon(Icons.alternate_email_rounded, color: iconColor),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter an email address.';
              final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
              if (!emailRegex.hasMatch(value)) return 'Please enter a valid email.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            cursorColor: Colors.grey[800],
            style: inputTextStyle,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: labelTextStyle,
              prefixIcon: Icon(Icons.lock_outline_rounded, color: iconColor),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            obscureText: true,
            onChanged: _checkPasswordStrength,
            // MODIFICATION 3: Validateur de mot de passe mis à jour pour 16 caractères.
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a password.';
              if (value.length < 16) return 'Password must be at least 16 characters long.';
              if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Must contain an uppercase letter.';
              if (!RegExp(r'[a-z]').hasMatch(value)) return 'Must contain a lowercase letter.';
              if (!RegExp(r'[0-9]').hasMatch(value)) return 'Must contain a number.';
              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Must contain a special character.';
              return null;
            },
          ),
          
          if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor: Colors.grey[300],
                      color: _getPasswordStrengthColor(),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _passwordFeedback,
                    style: textTheme.bodySmall?.copyWith(color: _getPasswordStrengthColor(), fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ],

          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            cursorColor: Colors.grey[800],
            style: inputTextStyle,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              labelStyle: labelTextStyle,
              prefixIcon: Icon(Icons.lock_person_rounded, color: iconColor),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            obscureText: true,
            validator: (value) => (value != _passwordController.text) ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
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
            onPressed: _isLoading ? null : _signUp,
            child: _isLoading
                ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                : Text(
                    'Create Account',
                    style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context, TextTheme textTheme, Color primaryColor) {
    return TextButton(
      onPressed: () => context.go('/login'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            'Back to Login',
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}

