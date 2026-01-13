import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:taskflow_todo_app/todos/bloc/todos_bloc.dart';

class NoSearchResultPlaceholder extends StatelessWidget {
  const NoSearchResultPlaceholder({
    super.key,
    required this.query,
  });

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No results found'),
          if (query.trim().isNotEmpty)
            TextButton(
              onPressed: () {
                context.read<TodosOverviewBloc>().add(
                  const TodosOverviewSearchQueryChanged(
                    '',
                  ),
                );
              },
              child: const Text('Clear search'),
            ),
        ],
      ),
    );
  }
}
