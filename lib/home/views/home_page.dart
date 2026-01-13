import 'package:flutter/material.dart';

import 'package:taskflow_todo_app/todos/views/add_todo_bottom_sheet.dart';
import 'package:taskflow_todo_app/todos/views/todos_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow'),
      ),
      body: const TodosPage(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await showAddTodoBottomSheet(context);

          if (added == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task added')),
            );
          }
        },
        child: const Icon(
          Icons.add_rounded,
          size: 30,
        ),
      ),
    );
  }
}
