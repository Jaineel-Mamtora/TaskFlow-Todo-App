import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskflow_todo_app/todos/bloc/todos_bloc.dart';
import 'package:taskflow_todo_app/todos/models/todos_filter.dart';

class TodoFilterChipList extends StatelessWidget {
  const TodoFilterChipList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodosOverviewBloc, TodosOverviewState>(
      buildWhen: (prev, curr) {
        // rebuild only when filter changes (and only for Loaded)
        final p = prev is TodosOverviewLoaded ? prev.filter : null;
        final c = curr is TodosOverviewLoaded ? curr.filter : null;
        return p != c;
      },
      builder: (context, state) {
        if (state is! TodosOverviewLoaded) return const SizedBox.shrink();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              TodoFilter.values.length,
              (index) {
                final filter = TodoFilter.values[index];
                final isSelected = state.filter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    checkmarkColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (_) {
                      context.read<TodosOverviewBloc>().add(
                        TodosOverviewTodosFilterChanged(filter),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
