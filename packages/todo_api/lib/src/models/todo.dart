import 'package:json_annotation/json_annotation.dart';

part 'todo.g.dart';

@JsonSerializable()
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
  });

  final int id;
  final String title;
  final bool completed;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);

  Map<String, dynamic> toJson() => _$TodoToJson(this);
}
