import 'package:echo/screen/date_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';

class Event {
  final String title;
  const Event(this.title);
}

class CustomCalendar extends StatefulWidget {
  final LinkedHashMap<DateTime, List<Event>> events;

  const CustomCalendar({super.key, required this.events});

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final int currentYear = DateTime.now().year;
  final DateTime firstDay = DateTime(2020, 1, 1);
  final DateTime lastDay = DateTime(DateTime.now().year, 12, 31);

  final monthNames = [
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
    'December'
  ];

  List<Event> _getEventsForDay(DateTime day) {
    return widget.events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _updateFocusedDay(int year, int month) {
    final newFocused = DateTime(year, month, 1);

    // Clamp focused day between firstDay and lastDay
    if (newFocused.isBefore(firstDay)) {
      _focusedDay = firstDay;
    } else if (newFocused.isAfter(lastDay)) {
      _focusedDay = lastDay;
    } else {
      _focusedDay = newFocused;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔽 Month & Year Selectors
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Month:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20,),
            DropdownButton<int>(
              value: _selectedMonth,
              onChanged: (int? newMonth) {
                if (newMonth != null) {
                  setState(() {
                    _selectedMonth = newMonth;
                    _updateFocusedDay(_selectedYear, _selectedMonth);
                  });
                }
              },
              items: List.generate(12, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text(monthNames[index]),
                );
              }),
            ),
            const SizedBox(width: 30),
            const Text("Year:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20,),
            DropdownButton<int>(
              value: _selectedYear,
              onChanged: (int? newYear) {
                if (newYear != null && newYear <= currentYear) {
                  setState(() {
                    _selectedYear = newYear;
                    _updateFocusedDay(_selectedYear, _selectedMonth);
                  });
                }
              },
              items: List.generate(currentYear - 2020 + 1, (index) {
                final year = 2020 + index;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
            ),
          ],
        ),

        // 📅 Calendar
        TableCalendar<Event>(
          rowHeight: 70,
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          calendarStyle: CalendarStyle(
            isTodayHighlighted: false,
            outsideDaysVisible: false,
            defaultTextStyle: const TextStyle(color: Colors.black),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DateDetailScreen(date: selectedDay),
              ),
            );
          },
          calendarBuilders: CalendarBuilders<Event>(
            markerBuilder: (context, day, events) => const SizedBox.shrink(),
            defaultBuilder: (context, day, focusedDay) {
              final events = _getEventsForDay(day);
              final int eventCount = events.length;

              Color backgroundColor;
              if (eventCount == 0) {
                backgroundColor = Colors.white;
              } else if (eventCount == 1) {
                backgroundColor = const Color(0xFFE0D7FF);
              } else if (eventCount <= 2) {
                backgroundColor = const Color(0xFFB8A6FF);
              } else {
                backgroundColor = const Color(0xFF6E61FD);
              }

              return Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${day.day}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(_weekdayShort(day), style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _weekdayShort(DateTime day) {
    return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day.weekday % 7];
  }
}