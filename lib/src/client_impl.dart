import 'package:dio/dio.dart';
import 'package:meilisearch/src/client_task_impl.dart';
import 'package:meilisearch/src/query_parameters/keys_query.dart';
import 'package:meilisearch/src/query_parameters/tasks_query.dart';
import 'package:meilisearch/src/result.dart';
import 'package:meilisearch/src/result_task.dart';
import 'package:meilisearch/src/task.dart';
import 'package:meilisearch/src/task_info.dart';
import 'package:meilisearch/src/tenant_token.dart';

import 'http_request.dart';
import 'http_request_impl.dart';

import 'client.dart';
import 'index.dart';
import 'index_impl.dart';
import 'key.dart';
import 'stats.dart' show AllStats;

class MeiliSearchClientImpl implements MeiliSearchClient {
  MeiliSearchClientImpl(this.serverUrl, [this.apiKey, this.connectTimeout])
      : http = HttpRequestImpl(serverUrl, apiKey, connectTimeout);

  @override
  final String serverUrl;

  @override
  final String? apiKey;

  @override
  final int? connectTimeout;

  final HttpRequest http;

  @override
  MeiliSearchIndex index(String uid) {
    return new MeiliSearchIndexImpl(this, uid);
  }

  Future<TaskInfo> _update(Future<Response> future) async {
    final response = await future;

    return ClientTaskImpl.fromMap(this, response.data);
  }

  @override
  Future<TaskInfo> createIndex(String uid, {String? primaryKey}) async {
    final data = <String, dynamic>{
      'uid': uid,
      if (primaryKey != null) 'primaryKey': primaryKey,
    };
    data.removeWhere((k, v) => v == null);

    return await _update(
        http.postMethod<Map<String, dynamic>>('/indexes', data: data));
  }

  @override
  Future<MeiliSearchIndex> getIndex(String uid) async {
    final response = await _getIndex(uid);

    return MeiliSearchIndexImpl.fromMap(this, response.data!);
  }

  @override
  Future<Map<String, dynamic>> getRawIndex(String uid) async {
    final response = await _getIndex(uid);

    return response.data!;
  }

  Future<Response<Map<String, dynamic>>> _getIndex(String uid) {
    return http.getMethod<Map<String, dynamic>>('/indexes/$uid');
  }

  @override
  Future<List<MeiliSearchIndex>> getIndexes() async {
    final response = await http.getMethod<List<dynamic>>('/indexes');

    return response.data!
        .cast<Map<String, dynamic>>()
        .map((item) => MeiliSearchIndexImpl.fromMap(this, item))
        .toList();
  }

  @override
  Future<TaskInfo> deleteIndex(String uid) async {
    final index = this.index(uid);

    return await index.delete();
  }

  @override
  Future<TaskInfo> updateIndex(String uid, String primaryKey) async {
    final index = this.index(uid);

    return index.update(primaryKey: primaryKey);
  }

  @override
  Future<Map<String, dynamic>> health() async {
    final response = await http.getMethod<Map<String, dynamic>>('/health');

    return response.data!;
  }

  @override
  Future<bool> isHealthy() async {
    try {
      await health();
    } on Exception catch (_) {
      return false;
    }
    return true;
  }

  @override
  Future<Task> createDump() async {
    final response = await http.postMethod('/dumps');

    return Task.fromMap(response.data);
  }

  @override
  Future<Result<Key>> getKeys({KeysQuery? params}) async {
    final response = await http.getMethod<Map<String, dynamic>>('/keys',
        queryParameters: params?.toQuery());

    return Result<Key>.fromMapWithType(
        response.data!, (model) => Key.fromJson(model));
  }

  @override
  Future<Key> getKey(String keyOrUid) async {
    final response = await http.getMethod<Map<String, dynamic>>('/keys/${keyOrUid}');

    return Key.fromJson(response.data!);
  }

  @override
  Future<Map<String, String>> getVersion() async {
    final response = await http.getMethod<Map<String, dynamic>>('/version');
    return response.data!.map((k, v) => MapEntry(k, v.toString()));
  }

  @override
  Future<AllStats> getStats() async {
    final response = await http.getMethod('/stats');

    return AllStats.fromMap(response.data);
  }

  @override
  Future<Key> createKey(
      {DateTime? expiresAt,
      String? description,
      required List<String> indexes,
      required List<String> actions}) async {
    final data = <String, dynamic>{
      'expiresAt': expiresAt?.toIso8601String().split('.').first,
      if (description != null) 'description': description,
      'indexes': indexes,
      'actions': actions,
    };

    final response =
        await http.postMethod<Map<String, dynamic>>('/keys', data: data);

    return Key.fromJson(response.data!);
  }

  @override
  Future<Key> updateKey(String key, {String? name, String? description}) async {
    final data = <String, dynamic>{
      if (description != null) 'description': description,
      if (name != null) 'name': name,
    };

    final response = await http
        .patchMethod<Map<String, dynamic>>('/keys/${key}', data: data);

    return Key.fromJson(response.data!);
  }

  @override
  Future<bool> deleteKey(String key) async {
    final response = await http.deleteMethod('/keys/${key}');

    return response.statusCode == 204;
  }

  @override
  String generateTenantToken(dynamic searchRules, String uid,
      {DateTime? expiresAt}) {
    return generateToken(searchRules, uid, expiresAt: expiresAt);
  }

  ///
  /// Tasks endpoints
  ///

  @override
  Future<ResultTask> getTasks({TasksQuery? params}) async {
    final response =
        await http.getMethod('/tasks', queryParameters: params?.toQuery());

    return ResultTask.fromMap(response.data);
  }

  @override
  Future<Task> getTask(int uid) async {
    final response = await http.getMethod(('/tasks/$uid'));

    return Task.fromMap(response.data);
  }
}
