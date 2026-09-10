import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/calendar_event.dart';
import '../../../repositories/calendar_repository.dart';

final myCalendarEventsProvider =
    FutureProvider.autoDispose<List<CalendarEventItem>>((ref) {
  return ref.read(calendarRepositoryProvider).getMyEvents();
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(myCalendarEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: eventsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorRetryView(
          error: err,
          onRetry: () => ref.invalidate(myCalendarEventsProvider),
        ),
        data: (events) {
          final byDay = <DateTime, List<CalendarEventItem>>{};
          for (final e in events) {
            final key = DateTime(e.startsAt.year, e.startsAt.month, e.startsAt.day);
            byDay.putIfAbsent(key, () => []).add(e);
          }
          List<CalendarEventItem> eventsForDay(DateTime day) {
            final key = DateTime(day.year, day.month, day.day);
            return byDay[key] ?? const [];
          }

          final selectedEvents = eventsForDay(_selectedDay ?? DateTime.now());

          return Column(
            children: [
              TableCalendar<CalendarEventItem>(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: eventsForDay,
                calendarStyle: const CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: AppBrand.secondary,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppBrand.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppBrand.primary,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: Colors.white70),
                ),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) => _focusedDay = focused,
              ),
              const Divider(height: 1),
              Expanded(
                child: selectedEvents.isEmpty
                    ? const EmptyView(
                        icon: Icons.event_note_outlined,
                        title: 'No events on this day',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: selectedEvents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) => _EventTile(event: selectedEvents[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final CalendarEventItem event;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _presentation(event.type);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(event.title),
        subtitle: Text(DateFormat.jm().format(event.startsAt.toLocal())),
        onTap: () => _navigate(context, event),
      ),
    );
  }

  (IconData, Color) _presentation(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.liveClass:
        return (Icons.videocam, AppBrand.danger);
      case CalendarEventType.assignmentDeadline:
        return (Icons.assignment, AppBrand.primary);
      case CalendarEventType.examDeadline:
        return (Icons.quiz, AppBrand.secondary);
      case CalendarEventType.event:
        return (Icons.event, AppBrand.success);
    }
  }

  void _navigate(BuildContext context, CalendarEventItem event) {
    // Calendar events don't carry the underlying assignment/exam/room id
    // directly — that link can be added if/when the teacher dashboard
    // starts writing it into a future `related_id` column. For now this
    // just routes to the relevant list.
    switch (event.type) {
      case CalendarEventType.liveClass:
        context.push('/rooms');
        break;
      case CalendarEventType.assignmentDeadline:
        context.push('/assignments');
        break;
      case CalendarEventType.examDeadline:
        context.push('/exams');
        break;
      case CalendarEventType.event:
        break;
    }
  }
}
