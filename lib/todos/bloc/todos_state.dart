part of 'todos_bloc.dart';

enum TodosOverviewActionStatus { idle, addInProgress, addSuccess, addFailure }

sealed class TodosOverviewState extends Equatable {
  const TodosOverviewState();

  @override
  List<Object?> get props => [];
}

final class TodosOverviewInitial extends TodosOverviewState {
  const TodosOverviewInitial();
}

final class TodosOverviewLoading extends TodosOverviewState {
  const TodosOverviewLoading();
}

final class TodosOverviewListLoading extends TodosOverviewState {
  const TodosOverviewListLoading();
}

final class TodosOverviewLoaded extends TodosOverviewState {
  const TodosOverviewLoaded({
    required this.todos,
    this.filter = TodoFilter.all,
    this.searchQuery = '',
    this.actionStatus = TodosOverviewActionStatus.idle,
    this.actionError,
    this.updatingTodoIds = const <int>{},
    this.completionError,
  });

  static const _sentinel = Object();

  final List<Todo> todos;
  final TodoFilter filter;
  final String searchQuery;
  final TodosOverviewActionStatus actionStatus;
  final String? actionError;
  final Set<int> updatingTodoIds;
  final String? completionError;

  TodosOverviewLoaded copyWith({
    List<Todo>? todos,
    TodoFilter? filter,
    String? searchQuery,
    TodosOverviewActionStatus? actionStatus,
    Object? actionError = _sentinel,
    Set<int>? updatingTodoIds,
    Object? completionError = _sentinel,
  }) {
    return TodosOverviewLoaded(
      todos: todos ?? this.todos,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      actionStatus: actionStatus ?? this.actionStatus,
      actionError: actionError == _sentinel
          ? this.actionError
          : actionError as String?,
      updatingTodoIds: updatingTodoIds ?? this.updatingTodoIds,
      completionError: completionError == _sentinel
          ? this.completionError
          : completionError as String?,
    );
  }

  @override
  List<Object?> get props => [
    todos,
    filter,
    searchQuery,
    actionStatus,
    actionError,
    updatingTodoIds,
    completionError,
  ];
}

final class TodosOverviewFailure extends TodosOverviewState {
  final String message;

  const TodosOverviewFailure(this.message);

  @override
  List<Object> get props => [message];
}
