import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/contact_list_model.dart';
import '../../../data/services/firebase_service.dart';
import '../../../shared/providers/contacts_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  Future<void> _createList() async {
    final name = await _showNameDialog(context, 'New Contact List');
    if (name == null || name.isEmpty) return;
    await FirebaseService.createList(name);
  }

  Future<String?> _showNameDialog(BuildContext context, String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'List name',
            hintText: 'e.g., Newsletter Subscribers',
          ),
          autofocus: true,
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, ) {
    final listsAsync = ref.watch(contactListsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Contacts',
          subtitle: 'Manage your subscriber lists',
          actions: [
            ElevatedButton.icon(
              onPressed: _createList,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New List'),
            ),
          ],
        ),
        Expanded(
          child: listsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (lists) {
              if (lists.isEmpty) {
                return EmptyState(
                  icon: Icons.people_rounded,
                  title: 'No contact lists yet',
                  subtitle:
                      'Create a list and import your contacts from Excel or CSV',
                  buttonLabel: 'Create List',
                  onButtonPressed: _createList,
                );
              }
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32),
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: lists.length,
                  itemBuilder: (_, i) =>
                      _ListCard(list: lists[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ListCard extends ConsumerWidget {
  final ContactListModel list;

  const _ListCard({required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () {
          ref.read(selectedListIdProvider.notifier).state = list.id;
          context.go('/contacts/import/${list.id}');
        },
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
                    child: Icon(Icons.people_rounded,
                        color: theme.colorScheme.primary, size: 20),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete List'),
                            content: Text(
                                'Delete "${list.name}" and all its contacts?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error),
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await FirebaseService.deleteList(list.id);
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                    icon: const Icon(Icons.more_vert_rounded,
                        color: Colors.white38, size: 20),
                  ),
                ],
              ),
              const Gap(12),
              Text(list.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Gap(4),
              Text('${list.count} subscribers',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white38)),
              const Spacer(),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.go('/contacts/import/${list.id}'),
                    icon: const Icon(Icons.upload_rounded, size: 16),
                    label: const Text('Import'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
