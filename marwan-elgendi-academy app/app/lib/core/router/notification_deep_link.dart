/// Maps the `data` payload of a push notification (or an in-app
/// notification-center tap) to the route it should deep-link to.
///
/// Payload shape sent by the backend (Edge Function) is expected to be:
///   {"type": "new_assignment", "assignment_id": "..."}
///   {"type": "new_exam", "exam_id": "..."}
///   {"type": "live_room", "room_id": "..."}
///   {"type": "assignment_graded", "assignment_id": "..."}
///   {"type": "exam_graded", "exam_id": "..."}
///   {"type": "announcement"}
String deepLinkPathForNotificationData(Map<String, dynamic> data) {
  final type = data['type'] as String?;
  switch (type) {
    case 'live_room':
      final id = data['room_id'] as String?;
      return id != null ? '/rooms/$id' : '/rooms';
    case 'new_assignment':
    case 'assignment_graded':
      final id = data['assignment_id'] as String?;
      return id != null ? '/assignments/$id' : '/assignments';
    case 'new_exam':
    case 'exam_graded':
      final id = data['exam_id'] as String?;
      return id != null ? '/exams/$id' : '/exams';
    case 'announcement':
      return '/announcements';
    default:
      return '/notifications';
  }
}
