import 'dart:collection';

import 'package:echo/shared/widgets/calendar.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class JournalCalendar extends StatefulWidget {
  final LinkedHashMap<DateTime, List<Event>> events = LinkedHashMap(
    equals: isSameDay,
    hashCode:
        (DateTime key) => key.day * 1000000 + key.month * 10000 + key.year,
  )..addAll({
    // Current week
    DateTime.now().subtract(const Duration(days: 3)): [
      Event("Morning meditation"),
      Event("Team meeting notes"),
    ],
    DateTime.now().subtract(const Duration(days: 2)): [Event("Gym workout")],
    DateTime.now().subtract(const Duration(days: 1)): [
      Event("Dinner with Alex"),
      Event("Book reading"),
      Event("Project ideas"),
    ],
    DateTime.now(): [
      Event("Today's reflection"),
      Event("Doctor appointment"),
      Event("Call mom"),
      Event("Gratitude journal"),
    ],
    DateTime.now().add(const Duration(days: 1)): [
      Event("Weekend plans"),
      Event("Shopping list"),
    ],

    // Previous month highlights
    DateTime(DateTime.now().year, DateTime.now().month - 1, 15): [
      Event("Vacation day!"),
      Event("Beach photos"),
    ],
    DateTime(DateTime.now().year, DateTime.now().month - 1, 20): [
      Event("Job interview"),
      Event("Follow-up email"),
      Event("Research notes"),
    ],

    // Next month
    DateTime(DateTime.now().year, DateTime.now().month + 1, 5): [
      Event("Birthday reminder"),
    ],

    // Random scattered entries
    DateTime(DateTime.now().year, DateTime.now().month, 7): [
      Event("Ideas for blog post"),
      Event("Movie night"),
    ],
    DateTime(DateTime.now().year, DateTime.now().month, 12): [
      Event("Conference notes"),
      Event("Networking contacts"),
      Event("Key takeaways"),
      Event("Action items"),
    ],
    DateTime(DateTime.now().year, DateTime.now().month, 25): [
      Event("Monthly review"),
      Event("Goals check-in"),
    ],
  });

  JournalCalendar({super.key});

  @override
  State<JournalCalendar> createState() => _JournalCalendarState();
}

class _JournalCalendarState extends State<JournalCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final Color _baseColor = const Color(0xFF6E61FD);

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  List<Event> _getEventsForDay(DateTime day) {
    return widget.events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            'Calendar',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: _baseColor,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Month Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: theme.colorScheme.secondary,
                ),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month - 1,
                    );
                  });
                },
              ),
              Text(
                '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.secondary,
                ),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Calendar
        TableCalendar<Event>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerVisible: false,
          daysOfWeekHeight: 36,
          rowHeight: 48,
          calendarStyle: CalendarStyle(
            isTodayHighlighted: false,
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            weekendTextStyle: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            cellMargin: const EdgeInsets.all(4),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarBuilders: CalendarBuilders<Event>(
            defaultBuilder: (context, day, focusedDay) {
              final events = _getEventsForDay(day);
              final isToday = isSameDay(day, DateTime.now());
              final isSelected = isSameDay(day, _selectedDay);

              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getDayBackgroundColor(events.length),
                  border:
                      isToday
                          ? Border.all(color: const Color(0xFF034C5F), width: 3)
                          : null,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : _getDayTextColor(events.length),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _baseColor,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getDayBackgroundColor(int eventCount) {
    if (eventCount == 0) return Colors.transparent;
    final opacity = (eventCount * 0.2).clamp(0.1, 0.8);
    return _baseColor.withOpacity(opacity);
  }

  Color _getDayTextColor(int eventCount) {
    if (eventCount == 0) return Theme.of(context).colorScheme.onSurface;
    return Colors.white;
  }

  String _getMonthName(int month) {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month - 1];
  }
}
