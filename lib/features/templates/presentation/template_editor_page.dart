import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/template_model.dart';
import '../../../data/services/firebase_service.dart';

class TemplateEditorPage extends ConsumerStatefulWidget {
  final String? templateId;

  const TemplateEditorPage({super.key, this.templateId});

  @override
  ConsumerState<TemplateEditorPage> createState() =>
      _TemplateEditorPageState();
}

class _TemplateEditorPageState extends ConsumerState<TemplateEditorPage> {
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _htmlCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _previewMode = false;
  String? _templateId;

  @override
  void initState() {
    super.initState();
    _templateId =
        widget.templateId == 'new' ? null : widget.templateId;
    if (_templateId != null) _loadTemplate();

    // Default template
    if (_templateId == null) {
      _htmlCtrl.text = _defaultTemplate;
    }
  }

  Future<void> _loadTemplate() async {
    setState(() => _loading = true);
    final t = await FirebaseService.getTemplate(_templateId!);
    if (t != null && mounted) {
      _nameCtrl.text = t.name;
      _subjectCtrl.text = t.subject;
      _htmlCtrl.text = t.htmlBody;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final plainText = _htmlCtrl.text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();

    final template = TemplateModel(
      id: _templateId ?? '',
      name: _nameCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      htmlBody: _htmlCtrl.text,
      plainText: plainText,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await FirebaseService.saveTemplate(template);
    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template saved!')),
      );
      context.go('/templates');
    }
  }

  void _insertMergeTag(String tag) {
    final currentText = _htmlCtrl.text;
    final selection = _htmlCtrl.selection;
    final newText = currentText.replaceRange(
      selection.start == -1 ? currentText.length : selection.start,
      selection.end == -1 ? currentText.length : selection.end,
      tag,
    );
    _htmlCtrl.text = newText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading && _templateId != null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _templateId == null
                          ? 'New Template'
                          : 'Edit Template',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const Gap(4),
                    Text('Design your email template',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/templates'),
                  child: const Text('Cancel'),
                ),
                const Gap(8),
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _previewMode = !_previewMode),
                  icon: Icon(_previewMode
                      ? Icons.edit_rounded
                      : Icons.preview_rounded,
                      size: 18),
                  label: Text(_previewMode ? 'Edit' : 'Preview'),
                ),
                const Gap(8),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save Template'),
                ),
              ],
            ),
          ),
          const Gap(24),
          Expanded(
            child: _previewMode
                ? _buildPreview(theme)
                : _buildEditor(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left panel — fields
          SizedBox(
            width: 360,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Template name',
                    hintText: 'e.g., Welcome Email',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const Gap(16),
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email subject line',
                    hintText: 'e.g., Welcome to our community, {{first_name}}!',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const Gap(24),
                // Merge tags
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Merge Tags',
                        style: theme.textTheme.titleSmall),
                    const Gap(8),
                    Text(
                      'Click a tag to insert it at the cursor position in your HTML',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white38),
                    ),
                    const Gap(12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.mergeTags.map((tag) {
                        return ActionChip(
                          label: Text(tag,
                              style:
                                  const TextStyle(fontFamily: 'monospace')),
                          onPressed: () => _insertMergeTag(tag),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(24),
          const VerticalDivider(),
          const Gap(24),
          // Right panel — HTML editor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HTML Body',
                    style: theme.textTheme.titleSmall),
                const Gap(8),
                Expanded(
                  child: TextFormField(
                    controller: _htmlCtrl,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Write your HTML email here...',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    // Replace merge tags with sample data for preview
    var html = _htmlCtrl.text
        .replaceAll('{{first_name}}', 'John')
        .replaceAll('{{last_name}}', 'Doe')
        .replaceAll('{{full_name}}', 'John Doe')
        .replaceAll('{{email}}', 'john.doe@example.com');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.white38, size: 16),
              const Gap(8),
              Text(
                'Preview shows sample data for merge tags',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.white38),
              ),
            ],
          ),
          const Gap(16),
          // Subject preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF21253A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('Subject: ',
                    style: TextStyle(color: Colors.white38)),
                Text(
                  _subjectCtrl.text
                      .replaceAll('{{first_name}}', 'John')
                      .replaceAll('{{last_name}}', 'Doe'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Gap(16),
          // HTML preview
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SelectableText(
                  html,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    _htmlCtrl.dispose();
    super.dispose();
  }

  static const _defaultTemplate = '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: Arial, sans-serif; background: #f4f4f4; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 40px auto; background: white; border-radius: 8px; overflow: hidden; }
    .header { background: #6C63FF; padding: 40px; text-align: center; color: white; }
    .content { padding: 40px; color: #333; line-height: 1.6; }
    .button { display: inline-block; background: #6C63FF; color: white; padding: 14px 28px; border-radius: 6px; text-decoration: none; margin: 20px 0; }
    .footer { background: #f8f8f8; padding: 20px; text-align: center; color: #999; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Hello, {{first_name}}!</h1>
    </div>
    <div class="content">
      <p>We are excited to share some news with you.</p>
      <p>Your email <strong>{{email}}</strong> is confirmed.</p>
      <a href="#" class="button">Get Started</a>
    </div>
    <div class="footer">
      <p>You are receiving this because you subscribed to our list.</p>
      <p><a href="{{unsubscribe_url}}">Unsubscribe</a></p>
    </div>
  </div>
</body>
</html>''';
}
