import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/campaign_model.dart';
import '../../../data/services/firebase_service.dart';
import '../../../shared/providers/campaign_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';

class CampaignsPage extends ConsumerWidget {
  const CampaignsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(campaignsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Campaigns',
          subtitle: 'Manage your email campaigns',
          actions: [
            ElevatedButton.icon(
              onPressed: () => context.go('/campaigns/create'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Campaign'),
            ),
          ],
        ),
        Expanded(
          child: campaignsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (campaigns) {
              if (campaigns.isEmpty) {
                return EmptyState(
                  icon: Icons.campaign_rounded,
                  title: 'No campaigns yet',
                  subtitle:
                      'Create your first campaign and start sending personalized emails',
                  buttonLabel: 'Create Campaign',
                  onButtonPressed: () =>
                      context.go('/campaigns/create'),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ListView.separated(
                  itemCount: campaigns.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (_, i) =>
                      _CampaignTile(campaign: campaigns[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CampaignTile extends StatelessWidget {
  final CampaignModel campaign;

  const _CampaignTile({required this.campaign});

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
      case CampaignStatus.paused:
        return const Color(0xFFFF9800);
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(campaign.status);
    final fmt = DateFormat('MMM d, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.campaign_rounded, color: color, size: 24),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(campaign.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Gap(2),
                  Text(campaign.subject,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white38)),
                  const Gap(8),
                  Row(
                    children: [
                      _Chip(
                          label:
                              campaign.status.name.toUpperCase(),
                          color: color),
                      const Gap(8),
                      _Chip(
                        label: campaign.listName,
                        color: Colors.white24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(24),
            // Stats
            if (campaign.status != CampaignStatus.draft)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${campaign.stats.sent}/${campaign.stats.total}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text('delivered',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white38)),
                  const Gap(4),
                  Text(
                    '${campaign.stats.deliveryRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            const Gap(24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(campaign.createdAt),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white38),
                ),
                if (campaign.status == CampaignStatus.sending) ...[
                  const Gap(8),
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      value: campaign.stats.total == 0
                          ? 0
                          : campaign.stats.sent /
                              campaign.stats.total,
                      backgroundColor: color.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ],
            ),
            const Gap(8),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Campaign'),
                      content: Text(
                          'Delete "${campaign.name}"?'),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.error),
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await FirebaseService.deleteCampaign(
                        campaign.id);
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'delete', child: Text('Delete')),
              ],
              icon: const Icon(Icons.more_vert_rounded,
                  color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
