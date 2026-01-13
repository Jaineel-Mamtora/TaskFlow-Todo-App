import 'package:json_annotation/json_annotation.dart';

part 'todo.g.dart';

@JsonSerializable()
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    this.pendingSync = false,
  });

  final int id;
  final String title;
  final bool completed;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool pendingSync;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);

  Map<String, dynamic> toJson() => _$TodoToJson(this);
}
