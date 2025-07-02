import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

class TodoListItem extends StatelessWidget {
  final Todo todo;
  final Function(Todo) onUpdate;
  final Function(int) onDelete;

  const TodoListItem({
    super.key,
    required this.todo,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: todo.completed,
        activeColor: Colors.green,
        onChanged: (value) {
          todo.completed = value!;
          onUpdate(todo);
        },
      ),
      title: Text(
        todo.task,
        style: GoogleFonts.raleway(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          decoration: todo.completed
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
      subtitle: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 4.0),
            child: Icon(
              Icons.alarm,
              color: Colors.grey,
              size: 14,
            ),
          ),
          Text(
            DateFormat(
              '${DateFormat.ABBR_MONTH_DAY} ${DateFormat.HOUR24_MINUTE}',
            ).format(todo.deadline!),
            style: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.delete,
          color: Colors.red,
        ),
        onPressed: () {
          onDelete(todo.id);
        },
      ),
    );
  }
}
