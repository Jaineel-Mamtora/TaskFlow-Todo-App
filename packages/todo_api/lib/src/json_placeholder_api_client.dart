import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:todo_api/src/todo_exception.dart';
import 'package:todo_api/todo_api.dart';

class JsonPlaceholderApiClient {
  JsonPlaceholderApiClient(http.Client? httpClient)
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _baseUrl = 'jsonplaceholder.typicode.com';
  Uri getTodosRequest([String? path]) => Uri.https(
    _baseUrl,
    path ?? '/todos',
  );

  Future<List<Todo>> getTodos() async {
    final todosResponse = await _httpClient.get(
      getTodosRequest(),
      headers: {'Content-type': 'application/json'},
    );

    if (todosResponse.statusCode != 200) {
      throw const TodosRequestFailure(
        'Server is down. Please try after sometime.',
      );
    }

    final todosJson = jsonDecode(todosResponse.body) as List;

    if (todosJson.isEmpty) throw const TodosNotFoundFailure('No todos found!');

    return todosJson
        .map((todo) => Todo.fromJson(todo as Map<String, dynamic>))
        .toList();
  }

  Future<Todo> addTodo(Todo todo) async {
    final todosResponse = await _httpClient.post(
      getTodosRequest(),
      body: todo.toJson(),
      headers: {'Content-type': 'application/json'},
    );

    if (todosResponse.statusCode != 200) {
      throw const TodosRequestFailure(
        'Server is down. Please try after sometime.',
      );
    }

    final todoJson = jsonDecode(todosResponse.body) as Map;

    if (!todoJson.containsKey('id')) {
      throw const TodoCreationFailure('Unable to add todo.');
    }

    return Todo.fromJson(todoJson as Map<String, dynamic>);
  }

  Future<Todo> updateTodo(Todo todo) async {
    final todosResponse = await _httpClient.put(
      getTodosRequest('/todos/${todo.id}'),
      body: todo.toJson(),
      headers: {'Content-type': 'application/json'},
    );

    if (todosResponse.statusCode != 200) {
      throw const TodosRequestFailure(
        'Server is down. Please try after sometime.',
      );
    }

    final todoJson = jsonDecode(todosResponse.body) as Map;

    if (!todoJson.containsKey('id')) {
      throw const TodoCreationFailure('Unable to update todo.');
    }

    return Todo.fromJson(todoJson as Map<String, dynamic>);
  }

  Future<void> deleteTodo(String todoId) async {
    final todosResponse = await _httpClient.delete(
      getTodosRequest('/todos/$todoId'),
      headers: {'Content-type': 'application/json'},
    );

    if (todosResponse.statusCode != 200) {
      throw const TodosRequestFailure('Unable to delete todo.');
    }
  }
}
