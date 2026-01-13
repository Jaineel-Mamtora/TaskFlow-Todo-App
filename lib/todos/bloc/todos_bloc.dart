import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:todos_repository/todos_repository.dart';

import 'package:taskflow_todo_app/todos/models/todos_filter.dart';

part 'todos_event.dart';
part 'todos_state.dart';

class TodosOverviewBloc extends Bloc<TodosOverviewEvent, TodosOverviewState> {
  TodosOverviewBloc({required TodosRepository todoRepository})
    : _todosRepository = todoRepository,
      super(const TodosOverviewInitial()) {
    on<TodosOverviewRequested>(_onRequested);
    on<TodosOverviewTodosFilterChanged>(_onFilterChanged);
    // on<TodosOverviewTodosSearchChanged>(_onSearchChanged);
  }

  final TodosRepository _todosRepository;

  List<Todo>? visibleTodos;

  Future<void> _onRequested(
    TodosOverviewRequested event,
    Emitter<TodosOverviewState> emit,
  ) async {
    emit(const TodosOverviewLoading());

    try {
      final todos = await _todosRepository.getTodos();
      visibleTodos = todos;
      emit(
        TodosOverviewLoaded(
          todos: todos,
          filter: TodoFilter.all,
          searchQuery: '',
        ),
      );
    } catch (e) {
      emit(TodosOverviewFailure(e.toString()));
    }
  }

  Future<void> _onFilterChanged(
    TodosOverviewTodosFilterChanged event,
    Emitter<TodosOverviewState> emit,
  ) async {
    emit(const TodosOverviewListLoading());

    try {
      final filteredTodos = await _todosRepository.getFilteredTodos(
        event.filter.name.toLowerCase(),
      );
      visibleTodos = filteredTodos;
      emit(
        TodosOverviewLoaded(
          todos: filteredTodos,
          filter: event.filter,
          searchQuery: '',
        ),
      );
    } catch (e) {
      print(e.toString());
      emit(TodosOverviewFailure(e.toString()));
    }
  }
}
