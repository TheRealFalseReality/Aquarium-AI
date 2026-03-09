// ignore_for_file: use_build_context_synchronously

import 'dart:math' show pi;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/app_check_service.dart';
import '../services/auth_service.dart';
import '../services/remote_config_service.dart';

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

  /// Route to push after successful sign-in. Defaults to '/profile'.
  String _returnRoute = '/profile';
  Object? _returnRouteArgs;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(screenName: 'auth_screen');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _returnRoute = (args['returnRoute'] as String?) ?? '/profile';
      _returnRouteArgs = args['returnRouteArgs'];
    }
  }

  void _navigateAfterSignIn() {
    Navigator.of(context).pushReplacementNamed(
      _returnRoute,
      arguments: _returnRouteArgs,
    );
  }

  /// Called when the user chooses to skip sign-in entirely.
  /// If launched from the onboarding flow (returnRoute is '/onboarding'),
  /// navigates directly to that onboarding step.
  /// Otherwise, just pops back to the previous screen.
  void _skipSignIn() {
    final args = _returnRouteArgs;
    // Check if we came from onboarding (return route goes back to onboarding).
    if (_returnRoute == '/onboarding' && args is Map &&
        args.containsKey('initialPage')) {
      Navigator.of(context).pushReplacementNamed(
        '/onboarding',
        arguments: args,
      );
    } else {
      Navigator.of(context).maybePop();
    }
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

    // Fire a reCAPTCHA v3 token request on web before sign-in/sign-up.
    // Non-enforcing: errors are swallowed and the login proceeds regardless.
    await AppCheckService.requestToken();

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
        _navigateAfterSignIn();
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
    // Fire a reCAPTCHA v3 token request on web before sign-in.
    await AppCheckService.requestToken();
    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null && mounted) {
        AnalyticsService.logFeatureUsed(featureName: 'auth_sign_in_google');
        _navigateAfterSignIn();
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
    // Fire a reCAPTCHA v3 token request on web before sign-in.
    await AppCheckService.requestToken();
    try {
      final user = await AuthService.signInWithFacebook();
      if (user != null && mounted) {
        AnalyticsService.logFeatureUsed(featureName: 'auth_sign_in_facebook');
        _navigateAfterSignIn();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isSocialLoading = false);
    }
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
                    if (!RemoteConfigService.hideFacebookLogin) ...[
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
                    ],

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

                    // Continue as Guest (creates anonymous account)
                    const Divider(height: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.person_outline),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l10n.authContinueAsGuest),
                              Text(
                                l10n.authContinueAsGuestDesc,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          onPressed: _isLoading || _isSocialLoading
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  // Fire a reCAPTCHA v3 token request on web before
                                  // anonymous sign-in.
                                  await AppCheckService.requestToken();
                                  await AuthService.signInAnonymously();
                                  if (mounted) {
                                    AnalyticsService.logFeatureUsed(
                                      featureName: 'auth_sign_in_anonymous',
                                    );
                                    setState(() => _isLoading = false);
                                    _navigateAfterSignIn();
                                  }
                                },
                        ),
                        const SizedBox(height: 8),
                        // Truly skip sign-in — no account created
                        TextButton(
                          onPressed: _isLoading || _isSocialLoading
                              ? null
                              : _skipSignIn,
                          child: Text(
                            l10n.authSkipSignIn,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
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
