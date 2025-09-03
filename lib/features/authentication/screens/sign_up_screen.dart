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

  // MODIFICATION 1: Variables d'état pour le suivi des exigences du mot de passe.
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

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

  // MODIFICATION 2: Mise à jour de la fonction pour vérifier chaque critère individuellement.
  void _checkPasswordStrength(String password) {
    setState(() {
      _hasMinLength = password.length >= 16;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

      double strength = 0;
      if (_hasMinLength) strength += 0.25;
      if (_hasUppercase) strength += 0.25;
      if (_hasLowercase) strength += 0.125;
      if (_hasNumber) strength += 0.125;
      if (_hasSpecialChar) strength += 0.25;

      _passwordStrength = strength > 1.0 ? 1.0 : strength; // Clamp value to 1.0

      if (password.isEmpty) {
        _passwordFeedback = '';
      } else if (_passwordStrength >= 0.8) {
        _passwordFeedback = 'Strong';
      } else if (_passwordStrength >= 0.4) {
        _passwordFeedback = 'Medium';
      } else {
        _passwordFeedback = 'Weak';
      }
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
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a password.';
              if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasNumber || !_hasSpecialChar) {
                return 'Please meet all password requirements.';
              }
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
            const SizedBox(height: 8),
            // MODIFICATION 3: Ajout de l'encart des exigences.
            _buildPasswordRequirements(),
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
  
  // MODIFICATION 4: Nouveau widget pour afficher l'encart des exigences.
  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequirementRow('At least 16 characters', _hasMinLength),
          _buildRequirementRow('An uppercase letter (A-Z)', _hasUppercase),
          _buildRequirementRow('A lowercase letter (a-z)', _hasLowercase),
          _buildRequirementRow('A number (0-9)', _hasNumber),
          _buildRequirementRow('A special character (!@#\$%)', _hasSpecialChar),
        ],
      ),
    );
  }

  // MODIFICATION 5: Widget helper pour une ligne d'exigence.
  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.remove_circle_outline,
            color: isMet ? Colors.green : Colors.grey.shade500,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.grey.shade800 : Colors.grey.shade600,
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

