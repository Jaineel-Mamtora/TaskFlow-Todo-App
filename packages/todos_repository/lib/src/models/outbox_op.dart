import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'outbox_op.g.dart';

enum OutboxOpType {
  create,
  updateTitle,
  toggle,
  delete,
}

extension OutboxOpTypeX on OutboxOpType {
  String get value {
    switch (this) {
      case OutboxOpType.create:
        return 'create';
      case OutboxOpType.updateTitle:
        return 'update_title';
      case OutboxOpType.toggle:
        return 'toggle';
      case OutboxOpType.delete:
        return 'delete';
    }
  }

  static OutboxOpType fromValue(String value) {
    switch (value) {
      case 'create':
        return OutboxOpType.create;
      case 'update_title':
        return OutboxOpType.updateTitle;
      case 'toggle':
        return OutboxOpType.toggle;
      case 'delete':
        return OutboxOpType.delete;
      default:
        throw ArgumentError.value(value, 'value', 'Unknown outbox type');
    }
  }

  static String toJson(OutboxOpType type) => type.value;

  static OutboxOpType fromJson(String value) => fromValue(value);
}

@JsonSerializable()
class OutboxOp {
  const OutboxOp({
    this.opId,
    required this.todoId,
    required this.type,
    this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  final int? opId;
  final int todoId;
  @JsonKey(fromJson: OutboxOpTypeX.fromJson, toJson: OutboxOpTypeX.toJson)
  final OutboxOpType type;
  final Map<String, dynamic>? payload;
  final int createdAt;
  final int retryCount;
  final String? lastError;

  factory OutboxOp.fromJson(Map<String, dynamic> json) =>
      _$OutboxOpFromJson(json);

  Map<String, dynamic> toJson() => _$OutboxOpToJson(this);

  Map<String, Object?> toMap() {
    return {
      'op_id': opId,
      'todo_id': todoId,
      'type': type.value,
      'payload': payload == null ? null : jsonEncode(payload),
      'created_at': createdAt,
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  factory OutboxOp.fromMap(Map<String, Object?> map) {
    final payloadValue = map['payload'];
    return OutboxOp(
      opId: map['op_id'] as int?,
      todoId: map['todo_id'] as int,
      type: OutboxOpTypeX.fromValue(map['type'] as String),
      payload: payloadValue == null
          ? null
          : jsonDecode(payloadValue as String) as Map<String, dynamic>,
      createdAt: map['created_at'] as int,
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  OutboxOp copyWith({
    int? opId,
    int? todoId,
    OutboxOpType? type,
    Map<String, dynamic>? payload,
    int? createdAt,
    int? retryCount,
    String? lastError,
  }) {
    return OutboxOp(
      opId: opId ?? this.opId,
      todoId: todoId ?? this.todoId,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }
}
