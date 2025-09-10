import 'package:flutter/material.dart';
import 'binding.dart';

Color? parseColor(dynamic v, BindingResolver br, {Map<String, dynamic>? item}) {
  final s = br.resolve<String>(v, item: item);
  if (s == null || s.isEmpty) return null;
  var hex = s.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  final val = int.tryParse(hex, radix: 16);
  if (val == null) return null;
  return Color(val);
}

double? parseDouble(
  dynamic v,
  BindingResolver br, {
  Map<String, dynamic>? item,
}) {
  final x = br.resolve(v, item: item);
  if (x is num) return x.toDouble();
  if (x is String) return double.tryParse(x);
  return null;
}

int? parseInt(dynamic v, BindingResolver br, {Map<String, dynamic>? item}) {
  final x = br.resolve(v, item: item);
  if (x is int) return x;
  if (x is String) return int.tryParse(x);
  if (x is double) return x.toInt();
  return null;
}

bool? parseBool(dynamic v, BindingResolver br, {Map<String, dynamic>? item}) {
  final x = br.resolve(v, item: item);
  if (x is bool) return x;
  if (x is String) return (x.toLowerCase() == 'true' || x == '1');
  if (x is num) return x != 0;
  return null;
}

EdgeInsets? parseEdgeInsets(
  dynamic v,
  BindingResolver br, {
  Map<String, dynamic>? item,
}) {
  if (v == null) return null;
  if (v is Map) {
    final top = parseDouble(v['top'], br, item: item) ?? 0;
    final right = parseDouble(v['right'], br, item: item) ?? 0;
    final bottom = parseDouble(v['bottom'], br, item: item) ?? 0;
    final left = parseDouble(v['left'], br, item: item) ?? 0;
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }
  final s = br.resolve<String>(v, item: item);
  if (s == null) return null;
  final parts = s
      .split(',')
      .map((e) => double.tryParse(e.trim()) ?? 0)
      .toList();
  if (parts.isEmpty) return null;
  if (parts.length == 1) return EdgeInsets.all(parts[0]);
  if (parts.length == 2)
    return EdgeInsets.symmetric(vertical: parts[0], horizontal: parts[1]);
  if (parts.length == 4)
    return EdgeInsets.fromLTRB(parts[1], parts[0], parts[3], parts[2]);
  return null;
}

// Basit enum parser: "center"/"start" → TextAlign.center/…
T? parseEnum<T>(
  dynamic v,
  Map<String, T> map,
  BindingResolver br, {
  Map<String, dynamic>? item,
}) {
  final s = br.resolve<String>(v, item: item)?.toLowerCase();
  if (s == null) return null;
  return map[s];
}

TextStyle? parseTextStyle(
  dynamic v,
  BindingResolver br, {
  Map<String, dynamic>? item,
}) {
  if (v == null) return null;
  if (v is! Map) return null;
  final color = parseColor(v['color'], br, item: item);
  final fontSize = parseDouble(v['fontSize'], br, item: item);
  final fwStr = br.resolve<String>(v['fontWeight'], item: item)?.toLowerCase();
  FontWeight? weight;
  if (fwStr != null) {
    const w = {
      'w100': FontWeight.w100,
      'w200': FontWeight.w200,
      'w300': FontWeight.w300,
      'w400': FontWeight.w400,
      'w500': FontWeight.w500,
      'w600': FontWeight.w600,
      'w700': FontWeight.w700,
      'w800': FontWeight.w800,
      'w900': FontWeight.w900,
      'thin': FontWeight.w100,
      'light': FontWeight.w300,
      'regular': FontWeight.w400,
      'medium': FontWeight.w500,
      'semibold': FontWeight.w600,
      'bold': FontWeight.w700,
    };
    weight = w[fwStr];
  }
  final italic = parseBool(v['italic'], br, item: item) ?? false;
  TextStyle s = const TextStyle();
  if (color != null) s = s.copyWith(color: color);
  if (fontSize != null) s = s.copyWith(fontSize: fontSize);
  if (weight != null) s = s.copyWith(fontWeight: weight);
  if (italic) s = s.copyWith(fontStyle: FontStyle.italic);
  return s;
}

class BoxProps {
  final EdgeInsets? padding;
  final Color? color;
  final double? radius;
  BoxProps({this.padding, this.color, this.radius});
  factory BoxProps.from(
    Map<String, dynamic>? props,
    BindingResolver br, {
    Map<String, dynamic>? item,
  }) {
    final p = props ?? const <String, dynamic>{};
    return BoxProps(
      padding: parseEdgeInsets(p['padding'], br, item: item),
      color: parseColor(p['backgroundColor'] ?? p['bg'], br, item: item),
      radius: parseDouble(p['borderRadius'] ?? p['radius'], br, item: item),
    );
  }
}
