import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/search_result.dart';
import '../../../repositories/search_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<SearchResultItem>? _results;
  bool _loading = false;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _query = value;
    if (value.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(value));
  }

  Future<void> _runSearch(String value) async {
    setState(() => _loading = true);
    final results = await ref.read(searchRepositoryProvider).search(value);
    if (!mounted || value != _query) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Search messages, resources, assignments...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_query.trim().length < 2) {
      return const EmptyView(
        icon: Icons.search,
        title: 'Search your groups',
        subtitle: 'Find messages, resources, announcements, assignments, and exams.',
      );
    }
    if (_loading) return const LoadingView();
    if (_results == null || _results!.isEmpty) {
      return const EmptyView(icon: Icons.search_off, title: 'No results found');
    }

    final byType = <SearchResultType, List<SearchResultItem>>{};
    for (final r in _results!) {
      byType.putIfAbsent(r.type, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final type in SearchResultType.values)
          if (byType[type] != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(_sectionLabel(type), style: Theme.of(context).textTheme.titleSmall),
            ),
            ...byType[type]!.map((r) => _ResultTile(item: r)),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  String _sectionLabel(SearchResultType type) {
    switch (type) {
      case SearchResultType.message:
        return 'Messages';
      case SearchResultType.resource:
        return 'Resources';
      case SearchResultType.announcement:
        return 'Announcements';
      case SearchResultType.assignment:
        return 'Assignments';
      case SearchResultType.exam:
        return 'Exams';
    }
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.item});
  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(_iconFor(item.type), color: AppBrand.primary),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: item.subtitle != null
            ? Text(item.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        onTap: () => _navigate(context, item),
      ),
    );
  }

  IconData _iconFor(SearchResultType type) {
    switch (type) {
      case SearchResultType.message:
        return Icons.chat_bubble_outline;
      case SearchResultType.resource:
        return Icons.folder_open_outlined;
      case SearchResultType.announcement:
        return Icons.campaign_outlined;
      case SearchResultType.assignment:
        return Icons.assignment_outlined;
      case SearchResultType.exam:
        return Icons.quiz_outlined;
    }
  }

  void _navigate(BuildContext context, SearchResultItem item) {
    switch (item.type) {
      case SearchResultType.message:
        if (item.groupId != null) context.push('/groups/${item.groupId}/chat');
        break;
      case SearchResultType.resource:
        context.push('/resources');
        break;
      case SearchResultType.announcement:
        context.push('/announcements');
        break;
      case SearchResultType.assignment:
        context.push('/assignments/${item.id}');
        break;
      case SearchResultType.exam:
        context.push('/exams/${item.id}');
        break;
    }
  }
}
