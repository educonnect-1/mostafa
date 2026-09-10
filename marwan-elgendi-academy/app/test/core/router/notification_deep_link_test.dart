import 'package:flutter_test/flutter_test.dart';
import 'package:marwan_elgendi_academy/core/router/notification_deep_link.dart';

void main() {
  group('deepLinkPathForNotificationData', () {
    test('new_assignment routes to the specific assignment', () {
      final path = deepLinkPathForNotificationData({
        'type': 'new_assignment',
        'assignment_id': 'abc-123',
      });
      expect(path, '/assignments/abc-123');
    });

    test('assignment_graded routes to the same assignment detail screen', () {
      final path = deepLinkPathForNotificationData({
        'type': 'assignment_graded',
        'assignment_id': 'abc-123',
      });
      expect(path, '/assignments/abc-123');
    });

    test('new_exam routes to the specific exam', () {
      final path = deepLinkPathForNotificationData({
        'type': 'new_exam',
        'exam_id': 'exam-1',
      });
      expect(path, '/exams/exam-1');
    });

    test('live_room routes to the specific room', () {
      final path = deepLinkPathForNotificationData({
        'type': 'live_room',
        'room_id': 'room-9',
      });
      expect(path, '/rooms/room-9');
    });

    test('announcement routes to the announcements list', () {
      final path = deepLinkPathForNotificationData({'type': 'announcement'});
      expect(path, '/announcements');
    });

    test('missing id falls back to the list route, not a crash', () {
      final path = deepLinkPathForNotificationData({'type': 'new_exam'});
      expect(path, '/exams');
    });

    test('unknown or missing type falls back to the notification center', () {
      expect(deepLinkPathForNotificationData({}), '/notifications');
      expect(
        deepLinkPathForNotificationData({'type': 'something_new'}),
        '/notifications',
      );
    });
  });
}
