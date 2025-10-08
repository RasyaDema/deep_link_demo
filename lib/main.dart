import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri>? _sub;
  String _status = 'Waiting for link...';
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String? _pendingId;

  @override
  void initState() {
    super.initState();
    initAppLinks();
  }

  Future<void> initAppLinks() async {
    final appLinks = AppLinks();

    // 1️⃣ Handle initial link (app cold start)
    try {
      final initialUri = await appLinks.getInitialAppLink();
      if (initialUri != null) _handleIncomingLink(initialUri);
    } catch (err) {
      setState(() => _status = 'Failed to get initial link: $err');
    }

    // 2️⃣ Handle link while app is running
    _sub = AppLinks().uriLinkStream.listen(
      (Uri uri) {
        _handleIncomingLink(uri);
      },
      onError: (err) {
        setState(() => _status = 'Failed to receive link: $err');
      },
    );
  }

  void _handleIncomingLink(Uri uri) {
    setState(() => _status = 'Received link: $uri');

    if (uri.host == 'details') {
      // Example link: myapp://details/42
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : 'unknown';
      _navigateToDetail(id);
    }
  }

  void _navigateToDetail(String id) {
    // Try to use the navigator key. If the navigator isn't ready yet
    // (link arrived early, e.g. during startup), save the id and try
    // again after the first frame.
    final nav = _navigatorKey.currentState;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => DetailScreen(id: id)));
      return;
    }

    _pendingId = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav2 = _navigatorKey.currentState;
      if (nav2 != null && _pendingId != null) {
        nav2.push(
          MaterialPageRoute(builder: (_) => DetailScreen(id: _pendingId!)),
        );
        _pendingId = null;
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deep Link Demo',
      navigatorKey: _navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: Text('Home')),
        body: Center(child: Text(_status)),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String id;
  const DetailScreen({required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details')),
      body: Center(child: Text('You opened item ID: $id')),
    );
  }
}
