import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/template_model.dart';
import '../../data/services/firebase_service.dart';

final templatesProvider = StreamProvider<List<TemplateModel>>((ref) {
  return FirebaseService.watchTemplates();
});

final selectedTemplateProvider = StateProvider<TemplateModel?>((ref) => null);
