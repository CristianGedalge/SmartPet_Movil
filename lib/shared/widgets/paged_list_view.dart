import 'package:flutter/material.dart';

import '../controllers/paged_list_controller.dart';
import 'app_widgets.dart';

class PagedListView<T> extends StatelessWidget {
  const PagedListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    required this.empty,
    this.header,
  });
  final PagedListController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget empty;
  final Widget? header;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      if (controller.loading && controller.items.isEmpty) {
        return const LoadingPanel();
      }
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (header != null) ...[header!, const SizedBox(height: 20)],
            if (controller.error != null) ...[
              ErrorPanel(
                message: controller.error!,
                onRetry: controller.pageError
                    ? controller.loadMore
                    : controller.refresh,
              ),
              const SizedBox(height: 16),
            ],
            if (controller.items.isEmpty && controller.error == null) empty,
            for (final item in controller.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: itemBuilder(context, item),
              ),
            if (controller.loadingMore ||
                (controller.loading && controller.items.isNotEmpty))
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (controller.hasMore &&
                controller.items.isNotEmpty &&
                !controller.loading &&
                !controller.loadingMore)
              OutlinedButton(
                onPressed: controller.loadMore,
                child: const Text('Cargar más'),
              ),
          ],
        ),
      );
    },
  );
}
