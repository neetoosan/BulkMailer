import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/contact_list_model.dart';
import '../../data/models/contact_model.dart';
import '../../data/services/firebase_service.dart';

final contactListsProvider = StreamProvider<List<ContactListModel>>((ref) {
  return FirebaseService.watchLists();
});

final contactsProvider =
    StreamProvider.family<List<ContactModel>, String>((ref, listId) {
  return FirebaseService.watchContacts(listId);
});

final selectedListIdProvider = StateProvider<String?>((ref) => null);
