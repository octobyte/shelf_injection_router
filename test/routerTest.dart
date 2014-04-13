library tentacle.test.core.router;

import 'dart:io';
import 'dart:async' show Future;
import 'package:unittest/unittest.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_injection_router/router.dart';
import 'package:shelf_injection_router/route.dart';
import 'package:shelf_exception_response/exception.dart';

String BASE_URL = "http://www.test.io";

shelf.Request createShelfRequest(String method, String path) {
 Uri uri = Uri.parse(BASE_URL + path);
 Map<String, String>headers = {};
 return new shelf.Request(method, uri);
}

void main() {

  group("router ", () {

    group("construct", () {

      test("router uses enpty base path as default base path", () {
        Router router = new Router();
        expect(router.basePath, equals(''));
      });

      test("router uses given base path", () {
        Router router = new Router('/api');
        expect(router.basePath, equals('/api'));
      });
    });

    group("addRoute", () {

      Router router = new Router('/api');

      test("add route returns a new route object", () {
        expect(router.addRoute("/asdf", (){return "";}) is Route, isTrue);
      });

      test("add route adds route to correct method collection", () {
        Route route = router.addRoute("/asdf", (){return "";});
        expect(router.routes['GET'].contains(route), isTrue);
      });

    });

    group("handle ", () {

      Router router = new Router();
      router.addRoute('/', (request) {
        return new shelf.Response.ok("done");
      });

      shelf.Middleware middleware = router.middleware;
      Handler handler = middleware((r){});
      shelf.Request rootRequest = createShelfRequest('GET', '/');

      test("returns middleware", () {
        expect(middleware is shelf.Middleware, isTrue);
      });

      test("takes request and returns future", () {
        var request = createShelfRequest('GET', '/');
        expect(handler(request) is Future, isTrue);
      });



    });

  });




}
