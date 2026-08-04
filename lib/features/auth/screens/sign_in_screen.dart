import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import 'widgets/auth_scaffold.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthBloc>().add(
          AuthSignInRequested(
            email: _email.text.trim(),
            password: _password.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in to your pro account.',
        children: [
          AuthField(
            label: 'Email address',
            hint: 'you@yourbusiness.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          AuthField(
            label: 'Password',
            hint: 'Your password',
            controller: _password,
            obscureText: !_showPassword,
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 4),
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
                  : const Text('Sign in'),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text.rich(
              TextSpan(
                text: "Don't have an account? ",
                children: [
                  TextSpan(
                    text: 'Create one',
                    style: const TextStyle(
                      color: AppColors.green700,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.go(AppRoutes.signUp),
                  ),
                ],
              ),
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.inkSoft, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
