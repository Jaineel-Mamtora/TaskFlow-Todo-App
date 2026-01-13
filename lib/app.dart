import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todos_repository/todos_repository.dart';

import 'package:taskflow_todo_app/home/views/home_page.dart';
import 'package:taskflow_todo_app/theme/app_theme.dart';

class MyTaskFlowApp extends StatelessWidget {
  const MyTaskFlowApp({
    required this.createTodosRepository,
    super.key,
  });

  final TodosRepository Function() createTodosRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<TodosRepository>(
      create: (_) => createTodosRepository(),
      child: const AppView(),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        title: 'TaskFlow - Todo App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme(),
        home: const HomePage(),
      ),
    );
  }
}
