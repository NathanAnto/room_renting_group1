// lib/features/authentication/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _auth = AuthService();
  String? _message;
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
         _message = 'Please enter your email address.';
         _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _auth.sendPasswordReset(_emailController.text.trim());
      setState(() {
        _message = 'Password reset link sent! Check your inbox.';
        _isSuccess = true;
      });
    } catch (_) {
      setState(() {
        _message = 'Failed to send link. Please try again.';
        _isSuccess = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      // MODIFICATION 1: Suppression du bouton retour de l'AppBar.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Empêche Flutter d'ajouter un bouton retour automatiquement
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
                  const SizedBox(height: 48),
                  _buildResetForm(textTheme, primaryBlue),
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
          'Forgot Password?',
          style: textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'No worries! Enter your email and we will send you a reset link.',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm(TextTheme textTheme, Color primaryColor) {
    // MODIFICATION 2: Ajout du style pour le curseur et le texte saisi.
    final inputTextStyle = TextStyle(
      color: Colors.grey[900], 
      fontWeight: FontWeight.w500
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          cursorColor: Colors.grey[800],
          style: inputTextStyle,
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
        ),
        const SizedBox(height: 24),

        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isSuccess ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w500
              ),
            ),
          ),

        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: primaryColor,
          ),
          onPressed: _isLoading ? null : _sendResetLink,
          child: _isLoading
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : Text(
                  'Send Reset Link',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
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
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

