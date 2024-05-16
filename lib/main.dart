import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Todo> _todos = [];
  Database? _database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'todo_list.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute(
          'CREATE TABLE todos (id INTEGER PRIMARY KEY AUTOINCREMENT, task TEXT, completed INTEGER)',
        );
      },
    );

    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final List<Map<String, dynamic>> maps = await _database!.query('todos');
    setState(() {
      _todos.clear();
      _todos.addAll(
        maps.map((map) => Todo(
              id: map['id'],
              task: map['task'],
              completed: map['completed'] == 1,
            )),
      );
    });
  }

  Future<void> _addTodo(String task) async {
    await _database!.insert(
      'todos',
      {'task': task, 'completed': 0},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
      ),
      body: ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          final todo = _todos[index];
          return ListTile(
            leading: Checkbox(
              value: todo.completed,
              onChanged: (value) {
                setState(() {
                  todo.completed = value!;
                  _updateTodo(todo);
                });
              },
            ),
            title: Text(
              todo.task,
              style: TextStyle(
                decoration: todo.completed
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red,),
              onPressed: () {
                _deleteTodo(todo.id);
              },
            ),
          );
        },
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
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(
              hintText: 'Enter task',
            ),
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

  Todo({required this.id, required this.task, required this.completed});
}