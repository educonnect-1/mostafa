import 'package:equatable/equatable.dart';

enum RoomStatus { scheduled, live, ended, cancelled }

RoomStatus _statusFromString(String? value) {
  switch (value) {
    case 'live':
      return RoomStatus.live;
    case 'ended':
      return RoomStatus.ended;
    case 'cancelled':
      return RoomStatus.cancelled;
    default:
      return RoomStatus.scheduled;
  }
}

class Room extends Equatable {
  const Room({
    required this.id,
    required this.title,
    required this.jitsiRoomUrl,
    required this.hostDisplayName,
    required this.status,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String title;
  final String jitsiRoomUrl;
  final String hostDisplayName;
  final RoomStatus status;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get isLive => status == RoomStatus.live;

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      title: json['title'] as String,
      jitsiRoomUrl: json['jitsi_room_url'] as String,
      hostDisplayName: (json['host_display_name'] as String?) ?? 'Mr. Marwan Elgendi',
      status: _statusFromString(json['status'] as String?),
      startsAt: json['starts_at'] == null ? null : DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] == null ? null : DateTime.parse(json['ends_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [id, title, jitsiRoomUrl, hostDisplayName, status, startsAt, endsAt];
}
