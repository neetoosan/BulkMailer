import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../data/models/campaign_model.dart';
import '../../../shared/providers/campaign_provider.dart';
import '../../../shared/providers/contacts_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/stat_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(campaignsProvider);
    final listsAsync = ref.watch(contactListsProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Dashboard',
            subtitle: 'Overview of your email marketing activity',
            actions: [
              ElevatedButton.icon(
                onPressed: () => context.go('/campaigns/create'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New Campaign'),
              ),
            ],
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: campaignsAsync.when(
              loading: () => const _StatsShimmer(),
              error: (e, _) => const SizedBox.shrink(),
              data: (campaigns) {
                final totalSent = campaigns.fold<int>(
                    0, (sum, c) => sum + c.stats.sent);
                final activeCampaigns = campaigns
                    .where((c) =>
                        c.status == CampaignStatus.sending ||
                        c.status == CampaignStatus.scheduled)
                    .length;
                final totalContacts = listsAsync.valueOrNull?.fold<int>(
                        0, (sum, l) => sum + l.count) ??
                    0;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 280,
                      child: StatCard(
                        title: 'Total Emails Sent',
                        value: totalSent.toString(),
                        icon: Icons.send_rounded,
                        iconColor: const Color(0xFF6C63FF),
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: StatCard(
                        title: 'Total Subscribers',
                        value: totalContacts.toString(),
                        icon: Icons.people_rounded,
                        iconColor: const Color(0xFF03DAC6),
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: StatCard(
                        title: 'Total Campaigns',
                        value: campaigns.length.toString(),
                        icon: Icons.campaign_rounded,
                        iconColor: const Color(0xFFFF9800),
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: StatCard(
                        title: 'Active Campaigns',
                        value: activeCampaigns.toString(),
                        icon: Icons.electric_bolt_rounded,
                        iconColor: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Gap(32),
          // Recent Campaigns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Text('Recent Campaigns',
                    style: theme.textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/campaigns'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const Gap(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: campaignsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (campaigns) {
                if (campaigns.isEmpty) {
                  return EmptyState(
                    icon: Icons.campaign_rounded,
                    title: 'No campaigns yet',
                    subtitle: 'Create your first campaign to start sending emails',
                    buttonLabel: 'Create Campaign',
                    onButtonPressed: () => context.go('/campaigns/create'),
                  );
                }
                return Column(
                  children: campaigns.take(5).map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CampaignRow(campaign: c),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignRow extends StatelessWidget {
  final CampaignModel campaign;

  const _CampaignRow({required this.campaign});

  Color _statusColor(CampaignStatus s) {
    switch (s) {
      case CampaignStatus.sent:
        return const Color(0xFF4CAF50);
      case CampaignStatus.sending:
        return const Color(0xFF6C63FF);
      case CampaignStatus.scheduled:
        return const Color(0xFFFF9800);
      case CampaignStatus.failed:
        return const Color(0xFFCF6679);
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(campaign.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.campaign_rounded, color: color, size: 20),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(campaign.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(campaign.subject,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white38)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    campaign.status.name.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Gap(4),
                Text(
                  '${campaign.stats.sent}/${campaign.stats.total} sent',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white38),
                ),
              ],
            ),
            const Gap(8),
            Text(
              timeago.format(campaign.createdAt),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _ShimmerBox(width: 280, height: 90),
        _ShimmerBox(width: 280, height: 90),
        _ShimmerBox(width: 280, height: 90),
        _ShimmerBox(width: 280, height: 90),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  const _ShimmerBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF21253A),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
