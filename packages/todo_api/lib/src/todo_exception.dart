class TodosRequestFailure implements Exception {
  const TodosRequestFailure([this.message]);

  final String? message;

  @override
  String toString() {
    return message ?? super.toString();
  }
}

class TodosNotFoundFailure implements Exception {
  const TodosNotFoundFailure([this.message]);

  final String? message;

  @override
  String toString() {
    return message ?? super.toString();
  }
}

class TodoCreationFailure implements Exception {
  const TodoCreationFailure([this.message]);

  final String? message;

  @override
  String toString() {
    return message ?? super.toString();
  }
}

class TodoUpdationFailure implements Exception {
  const TodoUpdationFailure([this.message]);

  final String? message;

  @override
  String toString() {
    return message ?? super.toString();
  }
}
