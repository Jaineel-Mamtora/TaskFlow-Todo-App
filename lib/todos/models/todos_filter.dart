enum TodoFilter { all, active, completed }

extension TodoFilterX on TodoFilter {
  String get label => switch (this) {
    TodoFilter.all => 'All',
    TodoFilter.active => 'Active',
    TodoFilter.completed => 'Completed',
  };
}
