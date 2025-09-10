import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/registry.dart';
import 'core/renderer.dart';
import 'core/binding.dart';
import 'core/actions.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, dynamic>? doc;
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);

  late WidgetRegistry registry;
  late BindingResolver br;
  late ActionRunner ar;

  Map<String, dynamic> appState = {};
  Map<String, dynamic> datasources = {};
  Map<String, dynamic> routeParams = {};

  final dio = Dio();

  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    registry = WidgetRegistry()
      ..register('Unknown', (_, __, ___) => const SizedBox());
    registerCoreWidgets(registry);

    datasources = {
      "products": {"data": []},
    };
    br = BindingResolver(
      appState: appState,
      routeParams: routeParams,
      datasources: datasources,
    );

    ar = ActionRunner(
      navigate: (routeName, params) {
        _router?.pushNamed(routeName, pathParameters: params ?? {});
      },
      callApi: (id) async {
        final ds = (doc?['datasources']?[id]) as Map<String, dynamic>?;
        if (ds == null) return {};
        final res = await dio.get(ds['url'] as String);
        setState(() {
          datasources[id] = {"data": res.data}; // sadece veriyi yaz
        });
        return datasources[id];
      },
      setState: setState,
      refresh: () => _tick.value++,
    );

    _loadJson();
  }

  Future<void> _loadJson() async {
    final raw = await rootBundle.loadString('assets/sample/app.json');
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      doc = parsed;
    });
    _buildRouter(); // JSON geldikten sonra router'ı kur
  }

  void _buildRouter() {
    final routesJson = (doc!['routes'] as List).cast<Map<String, dynamic>>();

    List<RouteBase> routes = routesJson.map((r) {
      final name = r['name'] as String;
      final path = r['path'] as String;
      final screenId = r['screen'] as String;

      return GoRoute(
        name: name,
        path: path,
        builder: (context, state) {
          return ValueListenableBuilder<int>(
            valueListenable: _tick,
            builder: (_, __, ___) {
              final params = <String, dynamic>{
                ...state.pathParameters,
                ...state.uri.queryParameters,
              };
              final rctx = _makeRenderCtx(params);
              final screen = _findScreen(screenId);
              final root = registry.build(
                screen['layout'] as Map<String, dynamic>,
                context,
                rctx,
              );

              return Scaffold(
                appBar: AppBar(title: Text(name)),
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: root, // tek scroll: ListView kendi kaydırır
                ),
              );
            },
          );
        },
      );
    }).toList();

    setState(() {
      _router = GoRouter(refreshListenable: _tick, routes: routes);
    });
  }

  Map<String, dynamic> _findScreen(String id) {
    return (doc!['screens'] as List).cast<Map<String, dynamic>>().firstWhere(
      (s) => s['id'] == id,
    );
  }

  RenderCtx _makeRenderCtx(Map<String, dynamic> params) {
    br = BindingResolver(
      appState: appState,
      routeParams: params,
      datasources: datasources,
    );
    return RenderCtx(registry, br, ar);
  }

  @override
  Widget build(BuildContext context) {
    if (doc == null || _router == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp.router(routerConfig: _router!);
  }
}
