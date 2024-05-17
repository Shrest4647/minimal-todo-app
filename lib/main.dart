import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:date_field/date_field.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.satisfy().fontFamily,
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
  TextEditingController taskController = TextEditingController();
  DateTime? deadline = DateTime.now().add(const Duration(hours: 2));
  bool? reminder = false;
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
  void dispose() {
    _database?.close();
    super.dispose();
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _easyDateTimelineController.animateToCurrentData();
                  },
                  child: Text(
                    "Today",
                    textAlign: TextAlign.left,
                    style: GoogleFonts.satisfy().copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _easyDateTimelineController.animateToDate(activeDate);
                  },
                  child: Text(
                    DateFormat(DateFormat.ABBR_MONTH_WEEKDAY_DAY)
                        .format(activeDate),
                    textAlign: TextAlign.left,
                    style: GoogleFonts.satisfy().copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          EasyInfiniteDateTimeLine(
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
                        DateFormat(
                                '${DateFormat.ABBR_MONTH_DAY} ${DateFormat.HOUR24_MINUTE}')
                            .format(todo.deadline!),
                        style: GoogleFonts.caveat().copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // const Padding(
                      //   padding: EdgeInsets.only(
                      //     left: 8.0,
                      //   ),
                      //   child: Icon(
                      //     Icons.notification_important,
                      //     color: Colors.pinkAccent,
                      //     size: 16,
                      //   ),
                      // ),
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
        return Center(
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text(
                    'Add Todo',
                    style: GoogleFonts.satisfy(),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
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
                      reminder == true
                          ? DateTimeFormField(
                              dateFormat: DateFormat(
                                '${DateFormat.ABBR_MONTH_DAY}, ${DateFormat.ABBR_WEEKDAY} ${DateFormat.HOUR24}:${DateFormat.MINUTE}',
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter Date',
                              ),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(minutes: 1)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              onChanged: (DateTime? value) {
                                setState(() {
                                  deadline = value;
                                });
                              },
                            )
                          : const SizedBox(),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: reminder,
                            activeColor: Colors.green,
                            onChanged: (bool? value) {
                              setState(() {
                                reminder = value;
                              });
                            },
                          ),
                          const Text(
                            'Reminder',
                          ),
                        ],
                      )
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
                        _addTodo(
                          task: taskController.text,
                          deadline: reminder == true ? deadline : null,
                          reminder: reminder,
                        );
                        taskController.clear();
                        deadline = null;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Add'),
                    ),
                  ],
                );
              },
            ),
          ),
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
