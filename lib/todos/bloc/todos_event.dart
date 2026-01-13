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

final class TodosOverviewTodosSearchChanged extends TodosOverviewEvent {
  const TodosOverviewTodosSearchChanged(this.query);

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
