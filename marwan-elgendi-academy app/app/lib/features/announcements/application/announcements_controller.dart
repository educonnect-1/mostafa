import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/announcement.dart';
import '../../../repositories/announcement_repository.dart';

final myAnnouncementsProvider = FutureProvider.autoDispose<List<Announcement>>((ref) {
  return ref.read(announcementRepositoryProvider).getMyAnnouncements();
});
