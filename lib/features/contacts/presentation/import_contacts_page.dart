import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/excel_service.dart';
import '../../../data/services/firebase_service.dart';
import '../../../shared/widgets/page_header.dart';

enum _ImportStep { upload, mapColumns, preview, importing, done }

class ImportContactsPage extends ConsumerStatefulWidget {
  final String listId;

  const ImportContactsPage({super.key, required this.listId});

  @override
  ConsumerState<ImportContactsPage> createState() =>
      _ImportContactsPageState();
}

class _ImportContactsPageState extends ConsumerState<ImportContactsPage> {
  _ImportStep _step = _ImportStep.upload;
  Uint8List? _fileBytes;
  String? _fileName;
  ExcelPreview? _preview;
  int _importedCount = 0;
  String? _error;

  Future<void> _pickFile() async {
    setState(() => _error = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _fileBytes = file.bytes;
      _fileName = file.name;
    });

    final preview = ExcelService.parsePreview(file.bytes!);
    if (preview == null) {
      setState(() => _error = 'Could not read file. Make sure it is a valid Excel or CSV file.');
      return;
    }

    setState(() {
      _preview = preview;
      _step = _ImportStep.mapColumns;
    });
  }

  Future<void> _runImport() async {
    if (_fileBytes == null || _preview == null) return;
    setState(() => _step = _ImportStep.importing);

    try {
      final contacts =
          ExcelService.extractContacts(_fileBytes!, _preview!.columns);
      await FirebaseService.importContacts(widget.listId, contacts);
      setState(() {
        _importedCount = contacts.length;
        _step = _ImportStep.done;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _step = _ImportStep.mapColumns;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Import Contacts',
          subtitle: _fileName ?? 'Upload an Excel or CSV file',
          actions: [
            TextButton(
              onPressed: () => context.go('/contacts'),
              child: const Text('Cancel'),
            ),
          ],
        ),
        // Step indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _StepIndicator(current: _step),
        ),
        const Gap(32),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildBody(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_step) {
      case _ImportStep.upload:
        return _UploadStep(onPickFile: _pickFile, error: _error);
      case _ImportStep.mapColumns:
        return _MapColumnsStep(
          preview: _preview!,
          error: _error,
          onContinue: () => setState(() => _step = _ImportStep.preview),
        );
      case _ImportStep.preview:
        return _PreviewStep(
          preview: _preview!,
          onBack: () => setState(() => _step = _ImportStep.mapColumns),
          onImport: _runImport,
        );
      case _ImportStep.importing:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              Gap(16),
              Text('Importing contacts...'),
            ],
          ),
        );
      case _ImportStep.done:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50), size: 72),
              const Gap(16),
              Text('Import Complete!',
                  style: theme.textTheme.headlineSmall),
              const Gap(8),
              Text('$_importedCount contacts imported successfully',
                  style: theme.textTheme.bodyMedium),
              const Gap(32),
              ElevatedButton(
                onPressed: () => context.go('/contacts'),
                child: const Text('Back to Contacts'),
              ),
            ],
          ),
        );
    }
  }
}

class _UploadStep extends StatelessWidget {
  final VoidCallback onPickFile;
  final String? error;

  const _UploadStep({required this.onPickFile, this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onPickFile,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 400,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_rounded,
                      color: theme.colorScheme.primary, size: 64),
                  const Gap(16),
                  Text('Drop your file here or click to browse',
                      style: theme.textTheme.titleMedium),
                  const Gap(8),
                  Text('Supports .xlsx, .xls, .csv',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ),
          if (error != null) ...[
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(error!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapColumnsStep extends StatelessWidget {
  final ExcelPreview preview;
  final VoidCallback onContinue;
  final String? error;

  const _MapColumnsStep({
    required this.preview,
    required this.onContinue,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mappingOptions = ['email', 'firstName', 'lastName', '(skip)'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Map your columns', style: theme.textTheme.headlineSmall),
        const Gap(8),
        Text(
          'Tell us what each column contains. At minimum, you need an "email" column.',
          style: theme.textTheme.bodyMedium,
        ),
        const Gap(24),
        ...preview.columns.map((col) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Text(col.name,
                      style: theme.textTheme.titleMedium),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white38),
                const Gap(16),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    initialValue: col.mappedTo ?? '(skip)',
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8)),
                    items: mappingOptions
                        .map((o) => DropdownMenuItem(
                            value: o,
                            child: Text(o == '(skip)'
                                ? '— skip —'
                                : o)))
                        .toList(),
                    onChanged: (v) {
                      col.mappedTo = v == '(skip)' ? null : v;
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        const Gap(32),
        ElevatedButton(
          onPressed: onContinue,
          child: const Text('Continue to Preview'),
        ),
      ],
    );
  }
}

class _PreviewStep extends StatelessWidget {
  final ExcelPreview preview;
  final VoidCallback onBack;
  final VoidCallback onImport;

  const _PreviewStep({
    required this.preview,
    required this.onBack,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mappedCols = preview.columns.where((c) => c.mappedTo != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preview', style: theme.textTheme.headlineSmall),
        const Gap(8),
        Text(
          '${preview.totalRows} contacts found. Showing first ${preview.previewRows.length} rows.',
          style: theme.textTheme.bodyMedium,
        ),
        const Gap(24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
                theme.colorScheme.primary.withValues(alpha: 0.1)),
            columns: mappedCols
                .map((c) => DataColumn(
                    label: Text(c.mappedTo!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold))))
                .toList(),
            rows: preview.previewRows.map((row) {
              return DataRow(
                cells: mappedCols.map((col) {
                  final val = col.index < row.length ? row[col.index] : '';
                  return DataCell(Text(val));
                }).toList(),
              );
            }).toList(),
          ),
        ),
        const Gap(32),
        Row(
          children: [
            OutlinedButton(
              onPressed: onBack,
              child: const Text('Back'),
            ),
            const Gap(16),
            ElevatedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_rounded, size: 18),
              label: Text('Import ${preview.totalRows} Contacts'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final _ImportStep current;

  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = ['Upload File', 'Map Columns', 'Preview', 'Import'];
    final stepIndex = current.index;
    final theme = Theme.of(context);

    return Row(
      children: List.generate(steps.length, (i) {
        final isDone = i < stepIndex;
        final isActive = i == stepIndex;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
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
                            color: isActive ? Colors.white : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[i],
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : Colors.white38,
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (i < steps.length - 1)
                      const Divider(thickness: 1),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
