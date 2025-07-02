import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddTodoDialog extends StatefulWidget {
  final Function(String, DateTime?, bool?) onAdd;

  const AddTodoDialog({super.key, required this.onAdd});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final TextEditingController taskController = TextEditingController();
  DateTime? deadline;
  bool? reminder = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Todo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: taskController,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Enter task',
            ),
          ),
          const SizedBox(height: 10),
          Visibility(
            visible: reminder!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deadline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    final BuildContext ctx = context;
                    final selectedDate = await showDatePicker(
                      context: ctx,
                      initialDate: deadline ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(minutes: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selectedDate != null) {
                      if (!mounted || !ctx.mounted) return;
                      final selectedTime = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(
                          deadline ?? DateTime.now(),
                        ),
                      );
                      if (selectedTime != null) {
                        if (!mounted || !ctx.mounted) return;
                        setState(() {
                          deadline = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Text(
                    deadline == null
                        ? 'Select Date'
                        : DateFormat(
                            '${DateFormat.ABBR_MONTH_DAY}, ${DateFormat.ABBR_WEEKDAY} ${DateFormat.HOUR24}:${DateFormat.MINUTE}',
                          ).format(deadline!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reminder'),
              Switch(
                value: reminder!,
                activeColor: Colors.green,
                onChanged: (bool? value) {
                  setState(() {
                    reminder = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            taskController.clear();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (taskController.text.isEmpty) {
              return;
            }
            widget.onAdd(
              taskController.text,
              reminder == true ? deadline : null,
              reminder,
            );
            taskController.clear();
            deadline = null;
            if (!mounted) return;
            Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
