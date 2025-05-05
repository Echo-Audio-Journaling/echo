import 'dart:collection';
import 'package:echo/app/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

class Event {
  final String title;
  const Event(this.title);
}

class JournalCalendar extends ConsumerStatefulWidget {
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

  // Added parameters for min and max years
  final int? minYear;
  final int? maxYear;

  JournalCalendar({super.key, this.minYear = 2020, this.maxYear = 2030});

  @override
  ConsumerState<JournalCalendar> createState() => _JournalCalendarState();
}

class _JournalCalendarState extends ConsumerState<JournalCalendar> {
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

  // Show month and year picker dialog
  void _showMonthYearPicker() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Initialize with current values
    int selectedMonth = _focusedDay.month;
    int selectedYear = _focusedDay.year;

    // Get min and max years
    final int minYear = widget.minYear ?? 2020;
    final int maxYear = widget.maxYear ?? 2030;

    // Create list of years
    final List<int> years = List.generate(
      maxYear - minYear + 1,
      (index) => minYear + index,
    );

    // Month names
    final List<String> monthNames = [
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
    ];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select Date',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _baseColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Divider(height: 24),

                    // Tabs for Month and Year
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TabBar(
                              indicatorColor: _baseColor,
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: _baseColor,
                              unselectedLabelColor:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              tabs: [Tab(text: 'MONTH'), Tab(text: 'YEAR')],
                            ),
                            SizedBox(
                              height: 220,
                              child: TabBarView(
                                children: [
                                  // Month Tab
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            childAspectRatio: 2.0,
                                            crossAxisSpacing: 4,
                                            mainAxisSpacing: 4,
                                          ),
                                      itemCount: 12,
                                      itemBuilder: (context, index) {
                                        final int month = index + 1;
                                        final bool isSelected =
                                            month == selectedMonth;

                                        return AnimatedContainer(
                                          margin: EdgeInsets.zero,
                                          duration: Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? _baseColor
                                                    : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? _baseColor
                                                      : isDarkMode
                                                      ? Colors.white30
                                                      : Colors.black12,
                                              width: 1,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () {
                                                setState(() {
                                                  selectedMonth = month;
                                                });
                                              },
                                              child: Center(
                                                child: Text(
                                                  monthNames[index].substring(
                                                    0,
                                                    3,
                                                  ),
                                                  style: TextStyle(
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : theme
                                                                .colorScheme
                                                                .onSurface,
                                                    fontWeight:
                                                        isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Year Tab
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            childAspectRatio: 1.5,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                          ),
                                      itemCount: years.length,
                                      itemBuilder: (context, index) {
                                        final int year = years[index];
                                        final bool isSelected =
                                            year == selectedYear;
                                        final bool isCurrent =
                                            year == DateTime.now().year;

                                        return AnimatedContainer(
                                          margin: EdgeInsets.zero,
                                          duration: Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? _baseColor
                                                    : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? _baseColor
                                                      : isCurrent
                                                      ? _baseColor.withOpacity(
                                                        0.5,
                                                      )
                                                      : isDarkMode
                                                      ? Colors.white30
                                                      : Colors.black12,
                                              width: isCurrent ? 2 : 1,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () {
                                                setState(() {
                                                  selectedYear = year;
                                                });
                                              },
                                              child: Center(
                                                child: Text(
                                                  year.toString(),
                                                  style: TextStyle(
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : isCurrent
                                                            ? _baseColor
                                                            : theme
                                                                .colorScheme
                                                                .onSurface,
                                                    fontWeight:
                                                        isSelected || isCurrent
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Current Selection Preview
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Selected: ',
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          Text(
                            '${monthNames[selectedMonth - 1]} $selectedYear',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _baseColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Update focused day in parent widget
                            this.setState(() {
                              _focusedDay = DateTime(
                                selectedYear,
                                selectedMonth,
                                1,
                              );
                            });
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _baseColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'APPLY',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Here you can access Riverpod providers using ref if needed
    // Example: final someState = ref.watch(someProvider);

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
              // Modified to be clickable with visual indicator
              InkWell(
                onTap: _showMonthYearPicker,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
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
          firstDay: DateTime.utc(widget.minYear ?? 2020, 1, 1),
          lastDay: DateTime.utc(widget.maxYear ?? 2030, 12, 31),
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
            // Navigate to date detail page with the selected date parameters
            final year = selectedDay.year;
            final month = selectedDay.month;
            final day = selectedDay.day;

            // Use the router to navigate to the date detail page
            ref.read(routerProvider).go('/date/$year/$month/$day');
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
            setState(() {});
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
