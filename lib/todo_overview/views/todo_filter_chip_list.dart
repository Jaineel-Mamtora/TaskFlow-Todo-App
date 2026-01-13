import 'package:flutter/material.dart';

class TodoFilterChipList extends StatelessWidget {
  const TodoFilterChipList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: true,
            onSelected: (_) {},
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Active'),
            selected: false,
            onSelected: (_) {},
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Completed'),
            selected: false,
            onSelected: (_) {},
          ),
        ],
      ),
    );
  }
}
