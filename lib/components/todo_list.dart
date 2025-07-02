import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/todo.dart';
import 'todo_list_item.dart';

class TodoList extends StatelessWidget {
  final List<Todo> todos;
  final Function(int, int) onReorder;
  final Function(Todo) onUpdate;
  final Function(int) onDelete;

  const TodoList({
    super.key,
    required this.todos,
    required this.onReorder,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ReorderableListView.builder(
        onReorder: onReorder,
        itemCount: todos.length + 1,
        itemBuilder: (context, index) {
          if (index == todos.length) {
            return ListTile(
              key: const Key("END"),
              title: SizedBox(
                height: 100,
                child: Text(
                  "--- End of List ---",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
          final todo = todos[index];
          return TodoListItem(
            key: Key(todo.id.toString()),
            todo: todo,
            onUpdate: onUpdate,
            onDelete: onDelete,
          );
        },
      ),
    );
  }
}
