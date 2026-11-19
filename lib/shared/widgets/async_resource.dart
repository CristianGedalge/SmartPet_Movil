import 'package:flutter/material.dart';

import '../utils/error_message.dart';
import 'app_widgets.dart';

class AsyncResource<T extends Object> extends StatefulWidget {
  const AsyncResource({super.key, required this.load, required this.builder});
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, VoidCallback reload)
  builder;
  @override
  State<AsyncResource<T>> createState() => _AsyncResourceState<T>();
}

class _AsyncResourceState<T extends Object> extends State<AsyncResource<T>> {
  late Future<T> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void _reload() => setState(() => _future = widget.load());
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const LoadingPanel();
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ErrorPanel(
              message: userErrorMessage(
                snapshot.error,
                fallback:
                    'No pudimos cargar la información. Intenta nuevamente.',
              ),
              onRetry: _reload,
            ),
          ),
        );
      }
      return widget.builder(context, snapshot.requireData, _reload);
    },
  );
}
