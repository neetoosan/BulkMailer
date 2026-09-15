import 'package:cloud_firestore/cloud_firestore.dart';

enum ContactStatus { active, unsubscribed, bounced }

class ContactModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final Map<String, dynamic> customFields;
  final ContactStatus status;
  final DateTime createdAt;

  const ContactModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.customFields = const {},
    this.status = ContactStatus.active,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ContactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContactModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      customFields: Map<String, dynamic>.from(data['customFields'] as Map? ?? {}),
      status: ContactStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'active'),
        orElse: () => ContactStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'customFields': customFields,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ContactModel copyWith({
    String? email,
    String? firstName,
    String? lastName,
    Map<String, dynamic>? customFields,
    ContactStatus? status,
  }) {
    return ContactModel(
      id: id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      customFields: customFields ?? this.customFields,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
