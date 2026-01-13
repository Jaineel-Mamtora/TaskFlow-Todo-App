import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:taskflow_todo_app/todos/bloc/todos_bloc.dart';

class TodoSearchField extends StatefulWidget {
  const TodoSearchField({super.key});

  @override
  State<TodoSearchField> createState() => _TodoSearchFieldState();
}

class _TodoSearchFieldState extends State<TodoSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TodosOverviewBloc, TodosOverviewState, String>(
      selector: (state) {
        return state is TodosOverviewLoaded ? state.searchQuery : '';
      },
      builder: (context, query) {
        if (_controller.text != query) {
          _controller.value = TextEditingValue(
            text: query,
            selection: TextSelection.collapsed(offset: query.length),
          );
        }

        return TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Search tasks…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _controller.clear();
                      context.read<TodosOverviewBloc>().add(
                        const TodosOverviewSearchQueryChanged(''),
                      );
                    },
                  ),
          ),
          onChanged: (value) {
            context.read<TodosOverviewBloc>().add(
              TodosOverviewSearchQueryChanged(value),
            );
          },
        );
      },
    );
  }
}
