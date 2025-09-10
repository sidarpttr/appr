import 'package:appr/core/props.dart';
import 'package:flutter/material.dart';
import 'registry.dart';

Widget columnBuilder(Map<String, dynamic> node, BuildContext c, RenderCtx r) {
  final children = (node['children'] as List? ?? [])
      .map<Widget>((n) => r.registry.build(n as Map<String, dynamic>, c, r))
      .toList();

  // Column için dinamik: mainAxis, crossAxis, spacing
  final props = (node['props'] as Map?) ?? const {};
  final main = parseEnum<MainAxisAlignment>(props['mainAxisAlignment'], {
    'start': MainAxisAlignment.start,
    'center': MainAxisAlignment.center,
    'end': MainAxisAlignment.end,
    'spacebetween': MainAxisAlignment.spaceBetween,
    'spacearound': MainAxisAlignment.spaceAround,
    'spaceevenly': MainAxisAlignment.spaceEvenly,
  }, r.br);
  final cross = parseEnum<CrossAxisAlignment>(props['crossAxisAlignment'], {
    'start': CrossAxisAlignment.start,
    'center': CrossAxisAlignment.center,
    'end': CrossAxisAlignment.end,
    'stretch': CrossAxisAlignment.stretch,
  }, r.br);

  return Column(
    mainAxisAlignment: main ?? MainAxisAlignment.start,
    crossAxisAlignment: cross ?? CrossAxisAlignment.start,
    children: children,
  );
}

Widget textBuilder(Map<String, dynamic> node, BuildContext c, RenderCtx r) {
  final item = _ItemScope.of(c);
  final props = (node['props'] as Map?) ?? const {};
  final text = r.br.resolveString(props['text'], item: item);
  final style = parseTextStyle(props['style'], r.br, item: item);
  final align = parseEnum<TextAlign>(
    props['textAlign'],
    {
      'start': TextAlign.start,
      'left': TextAlign.left,
      'center': TextAlign.center,
      'right': TextAlign.right,
      'end': TextAlign.end,
      'justify': TextAlign.justify,
    },
    r.br,
    item: item,
  );

  // Container benzeri sarma (padding/bg/radius)
  final box = BoxProps.from(props.cast<String, dynamic>(), r.br, item: item);
  Widget w = Text(text, textAlign: align, style: style);
  if (box.padding != null || box.color != null || (box.radius ?? 0) > 0) {
    w = Container(
      padding: box.padding,
      decoration: (box.color != null || (box.radius ?? 0) > 0)
          ? BoxDecoration(
              color: box.color,
              borderRadius: BorderRadius.circular(box.radius ?? 0),
            )
          : null,
      child: w,
    );
  }
  return w;
}

Widget spacerBuilder(Map<String, dynamic> node, BuildContext c, RenderCtx r) {
  final props = (node['props'] as Map?) ?? const {};
  final h = parseDouble(props['height'], r.br) ?? 8;
  final w = parseDouble(props['width'], r.br);
  return SizedBox(height: h, width: w);
}

Widget cardBuilder(Map<String, dynamic> node, BuildContext c, RenderCtx r) {
  final props = (node['props'] as Map?) ?? const {};
  final box = BoxProps.from(props.cast<String, dynamic>(), r.br);
  final childNode = node['child'] as Map<String, dynamic>;
  final child = r.registry.build(childNode, c, r);
  final margin =
      parseEdgeInsets(props['margin'], r.br) ??
      const EdgeInsets.symmetric(vertical: 8);

  return Container(
    margin: margin,
    padding: box.padding ?? const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: box.color ?? Colors.white,
      borderRadius: BorderRadius.circular(box.radius ?? 12),
    ),
    child: child,
  );
}

Widget buttonBuilder(Map<String, dynamic> node, BuildContext c, RenderCtx r) {
  final item = _ItemScope.of(c);
  final props = (node['props'] as Map?) ?? const {};
  final label = r.br.resolveString(props['text'], item: item);
  final actions = (node['actions'] as List?) ?? const [];

  final box = BoxProps.from(props.cast<String, dynamic>(), r.br, item: item);
  final onPressed = () => r.ar.run(actions, r.br, item: item);

  // variant: "text" | "outlined" | "elevated"
  final variant =
      r.br.resolve<String>(props['variant'], item: item)?.toLowerCase() ??
      'elevated';

  Widget btn;
  if (variant == 'text') {
    btn = TextButton(
      onPressed: onPressed,
      child: Text(label.isEmpty ? 'Button' : label),
    );
  } else if (variant == 'outlined') {
    btn = OutlinedButton(
      onPressed: onPressed,
      child: Text(label.isEmpty ? 'Button' : label),
    );
  } else {
    btn = ElevatedButton(
      onPressed: onPressed,
      child: Text(label.isEmpty ? 'Button' : label),
    );
  }

  // padding/bg/radius uygula (Container ile)
  if (box.padding != null || box.color != null || (box.radius ?? 0) > 0) {
    btn = Container(
      padding: box.padding,
      decoration: (box.color != null || (box.radius ?? 0) > 0)
          ? BoxDecoration(
              color: box.color,
              borderRadius: BorderRadius.circular(box.radius ?? 0),
            )
          : null,
      child: btn,
    );
  }
  return btn;
}

Widget expandedBuilder(Map<String, dynamic> node, BuildContext c, RenderCtx r) {
  final childNode = node['child'] as Map<String, dynamic>;
  final child = r.registry.build(childNode, c, r);
  return Expanded(child: child);
}

Widget listViewBuilder(Map<String, dynamic> node, BuildContext c, RenderCtx r) {
  final itemsExpr = node['bindings']?['items'];
  final List items = r.br.resolveList(itemsExpr) ?? const [];
  final template = node['itemBuilder'] as Map<String, dynamic>;
  final props = (node['props'] as Map?) ?? const {};

  final horizontal = parseBool(props['horizontal'], r.br) ?? false;
  final itemExtent = parseDouble(props['itemExtent'], r.br);
  final sep =
      r.br.resolve<String>(props['separatorText']) ?? ''; // basit ayraç örneği

  Widget itemBuilderFn(BuildContext ctx, int i) {
    final it = items[i] as Map<String, dynamic>;
    return _ItemScope(
      item: it,
      child: Builder(builder: (ctx) => r.registry.build(template, ctx, r)),
    );
  }

  final list = ListView.builder(
    scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
    shrinkWrap: false,
    physics: const ClampingScrollPhysics(),
    itemExtent: (itemExtent != null && itemExtent > 0)
        ? itemExtent
        : null, // ← güvenli
    itemCount: items.length,
    itemBuilder: itemBuilderFn,
  );

  // basit separator desteği (opsiyonel)
  if (sep.isNotEmpty) {
    return ListView.separated(
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      shrinkWrap: false,
      physics: const ClampingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => Center(child: Text(sep)),
      itemBuilder: itemBuilderFn,
    );
  }
  return list;
}

class _ItemScope extends InheritedWidget {
  final Map<String, dynamic>? item;
  const _ItemScope({required this.item, required super.child, super.key});

  static Map<String, dynamic>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ItemScope>()?.item;

  @override
  bool updateShouldNotify(covariant _ItemScope oldWidget) =>
      !identical(oldWidget.item, item);
}

void registerCoreWidgets(WidgetRegistry reg) {
  reg
    ..register('Column', columnBuilder)
    ..register('Text', textBuilder)
    ..register('Button', buttonBuilder)
    ..register('ListView', listViewBuilder)
    ..register('Expanded', expandedBuilder)
    ..register('Spacer', spacerBuilder)
    ..register('Card', cardBuilder);
}
