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
  });

  final List<Todo> todos;
  final TodoFilter filter;
  final String searchQuery;
  final TodosOverviewActionStatus actionStatus;
  final String? actionError;

  @override
  List<Object?> get props => [
    todos,
    filter,
    searchQuery,
    actionStatus,
    actionError,
  ];
}

final class TodosOverviewFailure extends TodosOverviewState {
  final String message;

  const TodosOverviewFailure(this.message);

  @override
  List<Object> get props => [message];
}
