import 'package:flutter/material.dart';

import 'package:todos_repository/todos_repository.dart';

class TodoSliverList extends StatelessWidget {
  const TodoSliverList({
    required this.todos,
    super.key,
  });

  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final itemIndex = index ~/ 2;

          if (index.isOdd) {
            return const SizedBox(height: 12.0);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ListTile(
              key: ValueKey(todos[itemIndex].id),
              title: Text(todos[itemIndex].title),
              tileColor: theme.colorScheme.surfaceContainer,
            ),
          );
        },
        childCount: todos.isEmpty ? 0 : todos.length * 2 - 1,
      ),
    );
  }
}
