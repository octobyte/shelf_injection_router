import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_injection_router/router.dart';
import 'package:shelf_exception_response/exception_response.dart';

void main() {

  // create router for base path /api
  Router router = new Router('/api');

  // static route
  router.addRoute("/hello", (request) {
    return new shelf.Response.ok("Here is the content");
  });

  // dynamic route
  router.addRoute("/user/:?name", (String name) {
    return new shelf.Response.ok("Hello ${name}");
  });

  // dynamic route with optional param
  router.addRoute("/echo/:?name", ({String name: "unknown"}) {
    return new shelf.Response.ok("Your name is ${name}");
  });

  // dynamic route with params validation and conversion
  router.addRoute("/location/:lat/:lon", (double lat, double lon) {
    return new shelf.Response.ok("You are at ${lat} / ${lon}");
  });

  // static route with body injection
  router.addRoute("/databody", (body) {
    if(body != null && body.body != null) {
      return new shelf.Response.ok("Hello ${body.body['name']}");
    }
  }, method: 'POST');

  // default router handles root route /
  var otherRouter = new Router();
  otherRouter.addRoute("/", () {
    return new shelf.Response.ok("Welcome to root");
  });

  var handler = const shelf.Pipeline()
  .addMiddleware(router.middleware) // add api router
  .addMiddleware(otherRouter.middleware) // add other router
  .addHandler((shelf.Request request){
    throw new NotFoundException(); // fallback handler called when no route has matched
  });

  io.serve(handler, 'localhost', 8080).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}