import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class OfflineAction {
  final String id;
  final String url;
  final String method;
  final dynamic body;
  final Map<String, String>? headers;
  final DateTime createdAt;

  OfflineAction({
    required this.id,
    required this.url,
    required this.method,
    this.body,
    this.headers,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'method': method,
        'body': body,
        'headers': headers,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
        id: json['id'],
        url: json['url'],
        method: json['method'],
        body: json['body'],
        headers: json['headers'] != null
            ? Map<String, String>.from(json['headers'])
            : null,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class OfflineQueueService {
  static const String boxName = 'offline_queue';
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  Future<void> queueAction({
    required String url,
    required String method,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final box = await Hive.openBox(boxName);
    final action = OfflineAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      method: method,
      body: body,
      headers: headers,
      createdAt: DateTime.now(),
    );
    await box.add(jsonEncode(action.toJson()));
    debugPrint("📦 Action queued: $method $url");
  }

  Future<List<OfflineAction>> getPendingActions() async {
    final box = await Hive.openBox(boxName);
    return box.values
        .map((e) => OfflineAction.fromJson(jsonDecode(e as String)))
        .toList();
  }

  Future<void> removeAction(String id) async {
    final box = await Hive.openBox(boxName);
    final index = box.values
        .toList()
        .indexWhere((e) => OfflineAction.fromJson(jsonDecode(e)).id == id);
    if (index != -1) {
      await box.deleteAt(index);
    }
  }

  Future<int> get queueLength async {
    final box = await Hive.openBox(boxName);
    return box.length;
  }
}
