import 'package:cloud_firestore/cloud_firestore.dart';

class TemplateModel {
  final String id;
  final String name;
  final String subject;
  final String htmlBody;
  final String plainText;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const TemplateModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.htmlBody,
    required this.plainText,
    required this.createdAt,
    this.updatedAt,
  });

  factory TemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TemplateModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      htmlBody: data['htmlBody'] as String? ?? '',
      plainText: data['plainText'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'subject': subject,
      'htmlBody': htmlBody,
      'plainText': plainText,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  TemplateModel copyWith({
    String? name,
    String? subject,
    String? htmlBody,
    String? plainText,
  }) {
    return TemplateModel(
      id: id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      htmlBody: htmlBody ?? this.htmlBody,
      plainText: plainText ?? this.plainText,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
