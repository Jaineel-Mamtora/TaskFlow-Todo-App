import 'package:flutter/material.dart';

import 'package:todos_repository/todos_repository.dart';

import 'package:taskflow_todo_app/todos/views/todo_dismissible_tile.dart';

class TodoSliverList extends StatelessWidget {
  const TodoSliverList({
    required this.todos,
    super.key,
  });

  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final itemIndex = index ~/ 2;

          if (index.isOdd) {
            return const SizedBox(height: 12.0);
          }

          return TodoDismissibleTile(
            todo: todos[itemIndex],
          );
        },
        childCount: todos.isEmpty ? 0 : todos.length * 2 - 1,
      ),
    );
  }
}
