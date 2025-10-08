import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;
  String _status = 'Waiting for link...';
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    initAppLinks();
  }

  Future<void> initAppLinks() async {
    // 1) Handle initial link (cold start)
    try {
      final dynamic initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        if (initialLink is Uri) {
          _handleIncomingLink(initialLink);
        } else if (initialLink is String) {
          _handleIncomingLinkFromString(initialLink);
        }
      }
    } catch (err) {
      setState(() => _status = 'Failed to get initial link: $err');
    }

    // 2) Handle links while the app is running
    try {
      _sub = _appLinks.uriLinkStream.listen(
        (uri) {
          _handleIncomingLink(uri);
        },
        onError: (err) {
          setState(() => _status = 'Failed to receive link: $err');
        },
      );
    } catch (err) {
      setState(() => _status = 'Failed to subscribe to link stream: $err');
    }
  }

  void _handleIncomingLink(Uri uri) {
    setState(() => _status = 'Received link: $uri');

    if (uri.host == 'details') {
      // Example link: myapp://details/42
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : 'unknown';
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetailScreen(id: id)),
      );
    }
  }

  void _handleIncomingLinkFromString(String link) {
    try {
      final uri = Uri.parse(link);
      _handleIncomingLink(uri);
    } catch (err) {
      setState(() => _status = 'Bad link received: $link');
    }
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
