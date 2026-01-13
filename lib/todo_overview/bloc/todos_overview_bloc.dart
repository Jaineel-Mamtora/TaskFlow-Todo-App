import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:todos_repository/todos_repository.dart';

part 'todos_overview_event.dart';
part 'todos_overview_state.dart';

class TodosOverviewBloc extends Bloc<TodosOverviewEvent, TodosOverviewState> {
  TodosOverviewBloc({required TodosRepository todoRepository})
    : _todosRepository = todoRepository,
      super(const TodosOverviewInitial()) {
    on<TodosOverviewRequested>(_onRequested);
    // on<TodosOverviewTodosFilterChanged>(_onFilterChanged);
    // on<TodosOverviewTodosSearchChanged>(_onSearchChanged);
  }

  final TodosRepository _todosRepository;

  Future<void> _onRequested(
    TodosOverviewRequested event,
    Emitter<TodosOverviewState> emit,
  ) async {
    emit(const TodosOverviewLoading());

    try {
      final todos = await _todosRepository.getTodos();
      emit(TodosOverviewLoaded(todos: todos));
    } catch (e) {
      emit(TodosOverviewFailure(e.toString()));
    }
  }
}
