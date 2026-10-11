import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_store.dart';

class AppAuth {
  static bool isAuthenticated = false;
  static String? authenticatedEmail;

  static String get validEmail => AccountStore.instance.email;
  static String get validPassword => AccountStore.instance.password;

  static bool validateCredentials(String email, String password) {
    return AccountStore.instance.validateCredentials(email, password);
  }

  static bool signIn(String email, String password) {
    if (!validateCredentials(email, password)) {
      return false;
    }

    authenticatedEmail = email.trim().toLowerCase();
    isAuthenticated = true;
    return true;
  }

  static void signOut() {
    authenticatedEmail = null;
    isAuthenticated = false;
  }

  static String? changeEmail({
    required String currentPassword,
    required String newEmail,
    String confirmEmail = '',
  }) {
    final error = AccountStore.instance.changeEmail(
      currentPassword: currentPassword,
      newEmail: newEmail,
      confirmEmail: confirmEmail,
    );
    if (error == null) authenticatedEmail = AccountStore.instance.email;
    return error;
  }

  static String? changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => AccountStore.instance.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
    confirmPassword: confirmPassword,
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password';
    if (value!.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _login() async {
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!AppAuth.signIn(email, password)) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email or password. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const darkBlue = Color(0xFF1E3A8A);
    const textDark = Color(0xFF0F172A);
    const textGrey = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 430,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.08),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryBlue, darkBlue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome back',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue managing attendance.',
                    style: GoogleFonts.inter(fontSize: 14, color: textGrey),
                  ),
                  const SizedBox(height: 26),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    validator: _validateEmail,
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    autofillHints: const [AutofillHints.password],
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: primaryBlue,
                            size: 18,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Administrator access',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textGrey,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Contact an administrator to reset the password.',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.inter(
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: primaryBlue.withValues(
                          alpha: 0.65,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Log In',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'Use ${AppAuth.validEmail} with your password to sign in',
                      style: GoogleFonts.inter(
                        color: textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
