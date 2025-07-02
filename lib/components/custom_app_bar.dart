import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DateTime activeDate;
  final bool showTimeline;
  final VoidCallback onToggleTimeline;
  final VoidCallback onToday;
  final EasyInfiniteDateTimelineController controller;

  const CustomAppBar({
    super.key,
    required this.activeDate,
    required this.showTimeline,
    required this.onToggleTimeline,
    required this.onToday,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Tasklite',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onToday,
                child: const Text(
                  "Today",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onToggleTimeline,
                icon: showTimeline
                    ? const Icon(Icons.arrow_drop_up)
                    : const Icon(Icons.arrow_drop_down),
                label: Text(
                  DateFormat(DateFormat.ABBR_MONTH_WEEKDAY_DAY)
                      .format(activeDate),
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 2);
}
