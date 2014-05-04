import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_injection_router/router.dart';
import 'package:shelf_exception_response/exception_response.dart';

void main() {

  Router router = new Router('/api');

  router.addRoute("/hello", (request) {
    return new shelf.Response.ok("Here is the content");
  });

  router.addRoute("/user/:name", (String name, body) {
    return new shelf.Response.ok("Hello ${name}");
  });

  router.addRoute("/location/:lat/:lon", (double lat, double lon) {
    return new shelf.Response.ok("You are at ${lat} / ${lon}");
  });

  router.addRoute("/databody", (body) {
    if(body != null && body.body != null) {
      return new shelf.Response.ok("Hello ${body.body['name']}");
    }
  }, method: 'POST');

  var handler = const shelf.Pipeline()
  .addMiddleware(exceptionResponse())
  .addMiddleware(router.middleware)
  .addHandler((shelf.Request request){
    // fallback handler called when no route matches
    throw new NotFoundException();
  });

  io.serve(handler, 'localhost', 8080).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}