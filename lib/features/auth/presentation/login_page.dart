import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Left panel — branding
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F1117),
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                    const Color(0xFF0F1117),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.mail_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const Gap(12),
                        Text('BulkMailer',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    Text('Email marketing\nthat actually works.',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        )),
                    const Gap(20),
                    Text(
                      'Import your contacts, design beautiful campaigns,\nand send personalized emails — all from one place.',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: Colors.white60, height: 1.6),
                    ),
                    const Gap(48),
                    const _FeatureBullet(
                        icon: Icons.upload_file_rounded,
                        text: 'Import contacts from Excel/CSV'),
                    const Gap(16),
                    const _FeatureBullet(
                        icon: Icons.person_rounded,
                        text: 'Personalize with {{first_name}} merge tags'),
                    const Gap(16),
                    const _FeatureBullet(
                        icon: Icons.mark_email_read_rounded,
                        text: 'Send safely via Gmail — no spam risk'),
                    const Gap(16),
                    const _FeatureBullet(
                        icon: Icons.bar_chart_rounded,
                        text: 'Track opens, clicks & deliveries'),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          // Right panel — sign in
          Expanded(
            flex: 4,
            child: Container(
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome back',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Gap(8),
                  Text('Sign in to your BulkMailer account',
                      style: theme.textTheme.bodyMedium),
                  const Gap(48),
                  // Google Sign In button
                  authAsync.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _GoogleSignInButton(
                          onTap: () async {
                            final success = await ref
                                .read(authNotifierProvider.notifier)
                                .signInWithGoogle();
                            if (success && context.mounted) {
                              context.go('/dashboard');
                            }
                          },
                        ),
                  if (authAsync.hasError) ...[
                    const Gap(16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Sign in failed. Please try again.',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                  const Gap(32),
                  Text(
                    'By signing in, you agree to our Terms of Service.\nYour Gmail credentials are only used to send emails on your behalf.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white30),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GoogleSignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/favicon.ico',
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.g_mobiledata_rounded,
                      color: Colors.red, size: 24),
            ),
            const Gap(12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20),
        const Gap(12),
        Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 15)),
      ],
    );
  }
}
