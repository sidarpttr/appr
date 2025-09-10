import 'dart:async';
import 'package:appr/core/binding.dart';

typedef NavigateFn = void Function(String route, Map<String, String>? params);
typedef ApiCallFn = Future<Map<String, dynamic>> Function(String id);
typedef RefreshFn = void Function(); // ← EKLENDİ

class ActionRunner {
  final NavigateFn navigate;
  final ApiCallFn callApi;
  final void Function(void Function()) setState;
  final RefreshFn refresh; // ← EKLENDİ

  ActionRunner({
    required this.navigate,
    required this.callApi,
    required this.setState,
    required this.refresh, // ← EKLENDİ
  });

  Future<void> run(
    List actions,
    BindingResolver br, {
    Map<String, dynamic>? item,
  }) async {
    for (final a in actions) {
      final type = a['type'];
      if (type == 'navigate') {
        final to = br.resolve(a['to'], item: item)?.toString() ?? '';
        final params = <String, String>{};
        final rawParams = (a['params'] as Map<String, dynamic>? ?? {});
        rawParams.forEach((k, v) {
          final resolved = br.resolve(v, item: item);
          params[k] = resolved?.toString() ?? '';
        });
        navigate(to, params);
      } else if (type == 'apiCall') {
        final id = br.resolve<String>(a['id'], item: item) ?? '';
        await callApi(id);
        refresh(); // ← API sonrası UI’ı yenile
      } else if (type == 'updateState') {
        final path = a['path'] as String;
        final value = br.resolve(a['value'], item: item);
        setState(() {
          // TODO: path parser ile appState[path] = value;
        });
        refresh();
      }
    }
  }
}
