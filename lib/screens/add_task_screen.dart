import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  final void Function(String title, String description) onAddTask;

  const AddTaskScreen({
    super.key,
    required this.onAddTask,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String? errorMessage;

  void saveTask() {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();

    if (title.isEmpty) {
      setState(() {
        errorMessage = 'Task title is required';
      });
      return;
    }

    widget.onAddTask(title, description);

    Navigator.pop(context);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('add_task_screen'),
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.add_task,
                      size: 62,
                      color: Color(0xFF6C63FF),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Create New Task',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Add a title and optional description.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              TextField(
                key: const Key('task_title_input'),
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                key: const Key('task_description_input'),
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Task description',
                  prefixIcon: Icon(Icons.description),
                ),
              ),

              const SizedBox(height: 16),

              if (errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    errorMessage!,
                    key: const Key('error_message'),
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('save_task_button'),
                  onPressed: saveTask,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}