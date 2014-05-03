import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_injection_router/router.dart';
import 'package:shelf_exception_response/exception_response.dart';

void main() {

  Router router = new Router('/api');
  router.addRoute("/hello", (request) {
    return new shelf.Response.ok("Here is the content");
  });

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