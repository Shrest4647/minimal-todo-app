import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minimalistic_todo_app/components/dayselector.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Todo> _todos = [];
  late DateTime activeDate;
  Database? _database;

  @override
  void initState() {
    super.initState();
    activeDate = DateTime.now();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'todo_list.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) {
        db.execute(
          'CREATE TABLE todos (id INTEGER PRIMARY KEY AUTOINCREMENT, task TEXT, completed INTEGER, deadline INTEGER NULL, created INTEGER NULL, updated INTEGER NULL, completed_at INTEGER NULL)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          // "Upgrading database from version $oldVersion to $newVersion"
        }
      },
    );

    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final List<Map<String, dynamic>> maps =
        await _database!.query('todos', orderBy: "deadline desc");
    setState(() {
      _todos.clear();
      _todos.addAll(
        maps.map((map) => Todo(
              id: map['id'],
              task: map['task'],
              completed: map['completed'] == 1,
              deadline: map['deadline'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      map['deadline'].toInt() * 1000),
              created: map['created'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      map['created'].toInt() * 1000),
              updated: map['updated'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      map['updated'].toInt() * 1000),
            )),
      );
    });
  }

  Future<void> _addTodo(String task) async {
    await _database!.insert(
      'todos',
      {
        'task': task,
        'completed': 0,
        'deadline': DateTime.now()
                .add(const Duration(hours: 2))
                .millisecondsSinceEpoch ~/
            1000,
        'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'updated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
    );
    _loadTodos();
  }

  Future<void> _updateTodo(Todo todo) async {
    await _database!.update(
      'todos',
      {'completed': todo.completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<void> _deleteTodo(int id) async {
    await _database!.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadTodos();
  }

  Future<void> _reorderTodos(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Todo movedTodo = _todos.removeAt(oldIndex);
    _todos.insert(newIndex, movedTodo);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Todo List',
          style: GoogleFonts.poly().copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DaySelector(
            defaultActiveDay: activeDate,
            onActiveDayChanged: (date) {
              setState(() {
                activeDate = date;
              });
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              "Tasks",
              textAlign: TextAlign.left,
              style: GoogleFonts.caveat().copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              onReorder: _reorderTodos,
              itemCount: _todos.length + 1,
              itemBuilder: (context, index) {
                if (index == _todos.length) {
                  return ListTile(
                    key: const Key("END"),
                    title: SizedBox(
                      height: 100,
                      child: Text(
                        "--- End of List ---",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.caveat().copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                final todo = _todos[index];
                return ListTile(
                  key: Key(todo.id.toString()),
                  leading: Checkbox(
                    value: todo.completed,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      setState(() {
                        todo.completed = value!;
                        _updateTodo(todo);
                      });
                    },
                  ),
                  title: Text(
                    todo.task,
                    style: GoogleFonts.caveat().copyWith(
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
                        DateFormat(DateFormat.ABBR_MONTH_WEEKDAY_DAY)
                            .format(todo.deadline!),
                        style: GoogleFonts.caveat().copyWith(
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
                      _deleteTodo(todo.id);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTodoDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    TextEditingController taskController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextField(
                controller: taskController,
                maxLines: 2,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Enter task',
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    value: false,
                    onChanged: null,
                  ),
                  Text('Add Deadline'),
                ],
              )
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addTodo(taskController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class Todo {
  final int id;
  final String task;
  bool completed;
  DateTime? deadline;
  DateTime? created;
  DateTime? updated;
  DateTime? completedAt;

  Todo({
    required this.id,
    required this.task,
    required this.completed,
    this.deadline,
    this.created,
    this.updated,
    this.completedAt,
  }) {
    created = created ?? DateTime.now();
    deadline = deadline ?? created?.add(const Duration(days: 1));
    updated = updated ?? created;
  }
}
