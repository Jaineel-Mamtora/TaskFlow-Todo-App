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

class TodoOverviewView extends StatefulWidget {
  const TodoOverviewView({super.key});

  @override
  State<TodoOverviewView> createState() => _TodoOverviewViewState();
}

class _TodoOverviewViewState extends State<TodoOverviewView> {
  SyncStatus? _lastSyncStatus;
  bool _shouldAnnounceSync = false;
  bool? _lastIsOffline;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TodosOverviewBloc, TodosOverviewState>(
      listenWhen: (previous, current) {
        if (previous is TodosOverviewLoaded && current is TodosOverviewLoaded) {
          return previous.completionError != current.completionError ||
              previous.infoMessage != current.infoMessage ||
              previous.syncStatus != current.syncStatus;
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
        if (state is TodosOverviewLoaded &&
            state.infoMessage != null &&
            state.infoMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.infoMessage!)),
          );
        }
        if (state is TodosOverviewLoaded) {
          if (_lastIsOffline == true && !state.isOffline) {
            _shouldAnnounceSync = true;
          }
          _lastIsOffline = state.isOffline;
          if (_lastSyncStatus != state.syncStatus) {
            if (_shouldAnnounceSync && state.syncStatus == SyncStatus.syncing) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing tasks...')),
              );
            } else if (_shouldAnnounceSync &&
                _lastSyncStatus == SyncStatus.syncing &&
                state.syncStatus == SyncStatus.idle) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync complete.')),
              );
              _shouldAnnounceSync = false;
            } else if (_shouldAnnounceSync &&
                state.syncStatus == SyncStatus.failed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync failed.')),
              );
              _shouldAnnounceSync = false;
            }
          }
          _lastSyncStatus = state.syncStatus;
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
                  if (state is TodosOverviewLoaded && state.isOffline)
                    const SliverToBoxAdapter(
                      child: _OfflineBanner(),
                    ),

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

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline — will sync later',
              style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
