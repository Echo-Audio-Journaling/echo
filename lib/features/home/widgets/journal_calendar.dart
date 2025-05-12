import 'package:echo/app/router.dart';
import 'package:echo/features/date_detail/provider/log_entries_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:echo/shared/models/log_entry.dart';

// New provider to get log entries grouped by date for calendar view
final calendarEntriesProvider =
    StateProvider.autoDispose<Map<DateTime, List<LogEntry>>>((ref) {
      final entriesAsyncValue = ref.watch(logEntriesProvider);

      // Default empty map
      Map<DateTime, List<LogEntry>> entriesByDate = {};

      // Only process if we have data
      if (entriesAsyncValue.hasValue && entriesAsyncValue.value != null) {
        // Group entries by date (ignoring time component)
        entriesByDate = groupLogEntriesByDate(entriesAsyncValue.value!);
      }

      return entriesByDate;
    });

// Helper function to group log entries by date
Map<DateTime, List<LogEntry>> groupLogEntriesByDate(List<LogEntry> entries) {
  final Map<DateTime, List<LogEntry>> result = {};

  for (final entry in entries) {
    // Create date without time component
    final dateOnly = DateTime(
      entry.timestamp.year,
      entry.timestamp.month,
      entry.timestamp.day,
    );

    if (!result.containsKey(dateOnly)) {
      result[dateOnly] = [];
    }

    result[dateOnly]!.add(entry);
  }

  return result;
}

class JournalCalendar extends ConsumerStatefulWidget {
  // Added parameters for min and max years
  final int? minYear;
  final int? maxYear;

  const JournalCalendar({super.key, this.minYear = 2020, this.maxYear = 2030});

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

    // Fetch all entries for the current month when the calendar initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEntriesForCurrentMonth();
    });
  }

  // Fetch entries for the current focused month
  void _fetchEntriesForCurrentMonth() {
    final year = _focusedDay.year;
    final month = _focusedDay.month;

    // Start of month
    final firstDay = DateTime(year, month, 1);

    // End of month (first day of next month minus 1 day)
    final lastDay = DateTime(year, month + 1, 0, 23, 59, 59, 999);

    // Fetch entries for date range
    ref
        .read(logEntriesProvider.notifier)
        .fetchEntriesForMonth(firstDay, lastDay);
  }

  // Get entries for a specific day from the Firestore data
  List<LogEntry> _getEntriesForDay(DateTime day) {
    final entriesByDate = ref.watch(calendarEntriesProvider);

    // Create a date with just year, month, and day components for comparison
    final dateKey = DateTime(day.year, day.month, day.day);

    return entriesByDate[dateKey] ?? [];
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
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                    const Divider(height: 24),

                    // Tabs for Month and Year
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFFF5F5F5),
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
                              tabs: const [
                                Tab(text: 'MONTH'),
                                Tab(text: 'YEAR'),
                              ],
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
                                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
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
                                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
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
                                                      ? _baseColor.withAlpha(
                                                        128,
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

                    const SizedBox(height: 24),

                    // Current Selection Preview
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? const Color(0xFF2D2D2D)
                                : const Color(0xFFF5F5F5),
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

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
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
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Update focused day in parent widget
                            this.setState(() {
                              _focusedDay = DateTime(
                                selectedYear,
                                selectedMonth,
                                1,
                              );

                              // Fetch entries for the newly selected month
                              _fetchEntriesForCurrentMonth();
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
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

    // Watch the async state of entries
    final entriesAsyncValue = ref.watch(logEntriesProvider);

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

                    // Fetch entries for the previous month
                    _fetchEntriesForCurrentMonth();
                  });
                },
              ),
              // Modified to be clickable with visual indicator
              InkWell(
                onTap: _showMonthYearPicker,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.secondary.withAlpha(77),
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

                    // Fetch entries for the next month
                    _fetchEntriesForCurrentMonth();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Show loading indicator or error if needed
        if (entriesAsyncValue.isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: _baseColor),
            ),
          )
        else if (entriesAsyncValue.hasError)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading calendar data',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          )
        else
          // Calendar
          TableCalendar<LogEntry>(
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
              setState(() {
                _focusedDay = focusedDay;

                // Fetch entries for the newly visible month
                _fetchEntriesForCurrentMonth();
              });
            },
            calendarBuilders: CalendarBuilders<LogEntry>(
              defaultBuilder: (context, day, focusedDay) {
                final entries = _getEntriesForDay(day);
                final isToday = isSameDay(day, DateTime.now());
                final isSelected = isSameDay(day, _selectedDay);

                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getDayBackgroundColor(entries.length),
                    border:
                        isToday
                            ? Border.all(
                              color: const Color(0xFF034C5F),
                              width: 3,
                            )
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color:
                            isSelected
                                ? Colors.white
                                : _getDayTextColor(entries.length),
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

    // Define base color (e.g., your purple color)
    final baseHue = HSLColor.fromColor(_baseColor).hue;
    final baseSaturation = HSLColor.fromColor(_baseColor).saturation;

    // Define distinct levels
    if (eventCount == 1) {
      // Level 1 (lightest) - High lightness
      return HSLColor.fromAHSL(1.0, baseHue, baseSaturation, 0.85).toColor();
    } else if (eventCount <= 3) {
      // Level 2
      return HSLColor.fromAHSL(1.0, baseHue, baseSaturation, 0.75).toColor();
    } else if (eventCount <= 5) {
      // Level 3
      return HSLColor.fromAHSL(1.0, baseHue, baseSaturation, 0.65).toColor();
    } else if (eventCount <= 8) {
      // Level 4
      return HSLColor.fromAHSL(1.0, baseHue, baseSaturation, 0.55).toColor();
    } else {
      // Level 5 (darkest)
      return HSLColor.fromAHSL(1.0, baseHue, baseSaturation, 0.45).toColor();
    }
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
