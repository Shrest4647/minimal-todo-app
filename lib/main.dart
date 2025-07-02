import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:google_fonts/google_fonts.dart';

import 'components/add_todo_dialog.dart';
import 'models/todo.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasklite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.ralewayTextTheme(),
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
  final _easyDateTimelineController = EasyInfiniteDateTimelineController();
  bool _showTimeline = false;
  @override
  void initState() {
    super.initState();
    activeDate = DateTime.now();
    _initDatabase();
  }

  void _toggleTimeline() {
    setState(() {
      _showTimeline = !_showTimeline;
    });
  }

  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'todo_list.db');

    _database = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) {
        db.execute(
          'CREATE TABLE todos (id INTEGER PRIMARY KEY AUTOINCREMENT, task TEXT, completed INTEGER, deadline INTEGER NULL, created INTEGER NULL, updated INTEGER NULL, completed_at INTEGER NULL, reminder INTEGER NULL)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 3) {
          db.execute('ALTER TABLE todos ADD COLUMN reminder INTEGER NULL');
        }
      },
    );

    _loadTodos();
  }

  Future<void> _loadTodos() async {
    int twodaysAgo = DateTime(activeDate.year, activeDate.month, activeDate.day)
            .subtract(const Duration(days: 2))
            .millisecondsSinceEpoch ~/
        1000;
    int threeDaysAfter =
        DateTime(activeDate.year, activeDate.month, activeDate.day)
                .add(const Duration(days: 3))
                .millisecondsSinceEpoch ~/
            1000;
    final List<Map<String, dynamic>> maps = await _database!.query('todos',
        orderBy: "completed, created desc",
        where: "deadline between ? and ? or created between ? and ?",
        whereArgs: [
          twodaysAgo,
          threeDaysAfter,
          twodaysAgo,
          threeDaysAfter,
        ]);
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
              completedAt: map['completed_at'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      map['completed_at'].toInt() * 1000),
              reminder: map['reminder'] == 1,
            )),
      );
    });
  }

  Future<void> _addTodo({
    required String task,
    DateTime? deadline,
    bool? reminder,
  }) async {
    await _database!.insert(
      'todos',
      {
        'task': task,
        'completed': 0,
        'deadline': (deadline ?? DateTime.now())
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
        'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'updated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'reminder': reminder ?? false,
      },
    );
    _loadTodos();
  }

  Future<void> _updateTodo(Todo todo) async {
    await _database!.update(
      'todos',
      {
        'completed': todo.completed ? 1 : 0,
        'completed_at': todo.completed
            ? DateTime.now().millisecondsSinceEpoch ~/ 1000
            : null,
      },
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
  void dispose() {
    _database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tasklite',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // set current date to today
                      setState(() {
                        activeDate = DateTime.now();
                        _loadTodos();
                        if (_showTimeline) {
                          _easyDateTimelineController.animateToCurrentData();
                        }
                      });
                    },
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
                    onPressed: () {
                      _toggleTimeline();
                    },
                    icon: _showTimeline
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
          Visibility(
            visible: _showTimeline,
            child: EasyInfiniteDateTimeLine(
              selectionMode: const SelectionMode.autoCenter(),
              controller: _easyDateTimelineController,
              focusDate: activeDate,
              firstDate: DateTime(2000, 1, 1),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              onDateChange: (selectedDate) {
                activeDate = selectedDate;
                _loadTodos();
                setState(() {});
              },
              showTimelineHeader: false,
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              "Tasks",
              textAlign: TextAlign.left,
              style: TextStyle(
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
                        "✨ All caught up! Time for a break! ✨",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
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
                                '${DateFormat.ABBR_MONTH_DAY} ${DateFormat.HOUR24_MINUTE}')
                            .format(todo.deadline!),
                        style: GoogleFonts.raleway(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Visibility(
                        visible: todo.reminder ?? false,
                        child: const Padding(
                          padding: EdgeInsets.only(
                            left: 8.0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notification_important,
                                color: Colors.pinkAccent,
                                size: 16,
                              ),
                            ],
                          ),
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
    showDialog(
      context: context,
      builder: (context) {
        return AddTodoDialog(
          onAdd: (task, deadline, reminder) {
            _addTodo(
              task: task,
              deadline: deadline,
              reminder: reminder,
            );
          },
        );
      },
    );
  }
}
