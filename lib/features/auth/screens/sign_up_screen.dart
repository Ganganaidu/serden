import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/turnstile_sheet.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  bool _showPassword = false;

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  static String? _checkPassword(String value) {
    if (value.isEmpty) return 'Required.';
    if (value.length < 8) return 'Must be at least 8 characters.';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must include at least one uppercase letter.';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Must include at least one lowercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must include at least one number.';
    }
    if (!value.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return 'Must include at least one special character.';
    }
    return null;
  }

  static String? _checkEmail(String value) {
    if (value.isEmpty) return 'Required.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : 'Enter a valid email address.';
  }

  @override
  void initState() {
    super.initState();
    // Clear field errors as the user edits; keep live password rule validation.
    _firstName.addListener(() {
      if (_firstNameError != null && _firstName.text.trim().isNotEmpty) {
        setState(() => _firstNameError = null);
      }
    });
    _lastName.addListener(() {
      if (_lastNameError != null && _lastName.text.trim().isNotEmpty) {
        setState(() => _lastNameError = null);
      }
    });
    _email.addListener(() {
      if (_emailError != null) setState(() => _emailError = null);
    });
    _password.addListener(_onPasswordChanged);
    _confirmPassword.addListener(_onConfirmChanged);
  }

  void _onPasswordChanged() {
    setState(() {
      // Only show live rule errors after the user has started typing.
      _passwordError = _password.text.isEmpty
          ? null
          : _checkPassword(_password.text);
      if (_confirmPassword.text.isNotEmpty) {
        _confirmError = _password.text != _confirmPassword.text
            ? 'Passwords do not match.'
            : null;
      }
    });
  }

  void _onConfirmChanged() {
    setState(() {
      _confirmError = _confirmPassword.text.isNotEmpty &&
              _password.text != _confirmPassword.text
          ? 'Passwords do not match.'
          : null;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstNameError = _firstName.text.trim().isEmpty ? 'Required.' : null;
    final lastNameError = _lastName.text.trim().isEmpty ? 'Required.' : null;
    final emailError = _checkEmail(_email.text.trim());
    final passError = _checkPassword(_password.text);
    final confirmError = _confirmPassword.text.isEmpty
        ? 'Required.'
        : _password.text != _confirmPassword.text
            ? 'Passwords do not match.'
            : null;

    if (firstNameError != null ||
        lastNameError != null ||
        emailError != null ||
        passError != null ||
        confirmError != null) {
      setState(() {
        _firstNameError = firstNameError;
        _lastNameError = lastNameError;
        _emailError = emailError;
        _passwordError = passError;
        _confirmError = confirmError;
      });
      return;
    }

    // Obtain a Turnstile token before calling the registration API.
    final token = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TurnstileSheet(),
    );

    if (token == null || !mounted) return;

    context.read<AuthBloc>().add(
          AuthSignUpRequested(
            email: _email.text.trim(),
            password: _password.text,
            confirmPassword: _confirmPassword.text,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            turnstileToken: token,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistered) {
          context.go(AppRoutes.emailVerification, extra: state.email);
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: AuthScaffold(
        title: 'Create your free account',
        subtitle: 'Start winning local jobs in minutes.',
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AuthField(
                  label: 'First name',
                  hint: 'Kevin',
                  controller: _firstName,
                  keyboardType: TextInputType.name,
                  errorText: _firstNameError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthField(
                  label: 'Last name',
                  hint: 'Smith',
                  controller: _lastName,
                  keyboardType: TextInputType.name,
                  errorText: _lastNameError,
                ),
              ),
            ],
          ),
          AuthField(
            label: 'User name',
            hint: 'you@yourbusiness.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
          ),
          AuthField(
            label: 'Password',
            hint: '8+ characters',
            controller: _password,
            obscureText: !_showPassword,
            helper: _passwordError == null
                ? 'Uppercase, lowercase, number, and special character.'
                : null,
            errorText: _passwordError,
            suffix: IconButton(
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppColors.inkFaint,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          AuthField(
            label: 'Confirm password',
            hint: 'Re-enter your password',
            controller: _confirmPassword,
            obscureText: !_showPassword,
            errorText: _confirmError,
          ),
          const SizedBox(height: 8),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => ElevatedButton(
              onPressed: state is AuthLoading ? null : _submit,
              child: state is AuthLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create account'),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text.rich(
              TextSpan(
                text: 'Already have an account? ',
                children: [
                  TextSpan(
                    text: 'Sign in',
                    style: const TextStyle(
                      color: AppColors.green700,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.go(AppRoutes.signIn),
                  ),
                ],
              ),
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.inkSoft, height: 1.3),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'By continuing you agree to our Terms of Service and Privacy Policy',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontSize: 11.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
