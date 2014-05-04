library tentacle.test.core.router;

import 'dart:io';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_injection_router/router.dart';
import 'package:shelf_injection_router/route.dart';
import './src/utils.dart';
import 'package:shelf_injection_router/src/injection_context.dart';
import 'package:http_server/http_server.dart';

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

    group("injection",() {

      var router = new Router();
      var mw = router.middleware;
      var handler = mw((r) {throw new Exception();});

      test("creates injectable context", () {
        var request = createShelfRequest('GET', '/test');
        router.addRoute('/test', (request) {
          expect(request.context[InjectionContext.CONTEXT_NAME] is InjectionContext, isTrue);
          return new shelf.Response.ok("done");
        });
        expect(handler(request), completes);
      });

      group("injects route params", () {



        test("injects strings", () {
          var request = createShelfRequest('GET', '/strings/tom/123');
          router.addRoute('/strings/:name/:id', (String id, String name) {
            expect(id, equals("123"));
            expect(name, equals("tom"));
            return new shelf.Response.ok("done");
          });
          expect(handler(request), completes);
        });

        test("injects converted values", () {
          var request = createShelfRequest('GET', '/values/tom/123/42.45/1/false');
          router.addRoute('/values/:name/:id/:lat/:b1/:b2', (int id, String name, double lat, bool b1, bool b2) {
            expect(id, equals(123));
            expect(name, equals("tom"));
            expect(lat, equals(42.45));
            expect(b1, equals(true));
            expect(b2, equals(false));
            return new shelf.Response.ok("done");
          });
          expect(handler(request), completes);
        });

        test("injects request by type", () {
          var request = createShelfRequest('GET', '/request');
          router.addRoute("/request", (shelf.Request r) {
            expect(r is shelf.Request, isTrue);
            return new shelf.Response.ok("done");
          });
          expect(handler(request), completes);
        });

        test("injects request by name", () {
          var request = createShelfRequest('GET', '/request1');
          router.addRoute("/request1", (request, [o]) {
            expect(request is shelf.Request, isTrue);
            return new shelf.Response.ok("done");
          });
          expect(handler(request), completes);
        });

        test("injects request single param compatibility mode", () {
          var request = createShelfRequest('GET', '/request2');
          router.addRoute("/request2", (r) {
            expect(r is shelf.Request, isTrue);
            return new shelf.Response.ok("done");
          });
          expect(handler(request), completes);
        });

        test("injects resolved body as string when text", () {
          var req = createShelfRequest('GET', '/body', null, 'src/body.txt');
          router.addRoute('/body', (body) {
            expect(body is HttpRequestBody, isTrue);
            expect(body.type, equals('text'));
            expect(body.body, equals("textbody"));
            return new shelf.Response.ok("done");
          });
          expect(handler(req), completes);
        });

        test("injects resolved body as json map when json", () {
          var req = createShelfRequest('GET', '/bodyjson', null, 'src/body.json');
          router.addRoute('/bodyjson', (body) {
            expect(body is HttpRequestBody, isTrue);
            expect(body.type, equals('json'));
            expect(body.body['asdf'], equals("qwer"));
            return new shelf.Response.ok("done");
          });
          expect(handler(req), completes);
        });

      });

    });

  });




}
