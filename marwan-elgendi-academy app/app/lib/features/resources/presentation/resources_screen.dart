import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/resource.dart';
import '../../../repositories/resource_repository.dart';

final myResourcesProvider = FutureProvider.autoDispose<List<Resource>>((ref) {
  return ref.read(resourceRepositoryProvider).getMyResources();
});

class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(myResourcesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myResourcesProvider.future),
        child: resourcesAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorRetryView(
            error: err,
            onRetry: () => ref.invalidate(myResourcesProvider),
          ),
          data: (resources) {
            if (resources.isEmpty) {
              return const EmptyView(
                icon: Icons.folder_open_outlined,
                title: 'No resources yet',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: resources.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _ResourceTile(resource: resources[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ResourceTile extends ConsumerStatefulWidget {
  const _ResourceTile({required this.resource});
  final Resource resource;

  @override
  ConsumerState<_ResourceTile> createState() => _ResourceTileState();
}

class _ResourceTileState extends ConsumerState<_ResourceTile> {
  bool _opening = false;

  Future<void> _open() async {
    setState(() => _opening = true);
    try {
      final url = await ref.read(resourceRepositoryProvider).getOpenUrl(widget.resource);
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this resource.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open this resource: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    return Card(
      child: ListTile(
        leading: Icon(_iconFor(resource.type), color: AppBrand.primary),
        title: Text(resource.title),
        subtitle: Text(_labelFor(resource.type)),
        trailing: _opening
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.open_in_new),
        onTap: _opening ? null : _open,
      ),
    );
  }

  IconData _iconFor(ResourceType type) {
    switch (type) {
      case ResourceType.pdf:
        return Icons.picture_as_pdf_outlined;
      case ResourceType.image:
        return Icons.image_outlined;
      case ResourceType.video:
        return Icons.videocam_outlined;
      case ResourceType.link:
        return Icons.link;
      case ResourceType.document:
        return Icons.description_outlined;
    }
  }

  String _labelFor(ResourceType type) {
    switch (type) {
      case ResourceType.pdf:
        return 'PDF document';
      case ResourceType.image:
        return 'Image';
      case ResourceType.video:
        return 'Video';
      case ResourceType.link:
        return 'External link';
      case ResourceType.document:
        return 'Document';
    }
  }
}
