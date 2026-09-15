import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/campaign_model.dart';
import '../../../data/models/contact_list_model.dart';
import '../../../data/models/template_model.dart';
import '../../../data/services/firebase_service.dart';
import '../../../shared/providers/contacts_provider.dart';
import '../../../shared/providers/templates_provider.dart';

class CreateCampaignPage extends ConsumerStatefulWidget {
  const CreateCampaignPage({super.key});

  @override
  ConsumerState<CreateCampaignPage> createState() =>
      _CreateCampaignPageState();
}

class _CreateCampaignPageState extends ConsumerState<CreateCampaignPage> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();

  // Step 1
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _fromNameCtrl = TextEditingController();
  final _replyToCtrl = TextEditingController();

  // Step 2
  ContactListModel? _selectedList;

  // Step 3
  TemplateModel? _selectedTemplate;

  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = ['Details', 'Audience', 'Template', 'Review & Send'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Campaign',
                      style: theme.textTheme.headlineMedium),
                  const Gap(4),
                  Text('Create and send a new email campaign',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/campaigns'),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
        const Gap(24),
        // Step progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: List.generate(steps.length, (i) {
              final isDone = i < _step;
              final isActive = i == _step;
              final color = isDone || isActive
                  ? theme.colorScheme.primary
                  : Colors.white24;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone || isActive
                            ? theme.colorScheme.primary
                            : const Color(0xFF2E3252),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i],
                              style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white38,
                                  fontSize: 12,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          if (i < steps.length - 1)
                            Divider(color: color, thickness: 1),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const Gap(32),
        Expanded(
          child: Form(
            key: _formKey,
            child: _buildStep(theme),
          ),
        ),
        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              if (_step > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('Back'),
                ),
              const Spacer(),
              if (_step < 3)
                ElevatedButton(
                  onPressed: _nextStep,
                  child: const Text('Continue'),
                )
              else
                ElevatedButton.icon(
                  onPressed: _sending ? null : _sendCampaign,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_sending
                      ? 'Sending...'
                      : 'Send Campaign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(ThemeData theme) {
    switch (_step) {
      case 0:
        return _Step1Details(
          nameCtrl: _nameCtrl,
          subjectCtrl: _subjectCtrl,
          fromNameCtrl: _fromNameCtrl,
          replyToCtrl: _replyToCtrl,
        );
      case 1:
        return _Step2Audience(
          selected: _selectedList,
          onSelect: (l) => setState(() => _selectedList = l),
          ref: ref,
        );
      case 2:
        return _Step3Template(
          selected: _selectedTemplate,
          onSelect: (t) => setState(() => _selectedTemplate = t),
          ref: ref,
        );
      case 3:
        return _Step4Review(
          name: _nameCtrl.text,
          subject: _subjectCtrl.text,
          fromName: _fromNameCtrl.text,
          list: _selectedList,
          template: _selectedTemplate,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _nextStep() {
    if (_step == 0) {
      if (!_formKey.currentState!.validate()) return;
    }
    if (_step == 1 && _selectedList == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an audience list')),
      );
      return;
    }
    if (_step == 2 && _selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a template')),
      );
      return;
    }
    setState(() => _step++);
  }

  Future<void> _sendCampaign() async {
    if (_selectedList == null || _selectedTemplate == null) return;
    setState(() => _sending = true);

    try {
      final campaign = CampaignModel(
        id: '',
        name: _nameCtrl.text.trim(),
        subject: _subjectCtrl.text.trim(),
        templateId: _selectedTemplate!.id,
        listId: _selectedList!.id,
        listName: _selectedList!.name,
        status: CampaignStatus.sending,
        stats: CampaignStats(total: _selectedList!.count),
        createdAt: DateTime.now(),
        fromName: _fromNameCtrl.text.trim().isNotEmpty
            ? _fromNameCtrl.text.trim()
            : null,
        replyTo: _replyToCtrl.text.trim().isNotEmpty
            ? _replyToCtrl.text.trim()
            : null,
      );

      await FirebaseService.createCampaign(campaign);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Campaign queued for sending! Emails are being sent in the background.')),
        );
        context.go('/campaigns');
      }
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    _fromNameCtrl.dispose();
    _replyToCtrl.dispose();
    super.dispose();
  }
}

class _Step1Details extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController subjectCtrl;
  final TextEditingController fromNameCtrl;
  final TextEditingController replyToCtrl;

  const _Step1Details({
    required this.nameCtrl,
    required this.subjectCtrl,
    required this.fromNameCtrl,
    required this.replyToCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Campaign Details', style: theme.textTheme.titleLarge),
          const Gap(24),
          TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Campaign name *',
              hintText: 'e.g., October Newsletter',
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
          ),
          const Gap(16),
          TextFormField(
            controller: subjectCtrl,
            decoration: const InputDecoration(
              labelText: 'Email subject line *',
              hintText: 'e.g., Check out what\'s new, {{first_name}}!',
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
          ),
          const Gap(16),
          TextFormField(
            controller: fromNameCtrl,
            decoration: const InputDecoration(
              labelText: 'From name (optional)',
              hintText: 'e.g., The BulkMailer Team',
            ),
          ),
          const Gap(16),
          TextFormField(
            controller: replyToCtrl,
            decoration: const InputDecoration(
              labelText: 'Reply-to email (optional)',
              hintText: 'e.g., support@yourcompany.com',
            ),
          ),
        ],
      ),
    );
  }
}

class _Step2Audience extends StatelessWidget {
  final ContactListModel? selected;
  final ValueChanged<ContactListModel> onSelect;
  final WidgetRef ref;

  const _Step2Audience({
    required this.selected,
    required this.onSelect,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listsAsync = ref.watch(contactListsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Audience', style: theme.textTheme.titleLarge),
          const Gap(8),
          Text('Choose the contact list for this campaign',
              style: theme.textTheme.bodyMedium),
          const Gap(24),
          Expanded(
            child: listsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (lists) => ListView.separated(
                itemCount: lists.length,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (_, i) {
                  final list = lists[i];
                  final isSelected = selected?.id == list.id;
                  return Card(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : const Color(0xFF2E3252),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => onSelect(list),
                      title: Text(list.name),
                      subtitle:
                          Text('${list.count} subscribers'),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              color: theme.colorScheme.primary)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step3Template extends StatelessWidget {
  final TemplateModel? selected;
  final ValueChanged<TemplateModel> onSelect;
  final WidgetRef ref;

  const _Step3Template({
    required this.selected,
    required this.onSelect,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templatesAsync = ref.watch(templatesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose Template', style: theme.textTheme.titleLarge),
          const Gap(8),
          Text('Select the email template to use for this campaign',
              style: theme.textTheme.bodyMedium),
          const Gap(24),
          Expanded(
            child: templatesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (templates) => GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                ),
                itemCount: templates.length,
                itemBuilder: (_, i) {
                  final t = templates[i];
                  final isSelected = selected?.id == t.id;
                  return Card(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.15)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : const Color(0xFF2E3252),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => onSelect(t),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.wysiwyg_rounded,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.white38),
                                const Spacer(),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded,
                                      color:
                                          theme.colorScheme.primary),
                              ],
                            ),
                            const Gap(12),
                            Text(t.name,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const Gap(4),
                            Text(t.subject,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                        color: Colors.white38),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step4Review extends StatelessWidget {
  final String name;
  final String subject;
  final String fromName;
  final ContactListModel? list;
  final TemplateModel? template;

  const _Step4Review({
    required this.name,
    required this.subject,
    required this.fromName,
    required this.list,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review & Send', style: theme.textTheme.titleLarge),
          const Gap(8),
          Text('Everything looks good? Click Send Campaign below.',
              style: theme.textTheme.bodyMedium),
          const Gap(24),
          _ReviewCard(
            icon: Icons.campaign_rounded,
            title: 'Campaign',
            items: [
              _ReviewItem('Name', name),
              _ReviewItem('Subject', subject),
              if (fromName.isNotEmpty)
                _ReviewItem('From Name', fromName),
            ],
          ),
          const Gap(16),
          _ReviewCard(
            icon: Icons.people_rounded,
            title: 'Audience',
            items: [
              _ReviewItem('List', list?.name ?? '-'),
              _ReviewItem(
                  'Recipients', '${list?.count ?? 0} subscribers'),
            ],
          ),
          const Gap(16),
          _ReviewCard(
            icon: Icons.wysiwyg_rounded,
            title: 'Template',
            items: [
              _ReviewItem('Name', template?.name ?? '-'),
              _ReviewItem('Subject', template?.subject ?? '-'),
            ],
          ),
          const Gap(24),
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
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF4CAF50)),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Emails will be sent in batches of 10 per minute to protect your Gmail account from spam filters.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_ReviewItem> items;

  const _ReviewCard({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const Gap(8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const Gap(16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(item.label,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.white38)),
                      ),
                      Expanded(
                          child: Text(item.value,
                              style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem {
  final String label;
  final String value;

  const _ReviewItem(this.label, this.value);
}

