import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todos_repository/todos_repository.dart';

import 'package:taskflow_todo_app/todos/bloc/todos_bloc.dart';
import 'package:taskflow_todo_app/todos/views/todo_filter_chip_list.dart';
import 'package:taskflow_todo_app/todos/views/todo_search_field.dart';
import 'package:taskflow_todo_app/todos/views/todo_sliver_list.dart';

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

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
        if (state is TodosOverviewLoading || state is TodosOverviewInitial) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is TodosOverviewListLoading || state is TodosOverviewLoaded) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: TodoSearchField(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 12),
                ),

                const SliverToBoxAdapter(
                  child: TodoFilterChipList(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 12),
                ),

                if (state is TodosOverviewListLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  TodoSliverList(
                    todos: (state as TodosOverviewLoaded).todos,
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),
          );
        }
        if (state is TodosOverviewFailure) {
          return const Center(
            child: Text('Something went wrong.'),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
