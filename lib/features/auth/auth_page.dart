import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/services/error_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../router/app_routes.dart';

const _termsOfUseUrl =
    'https://sites.google.com/view/steintechnologies/terms-of-use';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Sign In'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A90E2), Color(0xFF3E77D2), Color(0xFF211C7E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.vpn_key_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Access Your Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Securely manage your orders and profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 48),

                // Login Card
                Card(
                  color: const Color(0xFF11204F),
                  elevation: 12,
                  shadowColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFD32F2F),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (_loading)
                          const CircularProgressIndicator(color: Colors.white)
                        else
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            icon: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset(
                                'assets/images/google_logo.webp',
                                width: 24,
                                height: 24,
                              ),
                            ),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () async {
                              setState(() {
                                _loading = true;
                                _error = null;
                              });
                              try {
                                await ref
                                    .read(authServiceProvider)
                                    .signInWithGoogle();
                              } catch (e, stackTrace) {
                                ErrorHandler.handle(
                                  e,
                                  stackTrace,
                                  context: 'Google Sign-In',
                                  showToUser: true,
                                );
                                setState(() {
                                  _error = 'Sign in failed: $e';
                                });
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _loading = false;
                                  });
                                }
                              }
                            },
                          ),
                        const SizedBox(height: 20),
                        _buildTermsNotice(context),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.goNamed(AppRoute.welcomeName),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsNotice(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white70, height: 1.4),
        children: [
          const TextSpan(text: 'By signing in, you agree to our '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: InkWell(
              onTap: () => _openTermsOfUse(),
              child: Text(
                'Terms of Use',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const TextSpan(text: ' and acknowledge our privacy practices.'),
        ],
      ),
    );
  }

  Future<void> _openTermsOfUse() async {
    final uri = Uri.parse(_termsOfUseUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace,
        context: 'Opening Terms of Use',
        showToUser: true,
      );
    }
  }
}
