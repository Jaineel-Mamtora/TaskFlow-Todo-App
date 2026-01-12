import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:todo_api/todo_api.dart';

class TodosRequestFailure implements Exception {}

class TodosNotFoundFailure implements Exception {}

class JsonPlaceholderApiClient {
  JsonPlaceholderApiClient(http.Client? httpClient)
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _baseUrl = 'jsonplaceholder.typicode.com';

  Future<List<Todo>> getTodos() async {
    final todosRequest = Uri.https(
      _baseUrl,
      '/todos',
      {'userId': 1},
    );

    final todosResponse = await _httpClient.get(todosRequest);

    if (todosResponse.statusCode != 200) {
      throw TodosRequestFailure();
    }

    final todosJson = jsonDecode(todosResponse.body) as List;

    if (todosJson.isEmpty) throw TodosNotFoundFailure();

    return todosJson
        .map((todo) => Todo.fromJson(todo as Map<String, dynamic>))
        .toList();
  }
}
