import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'model/todo.dart';

class ToDoApp extends StatefulWidget {
  const ToDoApp({super.key});

  @override
  _ToDoAppState createState() => _ToDoAppState();
}

class _ToDoAppState extends State<ToDoApp> {
  List<ToDoItem> _tasks = [];
  List<ToDoItem> _todayTasks = [];
  final List<ToDoItem> _dailyTasks = [
    ToDoItem(title: 'Buy groceries'),
    ToDoItem(title: 'Learn Flutter'),
    ToDoItem(title: 'Exercise'),
    ToDoItem(title: 'Read book'),
    ToDoItem(title: 'Play game'),
  ];
  final TextEditingController _dailyTextController = TextEditingController();
  final TextEditingController _todayTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedDailyTasks = prefs.getString('dailyTasks');
    String? storedTodayTasks = prefs.getString('todayTasks');
    String? lastSaved = prefs.getString('lastSavedDate');
    String? lastTodaySaved = prefs.getString('lastTodaySavedDate');

    // Load daily tasks and ensure they persist across days
    if (storedDailyTasks != null && lastSaved != null) {
      if (DateFormat('yyyy-MM-dd').format(DateTime.now()) == lastSaved) {
        List decodedTasks = jsonDecode(storedDailyTasks);
        setState(() {
          _tasks = decodedTasks.map((e) => ToDoItem.fromJson(e)).toList();
        });
      } else {
        setState(() {
          _tasks = List.from(_dailyTasks);
        });
      }
    } else {
      setState(() {
        _tasks = List.from(_dailyTasks);
      });
    }

    // Reset "Today Task" list every day
    if (storedTodayTasks != null && lastTodaySaved != null) {
      if (DateFormat('yyyy-MM-dd').format(DateTime.now()) == lastTodaySaved) {
        List decodedTodayTodos = jsonDecode(storedTodayTasks);
        setState(() {
          _todayTasks = decodedTodayTodos.map((e) => ToDoItem.fromJson(e)).toList();
        });
      } else {
        setState(() {
          _todayTasks = [];
        });
      }
    } else {
      setState(() {
        _todayTasks = [];
      });
    }
  }

  Future<void> _saveDailyTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('dailyTasks', jsonEncode(_tasks));
    prefs.setString('lastSavedDate', DateFormat('yyyy-MM-dd').format(DateTime.now()));
  }

  Future<void> _saveTodayTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('todayTasks', jsonEncode(_todayTasks));
    prefs.setString('lastTodaySavedDate', DateFormat('yyyy-MM-dd').format(DateTime.now()));
  }

  void _toggleDailyFinished(int index) {
    setState(() {
      _tasks[index].isFinished = !_tasks[index].isFinished;
    });
    _saveDailyTasks();
  }

  void _toggleTodayFinished(int index) {
    setState(() {
      _todayTasks[index].isFinished = !_todayTasks[index].isFinished;
    });
    _saveTodayTasks();
  }

  void _deleteDailyTask(int index) {
    String taskTitle = _tasks[index].title;

    setState(() {
      // Remove the task from _tasks
      _tasks.removeAt(index);
      // Remove the task from _dailyTasks by matching the title
      _dailyTasks.removeWhere((task) => task.title == taskTitle);
    });

    // Save the updated tasks list
    _saveDailyTasks();
  }


  void _deleteTodayTask(int index) {
    setState(() {
      _todayTasks.removeAt(index);
    });
    _saveTodayTasks();
  }

  void _addDailyTask() {
    String newTitle = _dailyTextController.text.trim();
    if (newTitle.isNotEmpty) {
      setState(() {
        _tasks.insert(0, ToDoItem(title: newTitle));
        _dailyTasks.insert(0, ToDoItem(title: newTitle));  // Add to the default list
      });
      _dailyTextController.clear();
      _saveDailyTasks();
      FocusScope.of(context).unfocus();
    }
  }

  void _addTodayTask() {
    String newTitle = _todayTextController.text.trim();
    if (newTitle.isNotEmpty) {
      setState(() {
        _todayTasks.insert(0, ToDoItem(title: newTitle));
      });
      _todayTextController.clear();
      _saveTodayTasks();
      FocusScope.of(context).unfocus();
    }
  }

  void _openAddTaskDialog(String listType) {
    TextEditingController controller = listType == 'daily' ? _dailyTextController : _todayTextController;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(listType == 'daily' ? "Add new daily task" : "Add new today task"),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Enter task title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (listType == 'daily') {
                  _addDailyTask();
                } else {
                  _addTodayTask();
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(int index, String listType) {
    showDialog(
      context: context,
      builder: (context) {
        // Determine the task title based on the list type
        String taskTitle = listType == 'daily' ? _tasks[index].title : _todayTasks[index].title;

        return AlertDialog(
          title: const Text("Delete Task"),
          content: Text("Do you want to delete the task:\n${taskTitle}?"),
          actions: [
            TextButton(
              onPressed: () {
                // Delete the task based on the list type
                if (listType == 'daily') {
                  _deleteDailyTask(index);
                } else {
                  _deleteTodayTask(index);
                }
                Navigator.pop(context); // Close the dialog after deletion
              },
              child: const Text("Delete"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog without deleting
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title for Daily Task
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Daily Task",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openAddTaskDialog('daily'),
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'ADD TASK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.white, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Daily Task List
                Container(
                  padding: const EdgeInsets.all(10),
                  child:  _tasks.isEmpty
                      ? const Center(
                    child: Text(
                      'No daily task at the moment',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ) : Column(
                    children: _tasks.map((todo) {
                      int index = _tasks.indexOf(todo);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            todo.title,
                            style: TextStyle(
                              decoration: todo.isFinished
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  todo.isFinished
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: Colors.green,
                                ),
                                onPressed: () => _toggleDailyFinished(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(index, 'daily'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),
                // Title for Today Task
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today Task",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openAddTaskDialog('today'),
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'ADD TASK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.white, width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Today Task List
                Container(
                  padding: const EdgeInsets.all(10),
                  child: _todayTasks.isEmpty
                      ? const Center(
                    child: Text(
                      'No tasks for today',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                      : Column(
                    children: _todayTasks.map((todo) {
                      int index = _todayTasks.indexOf(todo);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            todo.title,
                            style: TextStyle(
                              decoration: todo.isFinished
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  todo.isFinished
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: Colors.green,
                                ),
                                onPressed: () => _toggleTodayFinished(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(index, 'today'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}