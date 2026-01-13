part of 'todos_bloc.dart';

sealed class TodosOverviewEvent extends Equatable {
  const TodosOverviewEvent();

  @override
  List<Object> get props => [];
}

final class TodosOverviewRequested extends TodosOverviewEvent {
  const TodosOverviewRequested();
}

final class TodosOverviewTodosFilterChanged extends TodosOverviewEvent {
  const TodosOverviewTodosFilterChanged(this.filter);

  final TodoFilter filter;

  @override
  List<Object> get props => [filter];
}

final class TodosOverviewSearchQueryChanged extends TodosOverviewEvent {
  const TodosOverviewSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object> get props => [query];
}

final class TodosOverviewTodoDeleted extends TodosOverviewEvent {
  const TodosOverviewTodoDeleted(this.todo);

  final Todo todo;

  @override
  List<Object> get props => [todo];
}

final class TodosOverviewTodoAddedRequested extends TodosOverviewEvent {
  const TodosOverviewTodoAddedRequested(this.title);

  final String title;

  @override
  List<Object> get props => [title];
}

final class TodosOverviewTodoUpdatedRequested extends TodosOverviewEvent {
  const TodosOverviewTodoUpdatedRequested({
    required this.todo,
    required this.updatedTitle,
  });

  final Todo todo;
  final String updatedTitle;

  @override
  List<Object> get props => [todo, updatedTitle];
}

final class TodosOverviewTodoCompletionToggled extends TodosOverviewEvent {
  const TodosOverviewTodoCompletionToggled({
    required this.todo,
    required this.completed,
  });

  final Todo todo;
  final bool completed;

  @override
  List<Object> get props => [todo, completed];
}
