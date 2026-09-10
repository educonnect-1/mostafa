import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/exception_mapper.dart';
import '../models/resource.dart';
import '../services/storage_service.dart';

/// RLS (`resources_select_member_or_teacher` in schema.sql) already
/// scopes results to resources belonging to one of the student's groups.
class ResourceRepository {
  ResourceRepository(this._client, this._storageService);

  final SupabaseClient _client;
  final StorageService _storageService;

  Future<List<Resource>> getMyResources() {
    return runGuarded(() async {
      final rows =
          await _client.from('resources').select().order('created_at', ascending: false);
      return (rows as List).map((r) => Resource.fromJson(r as Map<String, dynamic>)).toList();
    });
  }

  Future<String> getOpenUrl(Resource resource) {
    if (resource.type == ResourceType.link) {
      return Future.value(resource.externalUrl!);
    }
    return _storageService.getSignedUrl(bucket: 'resources', path: resource.storagePath!);
  }
}

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return ResourceRepository(SupabaseConfig.client, ref.read(storageServiceProvider));
});
