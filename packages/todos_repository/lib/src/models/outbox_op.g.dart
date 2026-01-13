// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_op.dart';

OutboxOp _$OutboxOpFromJson(Map<String, dynamic> json) => OutboxOp(
  opId: (json['opId'] as num?)?.toInt(),
  todoId: (json['todoId'] as num).toInt(),
  type: OutboxOpTypeX.fromJson(json['type'] as String),
  payload: json['payload'] as Map<String, dynamic>?,
  createdAt: (json['createdAt'] as num).toInt(),
  retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
  lastError: json['lastError'] as String?,
);

Map<String, dynamic> _$OutboxOpToJson(OutboxOp instance) => <String, dynamic>{
  'opId': instance.opId,
  'todoId': instance.todoId,
  'type': OutboxOpTypeX.toJson(instance.type),
  'payload': instance.payload,
  'createdAt': instance.createdAt,
  'retryCount': instance.retryCount,
  'lastError': instance.lastError,
};
