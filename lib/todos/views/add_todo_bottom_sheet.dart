import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:taskflow_todo_app/todos/bloc/todos_bloc.dart';

class AddTodoBottomSheet extends StatefulWidget {
  const AddTodoBottomSheet({super.key});

  @override
  State<AddTodoBottomSheet> createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends State<AddTodoBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorText = 'Title is required.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    context.read<TodosOverviewBloc>().add(
      TodosOverviewTodoAddedRequested(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<TodosOverviewBloc, TodosOverviewState>(
      listenWhen: (previous, current) {
        if (previous is TodosOverviewLoaded && current is TodosOverviewLoaded) {
          return previous.actionStatus != current.actionStatus;
        }
        return false;
      },
      listener: (context, state) {
        if (state is! TodosOverviewLoaded) {
          return;
        }

        switch (state.actionStatus) {
          case TodosOverviewActionStatus.addSuccess:
            Navigator.of(context).pop(true);
            break;
          case TodosOverviewActionStatus.addFailure:
            if (mounted) {
              setState(() {
                _isSubmitting = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionError ?? 'Unable to add todo.'),
                ),
              );
            }
            break;
          case TodosOverviewActionStatus.idle:
          case TodosOverviewActionStatus.addInProgress:
            break;
        }
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'New task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.of(context).pop(false);
                          },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                enabled: !_isSubmitting,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Task title',
                  errorText: _errorText,
                ),
                onSubmitted: (_) {
                  if (!_isSubmitting) {
                    _submit();
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              Navigator.of(context).pop(false);
                            },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Add'),
                              ],
                            )
                          : const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
