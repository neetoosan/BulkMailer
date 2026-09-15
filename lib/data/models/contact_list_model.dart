import 'package:cloud_firestore/cloud_firestore.dart';

class ContactListModel {
  final String id;
  final String name;
  final int count;
  final DateTime createdAt;

  const ContactListModel({
    required this.id,
    required this.name,
    required this.count,
    required this.createdAt,
  });

  factory ContactListModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContactListModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      count: data['count'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'count': count,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
