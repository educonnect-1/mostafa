import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/attendance_record.dart';
import '../../../repositories/attendance_repository.dart';

final myAttendanceProvider = FutureProvider.autoDispose<List<AttendanceRecord>>((ref) {
  return ref.read(attendanceRepositoryProvider).getMyAttendance();
});

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(myAttendanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myAttendanceProvider.future),
        child: attendanceAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorRetryView(
            error: err,
            onRetry: () => ref.invalidate(myAttendanceProvider),
          ),
          data: (records) {
            if (records.isEmpty) {
              return const EmptyView(
                icon: Icons.event_available_outlined,
                title: 'No attendance records yet',
              );
            }

            final byMonth = <String, List<AttendanceRecord>>{};
            for (final r in records) {
              final key = DateFormat.yMMMM().format(r.sessionDate);
              byMonth.putIfAbsent(key, () => []).add(r);
            }
            final months = byMonth.keys.toList()
              ..sort((a, b) => DateFormat.yMMMM()
                  .parse(b)
                  .compareTo(DateFormat.yMMMM().parse(a)));

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final month in months) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text(month, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  ...byMonth[month]!.map((r) => _AttendanceTile(record: r)),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.record});
  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _presentation(record.status);
    return Card(
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: color),
        title: Text(DateFormat.MMMd().format(record.sessionDate)),
        subtitle: Text(record.groupName),
        trailing: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }

  (String, Color, IconData) _presentation(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return ('Present', AppBrand.success, Icons.check_circle_outline);
      case AttendanceStatus.late:
        return ('Late', AppBrand.warning, Icons.schedule);
      case AttendanceStatus.absent:
        return ('Absent', AppBrand.danger, Icons.cancel_outlined);
      case AttendanceStatus.excused:
        return ('Excused', AppBrand.primary, Icons.info_outline);
    }
  }
}
