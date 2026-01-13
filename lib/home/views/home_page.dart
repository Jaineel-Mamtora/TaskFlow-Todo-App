import 'package:flutter/material.dart';

import 'package:taskflow_todo_app/todo_overview/views/todo_overview_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow'),
      ),
      body: const TodoOverviewPage(),
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
