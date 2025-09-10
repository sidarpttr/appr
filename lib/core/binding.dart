class BindingResolver {
  final Map<String, dynamic> appState;
  final Map<String, dynamic> routeParams;
  final Map<String, dynamic> datasources;

  BindingResolver({
    required this.appState,
    required this.routeParams,
    required this.datasources,
  });

  // --- PUBLIC API ---
  T? resolve<T>(dynamic val, {Map<String, dynamic>? item}) {
    if (val is String && val.contains('\${')) {
      // Sadece tek bir token mı?  "${...}"
      final single = RegExp(r'^\s*\$\{([^}]+)\}\s*$');
      final m = single.firstMatch(val);
      if (m != null) {
        final obj = _evalPath(m.group(1)!, item: item);
        return obj as T?;
      } else {
        // Metin içinde gömülü ifade(ler) varsa interpolasyon → String
        return _interpolate(val, item: item) as T?;
      }
    }
    return val as T?;
  }

  List? resolveList(dynamic val, {Map<String, dynamic>? item}) =>
      resolve<List>(val, item: item);

  Map<String, dynamic>? resolveMap(dynamic val, {Map<String, dynamic>? item}) =>
      resolve<Map<String, dynamic>>(val, item: item);

  String resolveString(dynamic val, {Map<String, dynamic>? item}) =>
      resolve<String>(val, item: item) ?? '';

  // --- INTERNALS ---
  dynamic _evalPath(String expr, {Map<String, dynamic>? item}) {
    // expr örn: datasources.products.data
    final parts = expr.split('.');
    dynamic cur;
    switch (parts.first) {
      case 'appState':
        cur = appState;
        break;
      case 'route':
        cur = routeParams;
        break;
      case 'datasources':
        cur = datasources;
        break;
      case 'item':
        cur = item;
        break;
      default:
        return null;
    }
    for (var i = 1; i < parts.length; i++) {
      final key = parts[i];
      if (cur is Map && cur.containsKey(key)) {
        cur = cur[key];
      } else {
        return null;
      }
    }
    return cur;
  }

  String _interpolate(String input, {Map<String, dynamic>? item}) {
    return input.replaceAllMapped(RegExp(r'\$\{([^}]+)\}'), (m) {
      final value = _evalPath(m.group(1)!, item: item);
      return value?.toString() ?? '';
    });
  }
}
