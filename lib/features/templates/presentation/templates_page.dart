import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../data/models/template_model.dart';
import '../../../data/services/firebase_service.dart';
import '../../../shared/providers/templates_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';

class TemplatesPage extends ConsumerWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Templates',
          subtitle: 'Design reusable email templates',
          actions: [
            ElevatedButton.icon(
              onPressed: () => context.go('/templates/edit/new'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Template'),
            ),
          ],
        ),
        Expanded(
          child: templatesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (templates) {
              if (templates.isEmpty) {
                return EmptyState(
                  icon: Icons.wysiwyg_rounded,
                  title: 'No templates yet',
                  subtitle:
                      'Create your first email template with personalization tags',
                  buttonLabel: 'Create Template',
                  onButtonPressed: () =>
                      context.go('/templates/edit/new'),
                );
              }
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32),
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (_, i) =>
                      _TemplateCard(template: templates[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateModel template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => context.go('/templates/edit/${template.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.wysiwyg_rounded,
                        color: theme.colorScheme.primary, size: 20),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Template'),
                            content: Text(
                                'Delete "${template.name}"?'),
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
                          await FirebaseService.deleteTemplate(
                              template.id);
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                    icon: const Icon(Icons.more_vert_rounded,
                        color: Colors.white38, size: 20),
                  ),
                ],
              ),
              const Gap(12),
              Text(template.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const Gap(4),
              Text(template.subject,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white38),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              Text(
                'Updated ${timeago.format(template.updatedAt ?? template.createdAt)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
