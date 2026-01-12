import 'package:flutter/material.dart';

import 'package:taskflow_todo_app/theme/app_theme.dart';

class MyTaskFlowApp extends StatelessWidget {
  const MyTaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow - Todo App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
    );
  }
}
