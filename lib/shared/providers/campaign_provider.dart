import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/campaign_model.dart';
import '../../data/services/firebase_service.dart';

final campaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  return FirebaseService.watchCampaigns();
});

final selectedCampaignProvider = StateProvider<CampaignModel?>((ref) => null);
