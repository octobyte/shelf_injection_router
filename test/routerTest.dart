library tentacle.test.core.router;

import 'dart:io';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_injection_router/router.dart';
import 'package:shelf_injection_router/route.dart';
import './src/utils.dart';

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

      router.addRoute('/:v1', (request) {
        print(request.context["shelf_injection_router.ctx"].injectables);
        return new shelf.Response.ok("done");
      });

      shelf.Middleware middleware = router.middleware;
      shelf.Handler handler = middleware((r){});
      shelf.Request rootRequest = createShelfRequest('GET', '/');

      test("returns middleware", () {
        expect(middleware is shelf.Middleware, isTrue);
      });

      test("takes request and returns future", () {
        var request = createShelfRequest('GET', '/');
        expect(handler(request) is Future, isTrue);
      });

      test("handler gets called with request object", () {
        var request = createShelfRequest('GET', '/asdf');
        handler(request);
      });



    });

  });




}
