import 'package:flutter/material.dart';

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
        onPressed: () {
          // TODO: implement
        },
        child: const Icon(
          Icons.add_rounded,
          size: 30,
        ),
      ),
    );
  }
}
