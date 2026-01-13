import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todos_repository/todos_repository.dart';

import 'package:taskflow_todo_app/todo_overview/bloc/todos_overview_bloc.dart';
import 'package:taskflow_todo_app/todo_overview/views/todo_filter_chip_list.dart';
import 'package:taskflow_todo_app/todo_overview/views/todo_search_field.dart';
import 'package:taskflow_todo_app/todo_overview/views/todo_sliver_list.dart';

class TodoOverviewPage extends StatelessWidget {
  const TodoOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TodosOverviewBloc>(
      create: (context) => TodosOverviewBloc(
        todoRepository: context.read<TodosRepository>(),
      )..add(const TodosOverviewRequested()),
      child: const TodoOverviewView(),
    );
  }
}

class TodoOverviewView extends StatelessWidget {
  const TodoOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodosOverviewBloc, TodosOverviewState>(
      builder: (context, state) {
        switch (state) {
          case TodosOverviewInitial():
          case TodosOverviewLoading():
            return const Center(
              child: CircularProgressIndicator(),
            );
          case TodosOverviewLoaded():
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: TodoSearchField(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: TodoFilterChipList(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                TodoSliverList(todos: state.todos),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          case TodosOverviewFailure():
            return const Center(
              child: Text('Something went wrong.'),
            );
        }
      },
    );
  }
}
