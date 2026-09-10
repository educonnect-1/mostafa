import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/search_result.dart';

/// Every query here hits a table already governed by the RLS policies
/// in schema.sql — group_messages, resources, announcements,
/// assignments, exams all restrict `select` to rows the signed-in
/// student can already see. There is no separate "is this search
/// result allowed" check needed or possible to bypass (spec §30 — "a
/// student must never receive search results from groups they do not
/// belong to").
///
/// Each sub-search fails independently and silently (returns an empty
/// list) rather than aborting the whole search, so one flaky category
/// doesn't blank out results the student could otherwise see.
class SearchRepository {
  SearchRepository(this._client);

  final SupabaseClient _client;

  Future<List<SearchResultItem>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];
    final pattern = '%$trimmed%';

    final results = await Future.wait([
      _searchMessages(pattern),
      _searchResources(pattern),
      _searchAnnouncements(pattern),
      _searchAssignments(pattern),
      _searchExams(pattern),
    ]);

    return results.expand((r) => r).toList();
  }

  Future<List<SearchResultItem>> _searchMessages(String pattern) async {
    try {
      final rows = await _client
          .from('group_messages')
          .select('id, content, group_id')
          .ilike('content', pattern)
          .limit(20);
      return (rows as List)
          .where((r) => r['content'] != null)
          .map((r) => SearchResultItem(
                type: SearchResultType.message,
                id: r['id'] as String,
                title: r['content'] as String,
                groupId: r['group_id'] as String,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SearchResultItem>> _searchResources(String pattern) async {
    try {
      final rows =
          await _client.from('resources').select('id, title').ilike('title', pattern).limit(20);
      return (rows as List)
          .map((r) => SearchResultItem(
                type: SearchResultType.resource,
                id: r['id'] as String,
                title: r['title'] as String,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SearchResultItem>> _searchAnnouncements(String pattern) async {
    try {
      final rows = await _client
          .from('announcements')
          .select('id, title, body')
          .or('title.ilike.$pattern,body.ilike.$pattern')
          .limit(20);
      return (rows as List)
          .map((r) => SearchResultItem(
                type: SearchResultType.announcement,
                id: r['id'] as String,
                title: r['title'] as String,
                subtitle: r['body'] as String?,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SearchResultItem>> _searchAssignments(String pattern) async {
    try {
      final rows = await _client
          .from('assignments')
          .select('id, title')
          .ilike('title', pattern)
          .limit(20);
      return (rows as List)
          .map((r) => SearchResultItem(
                type: SearchResultType.assignment,
                id: r['id'] as String,
                title: r['title'] as String,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SearchResultItem>> _searchExams(String pattern) async {
    try {
      final rows =
          await _client.from('exams').select('id, title').ilike('title', pattern).limit(20);
      return (rows as List)
          .map((r) => SearchResultItem(
                type: SearchResultType.exam,
                id: r['id'] as String,
                title: r['title'] as String,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(SupabaseConfig.client);
});
