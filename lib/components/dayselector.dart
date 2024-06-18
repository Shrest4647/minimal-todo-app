import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DaySelector extends StatefulWidget {
  final DateTime defaultActiveDay;
  final Function(DateTime) onActiveDayChanged;

  const DaySelector({
    super.key,
    required this.defaultActiveDay,
    required this.onActiveDayChanged,
  });

  @override
  State<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<DaySelector> {
  DateTime _activeDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _activeDay = widget.defaultActiveDay;
  }

  void _selectDay(DateTime day) {
    setState(() {
      _activeDay = day;
      widget.onActiveDayChanged(_activeDay);
    });
  }

  void _previousWeek() {
    setState(() {
      _activeDay = _activeDay.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _activeDay = _activeDay.add(const Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> daysOfWeek = List.generate(
      5,
      (index) => _activeDay.add(Duration(days: index - 2)),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat(DateFormat.ABBR_MONTH_WEEKDAY_DAY).format(_activeDay),
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousWeek,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 14,
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: daysOfWeek.map((day) {
                      final isActive = day == _activeDay;
                      return GestureDetector(
                        onTap: () {
                          _selectDay(day);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: isActive ? 50 : 40,
                          height: 70,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isActive
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  day.day.toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isActive ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('E').format(day)[0],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isActive ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                IconButton(
                  onPressed: _nextWeek,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
