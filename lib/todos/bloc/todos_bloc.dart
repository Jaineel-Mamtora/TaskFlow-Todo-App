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
    on<TodosOverviewTodoDeleted>(_onTodoDeleted);
    on<TodosOverviewTodoAddedRequested>(_onTodoAddedRequested);
    on<TodosOverviewTodoCompletionToggled>(_onTodoCompletionToggled);
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
    visibleTodos = updatedTodos;
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
      ),
    );

    try {
      final createdTodo = await _todosRepository.createTodo(event.title);
      final updatedTodos = List<Todo>.from(currentState.todos)
        ..insert(0, createdTodo);
      visibleTodos = updatedTodos;
      emit(
        currentState.copyWith(
          todos: updatedTodos,
          actionStatus: TodosOverviewActionStatus.addSuccess,
          actionError: null,
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          actionStatus: TodosOverviewActionStatus.addFailure,
          actionError: e.toString(),
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

    final updatedTodos = currentState.todos
        .map(
          (todo) => todo.id == event.todo.id
              ? Todo(
                  id: todo.id,
                  title: todo.title,
                  completed: event.completed,
                )
              : todo,
        )
        .toList();
    final updatingIds = Set<int>.from(currentState.updatingTodoIds)
      ..add(event.todo.id);
    visibleTodos = updatedTodos;
    emit(
      currentState.copyWith(
        todos: updatedTodos,
        updatingTodoIds: updatingIds,
      ),
    );

    try {
      final patchedTodo = await _todosRepository.updateTodoCompletion(
        id: event.todo.id,
        completed: event.completed,
      );
      final finalizedTodos = updatedTodos
          .map((todo) => todo.id == patchedTodo.id ? patchedTodo : todo)
          .toList();
      final updatedIds = Set<int>.from(updatingIds)..remove(event.todo.id);
      visibleTodos = finalizedTodos;
      emit(
        currentState.copyWith(
          todos: finalizedTodos,
          updatingTodoIds: updatedIds,
          completionError: null,
        ),
      );
    } catch (e) {
      final revertedTodos = updatedTodos
          .map(
            (todo) => todo.id == event.todo.id
                ? Todo(
                    id: todo.id,
                    title: todo.title,
                    completed: !event.completed,
                  )
                : todo,
          )
          .toList();
      final updatedIds = Set<int>.from(updatingIds)..remove(event.todo.id);
      visibleTodos = revertedTodos;
      emit(
        currentState.copyWith(
          todos: revertedTodos,
          updatingTodoIds: updatedIds,
          completionError: e.toString(),
        ),
      );
    }
  }
}
