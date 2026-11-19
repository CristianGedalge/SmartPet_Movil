import 'package:flutter/foundation.dart';

import '../utils/error_message.dart';

class PagedListController<T> extends ChangeNotifier {
  PagedListController({required this.fetchPage, this.pageSize = 10});
  final Future<List<T>> Function(int limit, int offset) fetchPage;
  final int pageSize;
  List<T> items = [];
  bool loading = false, loadingMore = false, hasMore = true;
  String? error;
  bool pageError = false;
  int _generation = 0;
  bool _disposed = false;

  Future<void> refresh() async {
    if (_disposed) return;
    final generation = ++_generation;
    loading = true;
    loadingMore = false;
    error = null;
    pageError = false;
    notifyListeners();
    try {
      final next = await fetchPage(pageSize, 0);
      if (_disposed || generation != _generation) return;
      items = List.unmodifiable(next);
      hasMore = next.length == pageSize;
    } catch (failure) {
      if (_disposed || generation != _generation) return;
      error = userErrorMessage(
        failure,
        fallback: 'No pudimos cargar la información. Intenta nuevamente.',
      );
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore || _disposed) return;
    final generation = _generation;
    loadingMore = true;
    error = null;
    notifyListeners();
    try {
      final next = await fetchPage(pageSize, items.length);
      if (_disposed || generation != _generation) return;
      items = List.unmodifiable([...items, ...next]);
      hasMore = next.length == pageSize;
    } catch (failure) {
      if (_disposed || generation != _generation) return;
      error = userErrorMessage(
        failure,
        fallback: 'No pudimos cargar más resultados. Intenta nuevamente.',
      );
      pageError = true;
    } finally {
      if (!_disposed && generation == _generation) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
