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
    on<_TodosOverviewTodosUpdated>(_onTodosUpdated);
    on<_TodosOverviewConnectivityChanged>(_onConnectivityChanged);
    on<_TodosOverviewSyncStatusChanged>(_onSyncStatusChanged);
    on<_TodosOverviewRefreshFailed>(_onRefreshFailed);
    on<_TodosOverviewInitialRefreshFinished>(_onInitialRefreshFinished);
    on<TodosOverviewTodosFilterChanged>(_onFilterChanged);
    on<TodosOverviewSearchQueryChanged>(_onSearchQueryChanged);
    on<TodosOverviewTodoDeleted>(_onTodoDeleted);
    on<TodosOverviewTodoAddedRequested>(_onTodoAddedRequested);
    on<TodosOverviewTodoUpdatedRequested>(_onTodoUpdatedRequested);
    on<TodosOverviewTodoCompletionToggled>(_onTodoCompletionToggled);
  }

  final TodosRepository _todosRepository;
  StreamSubscription<List<Todo>>? _todosSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<SyncStatus>? _syncStatusSubscription;
  bool _isOffline = false;
  SyncStatus _syncStatus = SyncStatus.idle;
  bool _initialRefreshPending = true;
  List<Todo> _latestTodos = const [];

  Future<void> _onRequested(
    TodosOverviewRequested event,
    Emitter<TodosOverviewState> emit,
  ) async {
    _initialRefreshPending = true;
    _latestTodos = const [];
    emit(const TodosOverviewListLoading());

    await _todosSubscription?.cancel();
    _todosSubscription = _todosRepository.watchTodos().listen(
      (todos) => add(_TodosOverviewTodosUpdated(todos)),
      onError: (error) => add(_TodosOverviewRefreshFailed(_mapError(error))),
    );

    await _syncStatusSubscription?.cancel();
    _syncStatusSubscription = _todosRepository.watchSyncStatus().listen(
      (status) => add(_TodosOverviewSyncStatusChanged(status)),
    );

    await _connectivitySubscription?.cancel();
    _connectivitySubscription = _todosRepository.watchOnlineStatus().listen(
      (isOnline) {
        add(_TodosOverviewConnectivityChanged(isOnline));
        if (isOnline) {
          unawaited(_todosRepository.syncOutbox());
          unawaited(
            _todosRepository.refreshFromNetwork().catchError(
              (error) => add(_TodosOverviewRefreshFailed(_mapError(error))),
            ),
          );
        }
      },
    );

    await _todosRepository.loadFromCache();
    final isOnline = await _todosRepository.isOnline();
    add(_TodosOverviewConnectivityChanged(isOnline));
    if (!isOnline) {
      add(const _TodosOverviewInitialRefreshFinished());
      return;
    }
    unawaited(
      _todosRepository
          .refreshFromNetwork()
          .timeout(const Duration(seconds: 10))
          .catchError(
            (error) => add(_TodosOverviewRefreshFailed(_mapError(error))),
          )
          .whenComplete(
            () => add(const _TodosOverviewInitialRefreshFinished()),
          ),
    );
  }

  void _onTodosUpdated(
    _TodosOverviewTodosUpdated event,
    Emitter<TodosOverviewState> emit,
  ) {
    _latestTodos = event.todos;
    if (event.todos.isEmpty && _initialRefreshPending) {
      emit(const TodosOverviewListLoading());
      return;
    }
    final currentState = state;
    if (currentState is TodosOverviewLoaded) {
      emit(currentState.copyWith(todos: event.todos));
      return;
    }

    emit(
      TodosOverviewLoaded(
        todos: event.todos,
        filter: TodoFilter.all,
        searchQuery: '',
        isOffline: _isOffline,
        syncStatus: _syncStatus,
      ),
    );
  }

  void _onInitialRefreshFinished(
    _TodosOverviewInitialRefreshFinished event,
    Emitter<TodosOverviewState> emit,
  ) {
    _initialRefreshPending = false;
    if (state is TodosOverviewLoaded) {
      return;
    }
    emit(
      TodosOverviewLoaded(
        todos: _latestTodos,
        filter: TodoFilter.all,
        searchQuery: '',
        isOffline: _isOffline,
        syncStatus: _syncStatus,
      ),
    );
  }

  void _onConnectivityChanged(
    _TodosOverviewConnectivityChanged event,
    Emitter<TodosOverviewState> emit,
  ) {
    _isOffline = !event.isOnline;
    final currentState = state;
    if (currentState is TodosOverviewLoaded) {
      emit(currentState.copyWith(isOffline: _isOffline));
    }
  }

  void _onSyncStatusChanged(
    _TodosOverviewSyncStatusChanged event,
    Emitter<TodosOverviewState> emit,
  ) {
    _syncStatus = event.status;
    final currentState = state;
    if (currentState is TodosOverviewLoaded) {
      emit(currentState.copyWith(syncStatus: event.status));
    }
  }

  void _onRefreshFailed(
    _TodosOverviewRefreshFailed event,
    Emitter<TodosOverviewState> emit,
  ) {
    final currentState = state;
    if (currentState is TodosOverviewLoaded) {
      emit(currentState.copyWith(infoMessage: event.message));
    } else {
      emit(TodosOverviewFailure(event.message));
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

    try {
      await _todosRepository.deleteTodo(event.todo.id);
    } catch (error) {
      emit(currentState.copyWith(infoMessage: _mapError(error)));
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
      await _todosRepository.addTodo(event.title);
      emit(
        currentState.copyWith(
          actionStatus: TodosOverviewActionStatus.addSuccess,
          actionError: null,
          actionTodoId: null,
        ),
      );
    } catch (error) {
      emit(
        currentState.copyWith(
          actionStatus: TodosOverviewActionStatus.addFailure,
          actionError: _mapError(error),
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
      await _todosRepository.updateTodoTitle(
        event.todo.id,
        event.updatedTitle,
      );
      emit(
        currentState.copyWith(
          actionStatus: TodosOverviewActionStatus.updateSuccess,
          actionError: null,
          actionTodoId: event.todo.id,
        ),
      );
    } catch (error) {
      emit(
        currentState.copyWith(
          actionStatus: TodosOverviewActionStatus.updateFailure,
          actionError: _mapError(error),
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
      final updatedIds = Set<int>.from(updatingIds)..remove(event.todo.id);
      await _todosRepository.toggleTodoCompletion(
        event.todo.id,
        event.completed,
      );
      emit(
        currentState.copyWith(
          updatingTodoIds: updatedIds,
          completionError: null,
        ),
      );
    } catch (error) {
      final updatedIds = Set<int>.from(updatingIds)..remove(event.todo.id);
      emit(
        currentState.copyWith(
          updatingTodoIds: updatedIds,
          completionError: _mapError(error),
        ),
      );
    }
  }

  String _mapError(Object error) {
    if (error is TodosRepositoryFailure) {
      return error.message;
    }
    return error.toString();
  }

  @override
  Future<void> close() async {
    await _todosSubscription?.cancel();
    await _connectivitySubscription?.cancel();
    await _syncStatusSubscription?.cancel();
    return super.close();
  }
}
