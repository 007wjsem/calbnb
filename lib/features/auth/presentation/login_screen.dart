import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../data/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/roles.dart';
import 'package:go_router/go_router.dart';
import 'package:calbnb/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      await ref.read(authControllerProvider.notifier).login(email, password);
    } catch (e) {
      // UI-level safety net for macOS Keychain errors:
      // Even if the repository throws, Firebase may have authenticated the user
      // in memory. Check both the Riverpod state and FirebaseAuth.instance.currentUser.
      final errStr = e.toString().toLowerCase();
      final isKeychainErr = errStr.contains('keychain') ||
          errStr.contains('nslocalizedfailurereasonerrorkey');

      if (isKeychainErr) {
        // Try to recover: load user data if the auth state was set despite the error.
        final appUser = ref.read(authControllerProvider);
        final fbUser = fb.FirebaseAuth.instance.currentUser;

        if (appUser != null) {
          // Repository recovery succeeded — just navigate.
          if (mounted) {
            if (mounted) setState(() => _isLoading = false);
            final role = appUser.role;
            if (role == AppRole.cleaner || role == AppRole.inspector) {
              context.go('/assignments');
            } else {
              context.go('/');
            }
          }
          return;
        } else if (fbUser != null) {
          // Firebase has a session but the app state wasn't set — try loading manually.
          try {
            await ref.read(authControllerProvider.notifier).login(
              _emailController.text.trim(),
              _passwordController.text,
            );
          } catch (_) {}
          if (mounted) {
            final role = ref.read(authControllerProvider)?.role;
            if (mounted) setState(() => _isLoading = false);
            if (role != null) {
              if (role == AppRole.cleaner || role == AppRole.inspector) {
                context.go('/assignments');
              } else {
                context.go('/');
              }
              return;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    // Navigate on success (no error thrown).
    if (mounted && _error == null) {
      final role = ref.read(authControllerProvider)?.role;
      if (role == AppRole.cleaner || role == AppRole.inspector) {
        context.go('/assignments');
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.sidebarBg, AppColors.primary, AppColors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & heading
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Image.asset('assets/images/logo.png', height: 88),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.appTitle,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.loginTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.loginSubtitle,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.emailHint,
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: l10n.passwordHint,
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(l10n.loginButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.go('/register_company'),
                          child: Text(
                            l10n.registerButton,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '© ${DateTime.now().year} ${l10n.appTitle}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
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
