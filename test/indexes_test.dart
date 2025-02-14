import 'package:meilisearch/meilisearch.dart';
import 'package:test/test.dart';

import 'utils/client.dart';
import 'utils/wait_for.dart';

void main() {
  group('Indexes', () {
    setUpClient();

    test('Create index with right UID without any primary passed', () async {
      final uid = randomUid();
      await client.createIndex(uid).waitFor(client: client);
      final index = await client.getIndex(uid);
      expect(index.uid, uid);
      expect(index.primaryKey, null);
    });

    test('Create index with right UID with a primary', () async {
      final uid = randomUid();
      await client.createIndex(uid, primaryKey: 'myId').waitFor(client: client);
      final index = await client.getIndex(uid);
      expect(index.uid, uid);
      expect(index.primaryKey, 'myId');
    });

    test('Update an index where the primary has not been set', () async {
      final uid = randomUid();
      await client.createIndex(uid).waitFor(client: client);

      var index = await client.getIndex(uid);
      await index.update(primaryKey: 'nextId').waitFor(client: client);
      index = await client.getIndex(uid);

      expect(index.primaryKey, equals('nextId'));
    });

    test('Update an index from the client where the primary has not been set',
        () async {
      final uid = randomUid();
      await client.createIndex(uid).waitFor(client: client);
      await client.updateIndex(uid, 'nextId').waitFor(client: client);
      final index = await client.getIndex(uid);
      expect(index.primaryKey, equals('nextId'));
    });

    test('Delete an existing index', () async {
      final uid = randomUid();
      await client.createIndex(uid).waitFor(client: client);

      final index = await client.getIndex(uid);
      await index.delete().waitFor(client: client);

      expect(client.getIndex(uid), throwsA(isA<MeiliSearchApiException>()));
    });

    test('Delete index with right UID from the client', () async {
      final uid = randomUid();
      await client.createIndex(uid).waitFor(client: client);
      await client.deleteIndex(uid).waitFor(client: client);

      expect(client.getIndex(uid), throwsA(isA<MeiliSearchApiException>()));
    });

    test('Get an existing index', () async {
      final uid = randomUid();
      await client.createIndex(uid).waitFor(client: client);
      var index = await client.getIndex(uid);
      expect(index.uid, uid);
      expect(index.primaryKey, null);
    });

    test('gets raw information about an index', () async {
      final uid = randomUid();
      await client.createIndex(uid).waitFor(client: client);

      final index = await client.getRawIndex(uid);
      final keys = ['uid', 'primaryKey', 'createdAt', 'updatedAt'];

      expect(index.keys, containsAll(keys));
      expect(index.keys.length, keys.length);
      expect(index['primaryKey'], isNull);
    });

    test('throws exception with a non-existing index', () async {
      expect(client.getIndex(randomUid('loremIpsum')),
          throwsA(isA<MeiliSearchApiException>()));
    });

    test('Get all indexes', () async {
      await client.createIndex(randomUid()).waitFor(client: client);
      await client.createIndex(randomUid()).waitFor(client: client);
      await client.createIndex(randomUid()).waitFor(client: client);
      var response = await client.getIndexes();
      expect(response.total, 3);
    });

    test('Create index object with UID', () async {
      final uid = randomUid();
      final index = client.index(uid);
      expect(index.uid, uid);
      expect(index.primaryKey, null);
    });

    test('Create index object with UID and add Document', () async {
      final uid = randomUid();
      var index = client.index(uid);
      final response = await index.addDocuments([
        {'book_id': 123, 'title': 'Pride and Prejudice'}
      ]).waitFor(client: client);
      expect(response.status, 'succeeded');
      index = await client.getIndex(uid);
      expect(index.uid, uid);
    });

    test('Create index object and get it without add it', () async {
      final uid = randomUid();
      client.index(uid);
      expect(client.getIndex(randomUid(uid)),
          throwsA(isA<MeiliSearchApiException>()));
    });

    test('Geting index stats', () async {
      final uid = randomUid();
      final index = client.index(uid);
      final response = await index.addDocuments([
        {'book_id': 123, 'title': 'Pride and Prejudice'},
        {'book_id': 456, 'title': 'The Martin'},
      ]).waitFor(client: client);
      expect(response.status, 'succeeded');
      final stats = await index.getStats();
      expect(stats.numberOfDocuments, 2);
    });

    test('gets all tasks by index', () async {
      final uid = randomUid();
      await client.createIndex(uid).waitFor(client: client);
      final index = await client.getIndex(uid);

      await index.addDocuments([
        {'book_id': 1234, 'title': 'Pride and Prejudice'}
      ]);
      await index.addDocuments([
        {'book_id': 5678}
      ]);

      final tasks = await index.getTasks();

      expect(tasks.results.length, equals(3));
    });

    test('gets a task from a index by taskId', () async {
      final index = client.index(randomUid());
      final response = await index.addDocuments([
        {'book_id': 1234, 'title': 'Pride and Prejudice'}
      ]);

      final task = await index.getTask(response.uid!);

      expect(task.uid, response.uid!);
    });

    test('gets a task with a failure', () async {
      final index = client.index(randomUid());

      expect(() async => await index.updateRankingRules(['invalid-rule']),
          throwsA(isA<MeiliSearchApiException>()));
    });

    test('Getting non-existant update status', () async {
      final uid = randomUid();
      await client.createIndex(uid).waitFor(client: client);
      final index = await client.getIndex(uid);

      expect(() async => await index.getTask(9999),
          throwsA(isA<MeiliSearchApiException>()));
    });

    test('extracts all possible properties from task', () async {
      final uid = randomUid();
      final task = await client.createIndex(uid);

      expect(task.uid, greaterThan(0));
      expect(task.indexUid, equals(uid));
      expect(task.type, equals("indexCreation"));
    });
  });
}
