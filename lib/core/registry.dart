import 'package:appr/core/actions.dart';
import 'package:appr/core/binding.dart';
import 'package:flutter/widgets.dart';

typedef WidgetBuilderFn =
    Widget Function(
      Map<String, dynamic> node,
      BuildContext context,
      RenderCtx rctx,
    );

class WidgetRegistry {
  final _map = <String, WidgetBuilderFn>{};
  void register(String type, WidgetBuilderFn builder) => _map[type] = builder;

  Widget build(
    Map<String, dynamic> node,
    BuildContext context,
    RenderCtx rctx,
  ) {
    final type = node['type'] as String? ?? 'Unknown';
    final builder = _map[type];
    if (builder == null) return const SizedBox.shrink();
    return builder(node, context, rctx);
  }
}

class RenderCtx {
  final WidgetRegistry registry;
  final BindingResolver br;
  final ActionRunner ar;

  RenderCtx(this.registry, this.br, this.ar);
}
