import 'package:todo_api/todo_api.dart';

class TodosRepository {
  const TodosRepository({
    required JsonPlaceholderApiClient todoApiClient,
  }) : _todoApiClient = todoApiClient;

  final JsonPlaceholderApiClient _todoApiClient;

  Future<List<Todo>> getTodos() async => await _todoApiClient.getTodos();

  Future<void> saveTodo(Todo todo) async => await _todoApiClient.addTodo(todo);

  Future<Todo> updateTodo(Todo todo) async =>
      await _todoApiClient.updateTodo(todo);

  Future<void> deleteTodo(String todoId) async =>
      await _todoApiClient.deleteTodo(todoId);
}
