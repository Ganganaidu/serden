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

/// Password rules shown in the checklist and used for validation.
typedef _PasswordRule = ({
  String label,
  bool Function(String) passes,
  String error,
});

final _passwordRules = <_PasswordRule>[
  (
    label: 'At least 8 characters',
    passes: (v) => v.length >= 8,
    error: 'Must be at least 8 characters.',
  ),
  (
    label: 'A lowercase letter (a–z)',
    passes: (v) => v.contains(RegExp(r'[a-z]')),
    error: 'Must include at least one lowercase letter.',
  ),
  (
    label: 'An uppercase letter (A–Z)',
    passes: (v) => v.contains(RegExp(r'[A-Z]')),
    error: 'Must include at least one uppercase letter.',
  ),
  (
    label: 'A number (0–9)',
    passes: (v) => v.contains(RegExp(r'[0-9]')),
    error: 'Must include at least one number.',
  ),
  (
    label: 'A symbol, such as !@#\$%^&*',
    passes: (v) => v.contains(RegExp(r'[^A-Za-z0-9]')),
    error: 'Must include at least one special character.',
  ),
];

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _passwordFocused = false;
  bool _showPassword = false;

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmError;

  static String? _checkPassword(String value) {
    if (value.isEmpty) return 'Required.';
    for (final rule in _passwordRules) {
      if (!rule.passes(value)) return rule.error;
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
    _username.addListener(() {
      if (_usernameError != null && _username.text.trim().isNotEmpty) {
        setState(() => _usernameError = null);
      }
    });
    _password.addListener(_onPasswordChanged);
    _passwordFocus.addListener(_onPasswordFocusChanged);
    _confirmPassword.addListener(_onConfirmChanged);
  }

  /// The checklist shows while the password field is focused; the field's
  /// error line only appears once the user leaves it (or submits).
  void _onPasswordFocusChanged() {
    final focused = _passwordFocus.hasFocus;
    setState(() {
      _passwordFocused = focused;
      if (focused) {
        _passwordError = null;
      } else {
        _passwordError = _password.text.isEmpty
            ? null
            : _checkPassword(_password.text);
      }
    });
  }

  void _onPasswordChanged() {
    setState(() {
      if (_confirmPassword.text.isNotEmpty) {
        _confirmError = _password.text != _confirmPassword.text
            ? 'Passwords do not match.'
            : null;
      }
    });
  }

  void _onConfirmChanged() {
    setState(() {
      _confirmError =
          _confirmPassword.text.isNotEmpty &&
              _password.text != _confirmPassword.text
          ? 'Passwords do not match.'
          : null;
    });
  }

  @override
  void dispose() {
    _passwordFocus.removeListener(_onPasswordFocusChanged);
    _passwordFocus.dispose();
    _email.dispose();
    _username.dispose();
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
    final usernameError = _username.text.trim().isEmpty ? 'Required.' : null;
    final passError = _checkPassword(_password.text);
    final confirmError = _confirmPassword.text.isEmpty
        ? 'Required.'
        : _password.text != _confirmPassword.text
        ? 'Passwords do not match.'
        : null;

    if (firstNameError != null ||
        lastNameError != null ||
        emailError != null ||
        usernameError != null ||
        passError != null ||
        confirmError != null) {
      setState(() {
        _firstNameError = firstNameError;
        _lastNameError = lastNameError;
        _emailError = emailError;
        _usernameError = usernameError;
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
        username: _username.text.trim(),
        password: _password.text,
        confirmPassword: _confirmPassword.text,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        turnstileToken: token,
      ),
    );
  }

  /// "User already exists with this email or username" → offer Sign in.
  void _showAlreadyExists(String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Account already exists'),
        content: Text('$message\n\nPlease sign in instead.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(AppRoutes.signIn);
            },
            child: const Text('Sign in'),
          ),
        ],
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
          if (state.message.toLowerCase().contains('already')) {
            _showAlreadyExists(state.message);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
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
                  hint: 'Enter first name',
                  controller: _firstName,
                  keyboardType: TextInputType.name,
                  errorText: _firstNameError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthField(
                  label: 'Last name',
                  hint: 'Enter last name',
                  controller: _lastName,
                  keyboardType: TextInputType.name,
                  errorText: _lastNameError,
                ),
              ),
            ],
          ),
          AuthField(
            label: 'Email address',
            hint: 'you@example.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
          ),
          AuthField(
            label: 'User name',
            hint: 'Choose a username',
            controller: _username,
            errorText: _usernameError,
          ),
          // The checklist is drawn above the field (not in the flow), so it
          // never moves the fields or the Create account button.
          Stack(
            clipBehavior: Clip.none,
            children: [
              AuthField(
                label: 'Password',
                hint: '8+ characters',
                controller: _password,
                focusNode: _passwordFocus,
                obscureText: !_showPassword,
                errorText: _passwordError,
                suffix: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.inkFaint,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                // Shifts the card up by its own height so its bottom edge
                // sits just above the Password label.
                child: FractionalTranslation(
                  translation: const Offset(0, -1),
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _passwordFocused ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PasswordRulesCard(password: _password.text),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
              onPressed: state is AuthSubmitting ? null : _submit,
              child: state is AuthSubmitting
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
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.inkSoft,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'By continuing you agree to our Terms of Service and Privacy Policy',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating checklist shown above the password field while it is focused.
class _PasswordRulesCard extends StatelessWidget {
  final String password;

  const _PasswordRulesCard({required this.password});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your password needs',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (final rule in _passwordRules)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _RuleRow(label: rule.label, met: rule.passes(password)),
            ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final bool met;

  const _RuleRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.check_rounded,
          size: 16,
          color: met ? AppColors.greenDeep : AppColors.inkFaint,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              height: 1.2,
              color: met ? AppColors.greenDeep : AppColors.inkSoft,
              fontWeight: met ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
