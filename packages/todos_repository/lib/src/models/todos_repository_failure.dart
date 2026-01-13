class TodosRepositoryFailure implements Exception {
  const TodosRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
