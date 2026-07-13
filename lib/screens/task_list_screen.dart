import 'package:flutter/material.dart';

import '../models/task.dart';
import 'add_task_screen.dart';
import 'task_details_screen.dart';

class TaskListScreen extends StatefulWidget {
  final List<Task> tasks;
  final void Function(String title, String description) onAddTask;
  final void Function(int index) onToggleTask;
  final void Function(int index) onDeleteTask;

  const TaskListScreen({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onDeleteTask,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  void openAddTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(onAddTask: widget.onAddTask),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void openTaskDetails(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(
          task: widget.tasks[index],
          taskIndex: index,
          onToggleTask: widget.onToggleTask,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  void toggleTask(int index) {
    widget.onToggleTask(index);
    setState(() {});
  }

  void deleteTask(int index) {
    widget.onDeleteTask(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('task_list_screen'),
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('floating_add_task_button'),
        onPressed: () => openAddTask(context),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: widget.tasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 82,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tasks available',
                    key: Key('empty_task_list_text'),
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              key: const Key('task_list'),
              padding: const EdgeInsets.all(16),
              itemCount: widget.tasks.length,
              itemBuilder: (context, index) {
                final task = widget.tasks[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Material(
                    key: Key('task_card_$index'),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      key: Key('task_tile_$index'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      leading: Checkbox(
                        key: Key('task_checkbox_$index'),
                        value: task.isCompleted,
                        activeColor: const Color(0xFF00BFA6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: (_) => toggleTask(index),
                      ),
                      title: Text(
                        task.title,
                        key: Key('task_title_$index'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          task.isCompleted ? 'Completed' : 'Pending',
                          key: Key('task_status_$index'),
                          style: TextStyle(
                            color: task.isCompleted
                                ? const Color(0xFF00BFA6)
                                : const Color(0xFFFF9800),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        key: Key('delete_task_button_$index'),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFE53935),
                        ),
                        onPressed: () => deleteTask(index),
                      ),
                      onTap: () => openTaskDetails(context, index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
