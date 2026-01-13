part of 'todos_overview_bloc.dart';

enum TodoFilter { all, active, completed }

extension TodoFilterX on TodoFilter {
  String get label => switch (this) {
    TodoFilter.all => 'All',
    TodoFilter.active => 'Active',
    TodoFilter.completed => 'Completed',
  };
}

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
