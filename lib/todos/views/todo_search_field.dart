import 'package:flutter/material.dart';

class TodoSearchField extends StatelessWidget {
  const TodoSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextField(
      decoration: InputDecoration(
        hintText: 'Search tasks…',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}
