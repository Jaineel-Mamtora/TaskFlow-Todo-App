import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todos_repository/todos_repository.dart';

import 'package:taskflow_todo_app/todos/bloc/todos_bloc.dart';
import 'package:taskflow_todo_app/todos/views/no_search_result_placeholder.dart';
import 'package:taskflow_todo_app/todos/views/todo_filter_chip_list.dart';
import 'package:taskflow_todo_app/todos/views/todo_search_field.dart';
import 'package:taskflow_todo_app/todos/views/todo_sliver_list.dart';

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TodoOverviewView();
  }
}

class TodoOverviewView extends StatelessWidget {
  const TodoOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TodosOverviewBloc, TodosOverviewState>(
      listenWhen: (previous, current) {
        if (previous is TodosOverviewLoaded && current is TodosOverviewLoaded) {
          return previous.completionError != current.completionError;
        }
        return false;
      },
      listener: (context, state) {
        if (state is TodosOverviewLoaded &&
            state.completionError != null &&
            state.completionError!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.completionError!)),
          );
        }
      },
      child: BlocBuilder<TodosOverviewBloc, TodosOverviewState>(
        builder: (context, state) {
          if (state is TodosOverviewLoading || state is TodosOverviewInitial) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is TodosOverviewListLoading ||
              state is TodosOverviewLoaded) {
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
                    BlocSelector<
                      TodosOverviewBloc,
                      TodosOverviewState,
                      List<Todo>
                    >(
                      selector: (state) {
                        return state is TodosOverviewLoaded
                            ? state.visibleTodos
                            : const <Todo>[];
                      },
                      builder: (context, visibleTodos) {
                        if (visibleTodos.isEmpty) {
                          final query = context.select(
                            (TodosOverviewBloc bloc) {
                              final blocState = bloc.state;
                              return blocState is TodosOverviewLoaded
                                  ? blocState.searchQuery
                                  : '';
                            },
                          );
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: NoSearchResultPlaceholder(query: query),
                          );
                        }

                        return TodoSliverList(
                          todos: visibleTodos,
                        );
                      },
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
      ),
    );
  }
}
