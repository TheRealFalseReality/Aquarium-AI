// ignore_for_file: use_build_context_synchronously

import 'dart:math' show pi;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/purchase_provider.dart' show debugBypassAppCheckEnforcementProvider;
import '../services/analytics_service.dart';
import '../services/app_check_service.dart';
import '../services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSocialLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'auth_screen');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Enforce App Check (reCAPTCHA v3) on web before sign-in/sign-up.
    if (!await _checkAppCheck()) return;

    try {
      User? user;
      if (_isSignUp) {
        user = await AuthService.signUpWithEmail(
          _emailController.text,
          _passwordController.text,
          displayName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
        );
      } else {
        user = await AuthService.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      }

      if (user != null && mounted) {
        AnalyticsService.logFeatureUsed(
          featureName: _isSignUp ? 'auth_sign_up_email' : 'auth_sign_in_email',
        );
        Navigator.of(context).pushReplacementNamed('/profile');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSocialLoading = true;
      _errorMessage = null;
    });

    // Enforce App Check (reCAPTCHA v3) on web before sign-in.
    if (!await _checkAppCheck(isSocial: true)) return;

    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null && mounted) {
        AnalyticsService.logFeatureUsed(featureName: 'auth_sign_in_google');
        Navigator.of(context).pushReplacementNamed('/profile');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isSocialLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      _isSocialLoading = true;
      _errorMessage = null;
    });

    // Enforce App Check (reCAPTCHA v3) on web before sign-in.
    if (!await _checkAppCheck(isSocial: true)) return;

    try {
      final user = await AuthService.signInWithFacebook();
      if (user != null && mounted) {
        AnalyticsService.logFeatureUsed(featureName: 'auth_sign_in_facebook');
        Navigator.of(context).pushReplacementNamed('/profile');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isSocialLoading = false);
    }
  }

  /// Verifies the Firebase App Check token (reCAPTCHA v3) on web before a
  /// sign-in or sign-up operation.
  ///
  /// Returns `true` when the check passes (or when enforcement is bypassed in
  /// a debug build), and `false` when the check fails and the operation must
  /// be aborted.  When returning `false` the relevant loading flag is reset
  /// and [_errorMessage] is set so the user sees an explanatory message.
  ///
  /// [isSocial] should be `true` for Google and Facebook sign-in flows which
  /// use [_isSocialLoading]; leave it `false` (default) for email/password and
  /// anonymous flows which use [_isLoading].
  Future<bool> _checkAppCheck({bool isSocial = false}) async {
    // App Check (reCAPTCHA v3) is only applicable on the web platform.
    // On Android/iOS the attestation is handled transparently by the SDK.
    if (!kIsWeb) return true;

    // In debug builds, honour the bypass toggle so developers can test the
    // sign-in flow without triggering a real reCAPTCHA evaluation.
    if (kDebugMode) {
      final bypass = ref.read(debugBypassAppCheckEnforcementProvider);
      if (bypass) {
        debugPrint('AppCheck enforcement bypassed (debug mode)');
        return true;
      }
    }

    final passed = await AppCheckService.verifyToken();
    if (!passed) {
      if (mounted) {
        setState(() {
          if (isSocial) {
            _isSocialLoading = false;
          } else {
            _isLoading = false;
          }
          _errorMessage =
              AppLocalizations.of(context)!.authErrorAppCheckFailed;
        });
      }
    }
    return passed;
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(
        () => _errorMessage = AppLocalizations.of(context)!.authEmailRequired,
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.authPasswordResetSent),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'user-not-found':
        return l10n.authErrorUserNotFound;
      case 'wrong-password':
        return l10n.authErrorWrongPassword;
      case 'email-already-in-use':
        return l10n.authErrorEmailInUse;
      case 'invalid-email':
        return l10n.authErrorInvalidEmail;
      case 'weak-password':
        return l10n.authErrorWeakPassword;
      case 'too-many-requests':
        return l10n.authErrorTooManyRequests;
      case 'network-request-failed':
        return l10n.authErrorNetwork;
      default:
        return l10n.authErrorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? l10n.authSignUp : l10n.authSignIn),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Icon(Icons.set_meal, size: 64, color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      _isSignUp ? l10n.authSignUpTitle : l10n.authSignInTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? l10n.authSignUpSubtitle
                          : l10n.authSignInSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // ── Social sign-in buttons ────────────────────────────
                    _SocialSignInButton(
                      label: l10n.authSignInWithGoogle,
                      icon: const _GoogleIcon(),
                      isLoading: _isSocialLoading,
                      onPressed: _isSocialLoading || _isLoading
                          ? null
                          : _signInWithGoogle,
                    ),
                    const SizedBox(height: 8),
                    _SocialSignInButton(
                      label: l10n.authSignInWithFacebook,
                      icon: const Icon(
                        Icons.facebook,
                        color: Color(0xFF1877F2),
                        size: 22,
                      ),
                      isLoading: _isSocialLoading,
                      onPressed: _isSocialLoading || _isLoading
                          ? null
                          : _signInWithFacebook,
                    ),

                    // ── Divider ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              l10n.authOrDivider,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                    ),

                    // Display name (sign-up only)
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.authDisplayName,
                          prefixIcon: const Icon(Icons.person_outline),
                          border: const OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: l10n.authEmail,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.authEmailRequired;
                        }
                        final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(v.trim())) {
                          return l10n.authErrorInvalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.authPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.authPasswordRequired;
                        }
                        if (_isSignUp && v.length < 6) {
                          return l10n.authPasswordTooShort;
                        }
                        return null;
                      },
                    ),

                    // Forgot password
                    if (!_isSignUp) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _forgotPassword,
                          child: Text(l10n.authForgotPassword),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 8),

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit button
                    FilledButton(
                      onPressed: _isLoading || _isSocialLoading
                          ? null
                          : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isSignUp ? l10n.authSignUp : l10n.authSignIn),
                    ),
                    const SizedBox(height: 16),

                    // Toggle sign-in / sign-up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp
                              ? l10n.authAlreadyHaveAccount
                              : l10n.authDontHaveAccount,
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _isSignUp = !_isSignUp;
                            _errorMessage = null;
                          }),
                          child: Text(
                            _isSignUp ? l10n.authSignIn : l10n.authSignUp,
                          ),
                        ),
                      ],
                    ),

                    // Continue anonymously
                    const Divider(height: 32),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.no_accounts_outlined),
                      label: Text(l10n.authContinueAnonymously),
                      onPressed: _isLoading || _isSocialLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              // Enforce App Check (reCAPTCHA v3) on web before
                              // anonymous sign-in.
                              if (!await _checkAppCheck()) return;
                              await AuthService.signInAnonymously();
                              if (mounted) {
                                AnalyticsService.logFeatureUsed(
                                  featureName: 'auth_sign_in_anonymous',
                                );
                                setState(() => _isLoading = false);
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/profile');
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Social sign-in button ────────────────────────────────────────────────────

class _SocialSignInButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _SocialSignInButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 22, height: 22, child: icon),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Google icon (coloured G logo drawn with Canvas) ─────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(22, 22), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Draw coloured arcs for the Google logo approximation
    const colors = [
      Color(0xFF4285F4), // Blue
      Color(0xFF34A853), // Green
      Color(0xFFFBBC05), // Yellow
      Color(0xFFEA4335), // Red
    ];
    const sweeps = [90.0, 90.0, 90.0, 90.0];
    const starts = [-45.0, 45.0, 135.0, 225.0];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r * 0.72),
        starts[i] * pi / 180,
        sweeps[i] * pi / 180,
        false,
        paint,
      );
    }

    // White cutout for the G bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - size.height * 0.12,
        r * 0.72,
        size.height * 0.24,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
