import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/gmail_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/page_header.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _gmailConnecting = false;

  Future<void> _connectGmail() async {
    setState(() => _gmailConnecting = true);
    final account = await GmailService.signInWithGmail();
    setState(() => _gmailConnecting = false);

    if (account != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gmail connected: ${account.email}'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    }
  }

  Future<void> _disconnectGmail() async {
    await GmailService.signOut();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final gmailUser = GmailService.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Settings',
          subtitle: 'Manage your account and email sending settings',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Card
                _SettingsCard(
                  title: 'Account',
                  icon: Icons.person_rounded,
                  child: Column(
                    children: [
                      _SettingsRow(
                        label: 'Name',
                        value: user?.displayName ?? '-',
                      ),
                      const Divider(),
                      _SettingsRow(
                        label: 'Email',
                        value: user?.email ?? '-',
                      ),
                      const Divider(),
                      _SettingsRow(
                        label: 'Account ID',
                        value: user?.uid ?? '-',
                        valueStyle: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                // Gmail Connection Card
                _SettingsCard(
                  title: 'Gmail Connection',
                  icon: Icons.mail_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect your Gmail account to send emails. BulkMailer uses Gmail API with OAuth 2.0 — your password is never stored.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white54),
                      ),
                      const Gap(16),
                      if (gmailUser != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF4CAF50)),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Connected',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                color: const Color(0xFF4CAF50))),
                                    Text(gmailUser.email,
                                        style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _disconnectGmail,
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.error),
                                child: const Text('Disconnect'),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed:
                              _gmailConnecting ? null : _connectGmail,
                          icon: _gmailConnecting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.mail_rounded, size: 18),
                          label: Text(_gmailConnecting
                              ? 'Connecting...'
                              : 'Connect Gmail'),
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(24),
                // Sending Limits Card
                _SettingsCard(
                  title: 'Sending Limits',
                  icon: Icons.speed_rounded,
                  child: Column(
                    children: [
                      const _SettingsRow(
                        label: 'Rate limit',
                        value: '10 emails / minute',
                        valueColor: Color(0xFF6C63FF),
                      ),
                      const Divider(),
                      const _SettingsRow(
                        label: 'Daily limit',
                        value: '500 emails / day (Gmail free)',
                        valueColor: Color(0xFFFF9800),
                      ),
                      const Divider(),
                      const _SettingsRow(
                        label: 'Workspace limit',
                        value: '2,000 emails / day',
                        valueColor: Color(0xFF4CAF50),
                      ),
                      const Gap(16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Emails are sent in staggered batches to protect your account from spam filters. A Cloud Function handles the queue automatically.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                // Danger Zone
                _SettingsCard(
                  title: 'Danger Zone',
                  icon: Icons.warning_rounded,
                  iconColor: theme.colorScheme.error,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sign Out',
                                style: theme.textTheme.titleSmall),
                            Text('Sign out of your BulkMailer account',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.white38)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await ref
                              .read(authNotifierProvider.notifier)
                              .signOut();
                          if (context.mounted) context.go('/login');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                              color: theme.colorScheme.error),
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
                const Gap(48),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Gap(8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const Gap(16),
            const Divider(),
            const Gap(16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;

  const _SettingsRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.white38)),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  theme.textTheme.bodyMedium
                      ?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
