import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todos_repository/todos_repository.dart';

import 'package:taskflow_todo_app/todos/bloc/todos_bloc.dart';

class TodoDismissibleTile extends StatelessWidget {
  const TodoDismissibleTile({
    required this.todo,
    super.key,
  });

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(
        context,
        alignment: Alignment.centerLeft,
        icon: Icons.delete_outline,
      ),
      secondaryBackground: _buildDismissBackground(
        context,
        alignment: Alignment.centerRight,
        icon: Icons.delete_outline,
      ),
      confirmDismiss: (direction) async {
        return showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete task?'),
              content: const Text(
                'Are you sure you want to delete this task? '
                'This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (_) {
        context.read<TodosOverviewBloc>().add(
          TodosOverviewTodoDeleted(todo),
        );
      },
      child: ListTile(
        title: Text(todo.title),
        tileColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildDismissBackground(
    BuildContext context, {
    required Alignment alignment,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.onError,
        size: 28,
      ),
    );
  }
}
