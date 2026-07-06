import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskDetailsScreen extends StatelessWidget {
  final Task task;
  final int taskIndex;
  final void Function(int index) onToggleTask;

  const TaskDetailsScreen({
    super.key,
    required this.task,
    required this.taskIndex,
    required this.onToggleTask,
  });

  void toggleAndGoBack(BuildContext context) {
    onToggleTask(taskIndex);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('task_details_screen'),
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.pending_actions,
                      size: 52,
                      color: task.isCompleted
                          ? const Color(0xFF00BFA6)
                          : const Color(0xFFFF9800),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      task.title,
                      key: const Key('details_task_title'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      task.description,
                      key: const Key('details_task_description'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? const Color(0xFFE6F8F5)
                            : const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        task.isCompleted
                            ? 'Status: Completed'
                            : 'Status: Pending',
                        key: const Key('details_task_status'),
                        style: TextStyle(
                          color: task.isCompleted
                              ? const Color(0xFF008C7A)
                              : const Color(0xFFFF9800),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('details_toggle_complete_button'),
                  onPressed: () => toggleAndGoBack(context),
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    task.isCompleted ? 'Mark as Pending' : 'Mark as Completed',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}