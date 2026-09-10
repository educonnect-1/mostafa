import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/room.dart';
import '../../../repositories/room_repository.dart';

final myRoomsStreamProvider = StreamProvider.autoDispose<List<Room>>((ref) {
  return ref.read(roomRepositoryProvider).watchMyRooms();
});

final roomByIdProvider = FutureProvider.autoDispose.family<Room, String>((ref, id) {
  return ref.read(roomRepositoryProvider).getRoomById(id);
});
