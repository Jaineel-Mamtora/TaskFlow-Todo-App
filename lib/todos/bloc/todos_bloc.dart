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
    on<TodosOverviewSearchQueryChanged>(_onSearchQueryChanged);
    on<TodosOverviewTodoDeleted>(_onTodoDeleted);
    on<TodosOverviewTodoAddedRequested>(_onTodoAddedRequested);
    on<TodosOverviewTodoUpdatedRequested>(_onTodoUpdatedRequested);
    on<TodosOverviewTodoCompletionToggled>(_onTodoCompletionToggled);
  }

  final TodosRepository _todosRepository;

  Future<void> _onRequested(
    TodosOverviewRequested event,
    Emitter<TodosOverviewState> emit,
  ) async {
    emit(const TodosOverviewLoading());

    try {
      final todos = await _todosRepository.getTodos();
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
    final currentState = state;
    if (currentState is! TodosOverviewLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        filter: event.filter,
      ),
    );
  }

  void _onSearchQueryChanged(
    TodosOverviewSearchQueryChanged event,
    Emitter<TodosOverviewState> emit,
  ) {
    final currentState = state;
    if (currentState is! TodosOverviewLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        searchQuery: event.query,
      ),
    );
  }

  Future<void> _onTodoDeleted(
    TodosOverviewTodoDeleted event,
    Emitter<TodosOverviewState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TodosOverviewLoaded) {
      return;
    }

    final updatedTodos = List<Todo>.from(currentState.todos)
      ..removeWhere((todo) => todo.id == event.todo.id);
    emit(
      currentState.copyWith(todos: updatedTodos),
    );

    try {
      await _todosRepository.deleteTodo(event.todo.id);
    } catch (e) {
      emit(TodosOverviewFailure(e.toString()));
    }
  }

  Future<void> _onTodoAddedRequested(
    TodosOverviewTodoAddedRequested event,
    Emitter<TodosOverviewState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TodosOverviewLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        actionStatus: TodosOverviewActionStatus.addInProgress,
        actionError: null,
        actionTodoId: null,
      ),
    );

    try {
      final createdTodo = await _todosRepository.createTodo(event.title);
      final updatedTodos = List<Todo>.from(currentState.todos)
        ..insert(0, createdTodo);
      emit(
        currentState.copyWith(
          todos: updatedTodos,
          actionStatus: TodosOverviewActionStatus.addSuccess,
          actionError: null,
          actionTodoId: null,
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          actionStatus: TodosOverviewActionStatus.addFailure,
          actionError: e.toString(),
          actionTodoId: null,
        ),
      );
    }
  }

  Future<void> _onTodoUpdatedRequested(
    TodosOverviewTodoUpdatedRequested event,
    Emitter<TodosOverviewState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TodosOverviewLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        actionStatus: TodosOverviewActionStatus.updateInProgress,
        actionError: null,
        actionTodoId: event.todo.id,
      ),
    );

    try {
      final patchedTodo = await _todosRepository.updateTodoTitle(
        id: event.todo.id,
        title: event.updatedTitle,
      );
      final finalizedTodos = currentState.todos
          .map((todo) => todo.id == patchedTodo.id ? patchedTodo : todo)
          .toList();
      emit(
        currentState.copyWith(
          todos: finalizedTodos,
          actionStatus: TodosOverviewActionStatus.updateSuccess,
          actionError: null,
          actionTodoId: event.todo.id,
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          actionStatus: TodosOverviewActionStatus.updateFailure,
          actionError: e.toString(),
          actionTodoId: event.todo.id,
        ),
      );
    }
  }

  Future<void> _onTodoCompletionToggled(
    TodosOverviewTodoCompletionToggled event,
    Emitter<TodosOverviewState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TodosOverviewLoaded) {
      return;
    }

    final updatingIds = Set<int>.from(currentState.updatingTodoIds)
      ..add(event.todo.id);
    emit(
      currentState.copyWith(
        updatingTodoIds: updatingIds,
      ),
    );

    try {
      final patchedTodo = await _todosRepository.updateTodoCompletion(
        id: event.todo.id,
        completed: event.completed,
      );
      final finalizedTodos = currentState.todos
          .map((todo) => todo.id == patchedTodo.id ? patchedTodo : todo)
          .toList();
      final updatedIds = Set<int>.from(updatingIds)..remove(event.todo.id);
      emit(
        currentState.copyWith(
          todos: finalizedTodos,
          updatingTodoIds: updatedIds,
          completionError: null,
        ),
      );
    } catch (e) {
      final updatedIds = Set<int>.from(updatingIds)..remove(event.todo.id);
      emit(
        currentState.copyWith(
          updatingTodoIds: updatedIds,
          completionError: e.toString(),
        ),
      );
    }
  }
}
