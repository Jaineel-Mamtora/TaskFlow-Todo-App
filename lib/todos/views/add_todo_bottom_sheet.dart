import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:todos_repository/todos_repository.dart';

import 'package:taskflow_todo_app/todos/bloc/todos_bloc.dart';

Future<bool?> showAddTodoBottomSheet(
  BuildContext context, {
  Todo? todo,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) {
      return AddTodoBottomSheet(todo: todo);
    },
  );
}

class AddTodoBottomSheet extends StatefulWidget {
  const AddTodoBottomSheet({
    super.key,
    this.todo,
  });

  final Todo? todo;

  @override
  State<AddTodoBottomSheet> createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends State<AddTodoBottomSheet> {
  late final TextEditingController _controller;
  StreamSubscription<TodosOverviewState>? _subscription;
  String? _errorText;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.todo != null;

  @override
  void initState() {
    super.initState();
    // Prefill when editing an existing todo.
    _controller = TextEditingController(text: widget.todo?.title ?? '');
    _subscription = context.read<TodosOverviewBloc>().stream.listen(
      _handleBlocState,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
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

    if (_isEditMode) {
      // Update existing todo instead of creating a new one.
      context.read<TodosOverviewBloc>().add(
        TodosOverviewTodoUpdatedRequested(
          todo: widget.todo!,
          updatedTitle: title,
        ),
      );
    } else {
      context.read<TodosOverviewBloc>().add(
        TodosOverviewTodoAddedRequested(title),
      );
    }
  }

  void _handleBlocState(TodosOverviewState state) {
    if (!mounted || !_isSubmitting) {
      return;
    }
    if (state is! TodosOverviewLoaded) {
      return;
    }

    if (_isEditMode) {
      if (state.actionTodoId != widget.todo!.id) {
        return;
      }
      switch (state.actionStatus) {
        case TodosOverviewActionStatus.updateSuccess:
          Navigator.of(context).pop(true);
          break;
        case TodosOverviewActionStatus.updateFailure:
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionError ?? 'Unable to update todo.'),
            ),
          );
          break;
        case TodosOverviewActionStatus.idle:
        case TodosOverviewActionStatus.addInProgress:
        case TodosOverviewActionStatus.addSuccess:
        case TodosOverviewActionStatus.addFailure:
        case TodosOverviewActionStatus.updateInProgress:
          break;
      }
      return;
    }

    switch (state.actionStatus) {
      case TodosOverviewActionStatus.addSuccess:
        Navigator.of(context).pop(true);
        break;
      case TodosOverviewActionStatus.addFailure:
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.actionError ?? 'Unable to add todo.'),
          ),
        );
        break;
      case TodosOverviewActionStatus.idle:
      case TodosOverviewActionStatus.addInProgress:
      case TodosOverviewActionStatus.updateInProgress:
      case TodosOverviewActionStatus.updateSuccess:
      case TodosOverviewActionStatus.updateFailure:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditMode ? 'Edit task' : 'New task',
                    style: const TextStyle(
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
                              Text(_isEditMode ? 'Update' : 'Add'),
                            ],
                          )
                        : Text(_isEditMode ? 'Update' : 'Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
