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

  Future<List<Todo>> getFilteredTodos(String filterName) async {
    var filter = <String, dynamic>{};

    switch (filterName.trim().toLowerCase()) {
      case 'completed':
        filter = {'completed': 'true'};
        break;
      case 'active':
        filter = {'completed': 'false'};
        break;
      default:
        filter = {};
    }

    final todosResponse = await _httpClient.get(
      Uri.https(
        _baseUrl,
        '/todos',
        filter,
      ),
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
      body: jsonEncode(todo),
      headers: {'Content-type': 'application/json'},
    );

    if (todosResponse.statusCode != 201) {
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
      body: jsonEncode(todo.toJson()),
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

  Future<Todo> updateTodoCompletion({
    required int id,
    required bool completed,
  }) async {
    final todosResponse = await _httpClient.patch(
      getTodosRequest('/todos/$id'),
      body: jsonEncode({'completed': completed}),
      headers: {'Content-type': 'application/json'},
    );

    if (todosResponse.statusCode != 200) {
      throw const TodoUpdationFailure('Unable to update todo.');
    }

    final todoJson = jsonDecode(todosResponse.body) as Map;

    if (!todoJson.containsKey('id')) {
      throw const TodoUpdationFailure('Unable to update todo.');
    }

    return Todo.fromJson(todoJson as Map<String, dynamic>);
  }

  Future<Todo> updateTodoTitle({
    required int id,
    required String title,
  }) async {
    final todosResponse = await _httpClient.patch(
      getTodosRequest('/todos/$id'),
      body: jsonEncode({'title': title}),
      headers: {'Content-type': 'application/json'},
    );

    if (todosResponse.statusCode != 200) {
      throw const TodoUpdationFailure('Unable to update todo.');
    }

    final todoJson = jsonDecode(todosResponse.body) as Map;

    if (!todoJson.containsKey('id')) {
      throw const TodoUpdationFailure('Unable to update todo.');
    }

    return Todo.fromJson(todoJson as Map<String, dynamic>);
  }

  Future<void> deleteTodo(int todoId) async {
    final todosResponse = await _httpClient.delete(
      getTodosRequest('/todos/$todoId'),
      headers: {'Content-type': 'application/json'},
    );

    if (todosResponse.statusCode != 200) {
      throw const TodosRequestFailure('Unable to delete todo.');
    }
  }
}
