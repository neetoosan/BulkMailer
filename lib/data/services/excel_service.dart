import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/contact_model.dart';

class ExcelColumn {
  final int index;
  final String name;
  String? mappedTo; // 'email', 'firstName', 'lastName', or custom

  ExcelColumn({required this.index, required this.name, this.mappedTo});
}

class ExcelPreview {
  final List<ExcelColumn> columns;
  final List<List<String>> previewRows;
  final int totalRows;

  const ExcelPreview({
    required this.columns,
    required this.previewRows,
    required this.totalRows,
  });
}

class ExcelService {
  static ExcelPreview? parsePreview(Uint8List bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      final rows = sheet.rows;
      if (rows.isEmpty) return null;

      // First row = headers
      final headers = rows.first
          .map((cell) => cell?.value?.toString() ?? '')
          .toList();

      final columns = <ExcelColumn>[];
      for (var i = 0; i < headers.length; i++) {
        final name = headers[i];
        if (name.isEmpty) continue;
        // Auto-detect common column names
        String? mappedTo;
        final lower = name.toLowerCase();
        if (lower.contains('email')) {
          mappedTo = 'email';
        } else if (lower.contains('first') || lower == 'name') {
          mappedTo = 'firstName';
        } else if (lower.contains('last') || lower.contains('surname')) {
          mappedTo = 'lastName';
        }
        columns.add(ExcelColumn(index: i, name: name, mappedTo: mappedTo));
      }

      // Preview first 5 data rows
      final dataRows = rows.skip(1).take(5).toList();
      final previewRows = dataRows
          .map((row) => row
              .map((cell) => cell?.value?.toString() ?? '')
              .toList())
          .toList();

      return ExcelPreview(
        columns: columns,
        previewRows: previewRows,
        totalRows: rows.length - 1,
      );
    } catch (e) {
      return null;
    }
  }

  static List<ContactModel> extractContacts(
    Uint8List bytes,
    List<ExcelColumn> columnMapping,
  ) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    final rows = sheet.rows.skip(1); // skip header

    final emailCol = columnMapping.firstWhere(
      (c) => c.mappedTo == 'email',
      orElse: () => ExcelColumn(index: -1, name: ''),
    );
    final firstNameCol = columnMapping.firstWhere(
      (c) => c.mappedTo == 'firstName',
      orElse: () => ExcelColumn(index: -1, name: ''),
    );
    final lastNameCol = columnMapping.firstWhere(
      (c) => c.mappedTo == 'lastName',
      orElse: () => ExcelColumn(index: -1, name: ''),
    );

    final contacts = <ContactModel>[];

    for (final row in rows) {
      String email = '';
      if (emailCol.index >= 0 && emailCol.index < row.length) {
        email = row[emailCol.index]?.value?.toString() ?? '';
      }

      if (email.isEmpty || !email.contains('@')) continue;

      String firstName = '';
      if (firstNameCol.index >= 0 && firstNameCol.index < row.length) {
        firstName = row[firstNameCol.index]?.value?.toString() ?? '';
      }

      String lastName = '';
      if (lastNameCol.index >= 0 && lastNameCol.index < row.length) {
        lastName = row[lastNameCol.index]?.value?.toString() ?? '';
      }

      // Collect custom fields
      final customFields = <String, dynamic>{};
      for (final col in columnMapping) {
        if (col.mappedTo == null && col.index < row.length) {
          final value = row[col.index]?.value?.toString() ?? '';
          if (value.isNotEmpty) {
            customFields[col.name] = value;
          }
        }
      }

      contacts.add(ContactModel(
        id: '',
        email: email.trim().toLowerCase(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        customFields: customFields,
        createdAt: DateTime.now(),
      ));
    }

    return contacts;
  }
}
