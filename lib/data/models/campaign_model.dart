import 'package:cloud_firestore/cloud_firestore.dart';

enum CampaignStatus { draft, scheduled, sending, sent, failed, paused }

class CampaignStats {
  final int total;
  final int sent;
  final int failed;
  final int opened;

  const CampaignStats({
    this.total = 0,
    this.sent = 0,
    this.failed = 0,
    this.opened = 0,
  });

  double get deliveryRate => total == 0 ? 0 : (sent / total) * 100;
  double get openRate => sent == 0 ? 0 : (opened / sent) * 100;

  factory CampaignStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CampaignStats();
    return CampaignStats(
      total: map['total'] as int? ?? 0,
      sent: map['sent'] as int? ?? 0,
      failed: map['failed'] as int? ?? 0,
      opened: map['opened'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'total': total,
    'sent': sent,
    'failed': failed,
    'opened': opened,
  };
}

class CampaignModel {
  final String id;
  final String name;
  final String subject;
  final String templateId;
  final String listId;
  final String listName;
  final CampaignStatus status;
  final CampaignStats stats;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final String? fromName;
  final String? replyTo;

  const CampaignModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.templateId,
    required this.listId,
    required this.listName,
    required this.status,
    required this.stats,
    required this.createdAt,
    this.scheduledAt,
    this.sentAt,
    this.fromName,
    this.replyTo,
  });

  factory CampaignModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CampaignModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      templateId: data['templateId'] as String? ?? '',
      listId: data['listId'] as String? ?? '',
      listName: data['listName'] as String? ?? '',
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'draft'),
        orElse: () => CampaignStatus.draft,
      ),
      stats: CampaignStats.fromMap(data['stats'] as Map<String, dynamic>?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      fromName: data['fromName'] as String?,
      replyTo: data['replyTo'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'subject': subject,
      'templateId': templateId,
      'listId': listId,
      'listName': listName,
      'status': status.name,
      'stats': stats.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt!),
      if (sentAt != null) 'sentAt': Timestamp.fromDate(sentAt!),
      if (fromName != null) 'fromName': fromName,
      if (replyTo != null) 'replyTo': replyTo,
    };
  }

  CampaignModel copyWith({
    String? name,
    String? subject,
    String? templateId,
    String? listId,
    String? listName,
    CampaignStatus? status,
    CampaignStats? stats,
    DateTime? scheduledAt,
    DateTime? sentAt,
    String? fromName,
    String? replyTo,
  }) {
    return CampaignModel(
      id: id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      templateId: templateId ?? this.templateId,
      listId: listId ?? this.listId,
      listName: listName ?? this.listName,
      status: status ?? this.status,
      stats: stats ?? this.stats,
      createdAt: createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      fromName: fromName ?? this.fromName,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
