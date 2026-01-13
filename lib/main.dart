import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:todo_api/todo_api.dart';
import 'package:todos_repository/todos_repository.dart';

import 'package:taskflow_todo_app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final todosApi = JsonPlaceholderApiClient(http.Client());

  runApp(
    MyTaskFlowApp(
      createTodosRepository: () => TodosRepository(todoApiClient: todosApi),
    ),
  );
}
