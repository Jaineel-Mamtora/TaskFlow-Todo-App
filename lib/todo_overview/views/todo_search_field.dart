import 'package:flutter/material.dart';

class TodoSearchField extends StatelessWidget {
  const TodoSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12.0,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search tasks…',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }
}
