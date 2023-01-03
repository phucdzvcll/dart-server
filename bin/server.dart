import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'db_controller.dart';
import 'redis_client.dart';

final _router = Router()
  ..get('/', _rootHandler)
  ..get('/create-url', _createShortUrlHandler)
  ..get('/url', _getRawUrlHandler)
  ..get('/echo/<message>', _echoHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request req) {
  return Response.ok('_echoHandler Hello, World!\n');
}

final DBController dbController = DBController();

Future<Response> _createShortUrlHandler(Request request) async {
  String? rawUrl = request.requestedUri.queryParameters["rawUrl"];
  if (rawUrl != null) {
    try {
      final shortUrl = await dbController.insertShortUrl(rawUrl);
      return Response.ok('OK $shortUrl');
    } catch (e) {
      return Response.badRequest();
    }
  }

  return Response.notFound(null);
}

Future<Response> _getRawUrlHandler(Request request) async {
  String? url = request.requestedUri.queryParameters["url"];
  if (url != null) {
    try {
      String? rawUrl = await redisClient.get(url);
      if (rawUrl != null) {
        await redisClient.setExpire(url, 60);
        return Response.ok('OK $rawUrl');
      } else {
        final rawUrl = await dbController.getRawUrl(url);
        if (rawUrl != null) {
          await redisClient.set(url, rawUrl);
          await redisClient.setExpire(url, 60);
          return Response.ok('OK $rawUrl');
        } else {
          return Response.notFound(null);
        }
      }
    } catch (e) {
      return Response.notFound(null);
    }
  }

  return Response.notFound(null);
}

RedisClient redisClient = RedisClient();

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8989');

  await redisClient.init();

  await dbController.init();

  final HttpServer server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
