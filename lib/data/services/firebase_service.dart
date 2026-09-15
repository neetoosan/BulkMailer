import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact_model.dart';
import '../models/contact_list_model.dart';
import '../models/campaign_model.dart';
import '../models/template_model.dart';
import '../../core/constants/app_constants.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  // -- Contact Lists --------------------------------------------------

  static Stream<List<ContactListModel>> watchLists() {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.listsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ContactListModel.fromFirestore).toList());
  }

  static Future<String> createList(String name) async {
    final ref = await _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.listsCollection)
        .add({'name': name, 'count': 0, 'createdAt': FieldValue.serverTimestamp()});
    return ref.id;
  }

  static Future<void> deleteList(String listId) async {
    final ref = _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.listsCollection)
        .doc(listId);
    // Delete all subscribers first
    final subs = await ref.collection(AppConstants.subscribersCollection).get();
    final batch = _db.batch();
    for (final doc in subs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(ref);
    await batch.commit();
  }

  // -- Contacts -------------------------------------------------------

  static Stream<List<ContactModel>> watchContacts(String listId) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.listsCollection)
        .doc(listId)
        .collection(AppConstants.subscribersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ContactModel.fromFirestore).toList());
  }

  static Future<void> importContacts(
    String listId,
    List<ContactModel> contacts,
  ) async {
    const batchSize = 500;
    final listRef = _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.listsCollection)
        .doc(listId);

    for (var i = 0; i < contacts.length; i += batchSize) {
      final chunk = contacts.sublist(
        i,
        i + batchSize > contacts.length ? contacts.length : i + batchSize,
      );
      final batch = _db.batch();
      for (final contact in chunk) {
        final ref = listRef.collection(AppConstants.subscribersCollection).doc();
        batch.set(ref, contact.toFirestore());
      }
      await batch.commit();
    }

    // Update count
    await listRef.update({'count': FieldValue.increment(contacts.length)});
  }

  static Future<void> unsubscribeContact(String listId, String contactId) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.listsCollection)
        .doc(listId)
        .collection(AppConstants.subscribersCollection)
        .doc(contactId)
        .update({'status': 'unsubscribed'});
  }

  // -- Templates ------------------------------------------------------

  static Stream<List<TemplateModel>> watchTemplates() {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.templatesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TemplateModel.fromFirestore).toList());
  }

  static Future<String> saveTemplate(TemplateModel template) async {
    if (template.id.isEmpty) {
      final ref = await _db
          .collection(AppConstants.usersCollection)
          .doc(_uid)
          .collection(AppConstants.templatesCollection)
          .add(template.toFirestore());
      return ref.id;
    } else {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(_uid)
          .collection(AppConstants.templatesCollection)
          .doc(template.id)
          .update(template.toFirestore());
      return template.id;
    }
  }

  static Future<void> deleteTemplate(String templateId) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.templatesCollection)
        .doc(templateId)
        .delete();
  }

  static Future<TemplateModel?> getTemplate(String templateId) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.templatesCollection)
        .doc(templateId)
        .get();
    if (!doc.exists) return null;
    return TemplateModel.fromFirestore(doc);
  }

  // -- Campaigns ------------------------------------------------------

  static Stream<List<CampaignModel>> watchCampaigns() {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.campaignsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(CampaignModel.fromFirestore).toList());
  }

  static Future<String> createCampaign(CampaignModel campaign) async {
    final ref = await _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.campaignsCollection)
        .add(campaign.toFirestore());
    return ref.id;
  }

  static Future<void> updateCampaignStatus(
    String campaignId,
    CampaignStatus status,
  ) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.campaignsCollection)
        .doc(campaignId)
        .update({
      'status': status.name,
      if (status == CampaignStatus.sending)
        'sentAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteCampaign(String campaignId) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.campaignsCollection)
        .doc(campaignId)
        .delete();
  }

  // -- User Profile ---------------------------------------------------

  static Future<void> saveUserProfile(Map<String, dynamic> data) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .get();
    return doc.data();
  }
}

