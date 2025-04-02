import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomCalendar extends StatefulWidget {
  final void Function(String selectedDay) onDateSelected;
  final List<DateTime> highlightedDates;

  const CustomCalendar({
    Key? key,
    required this.onDateSelected,
    required this.highlightedDates,
  }) : super(key: key);

  @override
  _CustomCalendarState createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime _focusedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _lastDay = DateTime.now();
    _firstDay = _lastDay.subtract(const Duration(days: 30));
    _focusedDay = _lastDay;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  bool _isHighlighted(DateTime day) {
    return widget.highlightedDates.any((highlighted) =>
        highlighted.year == day.year &&
        highlighted.month == day.month &&
        highlighted.day == day.day);
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: _firstDay,
      lastDay: _lastDay,
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        widget.onDateSelected(_formatDate(_selectedDay!));
      },
      calendarFormat: CalendarFormat.month,
      headerStyle: const HeaderStyle(formatButtonVisible: false),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          if (_isHighlighted(day)) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
