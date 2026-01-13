import 'dart:math';

import 'package:todo_api/todo_api.dart';

class TodosRepository {
  const TodosRepository({
    required JsonPlaceholderApiClient todoApiClient,
  }) : _todoApiClient = todoApiClient;

  final JsonPlaceholderApiClient _todoApiClient;

  Future<List<Todo>> getTodos() async => await _todoApiClient.getTodos();

  Future<List<Todo>> getFilteredTodos(String filterName) async =>
      await _todoApiClient.getFilteredTodos(filterName);

  Future<Todo> createTodo(String title) async {
    final todo = Todo(
      id: Random().nextInt(1000) + 400,
      title: title,
      completed: false,
    );
    return await _todoApiClient.addTodo(todo);
  }

  Future<Todo> updateTodo(Todo todo) async =>
      await _todoApiClient.updateTodo(todo);

  Future<Todo> updateTodoCompletion({
    required int id,
    required bool completed,
  }) async {
    return await _todoApiClient.updateTodoCompletion(
      id: id,
      completed: completed,
    );
  }

  Future<Todo> updateTodoTitle({
    required int id,
    required String title,
  }) async => await _todoApiClient.updateTodoTitle(
    id: id,
    title: title,
  );

  Future<void> deleteTodo(int todoId) async =>
      await _todoApiClient.deleteTodo(todoId);
}
