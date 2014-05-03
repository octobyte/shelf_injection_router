library shelf_injection_router.router;

import 'dart:async';
import 'package:shelf/shelf.dart' as shelf;
import './src/injection_context.dart';

import 'package:shelf_injection_router/route.dart';
export 'package:shelf_injection_router/route.dart';

class Router {

  String basePath = "";
  Map<String,List<Route>> routes = {};

  Router([this.basePath = '']);

  /**
   * Exposes this Router as shelf middleware
   */
  shelf.Middleware get middleware => shelf.createMiddleware(requestHandler: _handle);

  /**
   * Matches the request route against the registered routes
   * and dispatches the Routes handler for the first Route that
   * matches.
   */
  dynamic _handle(shelf.Request request) {
    Route route = _getHandler(request);
    if(route != null) {
      var context = new Map.from(request.context);
      InjectionContext ctx = new InjectionContext();
      ctx.injectables.addAll(route.params(request.requestedUri));
      context[InjectionContext.CONTEXT_NAME] = ctx;

      // create new request with injection context
      shelf.Request req = new shelf.Request(
          request.method, request.requestedUri,
          context: context,
          headers: request.headers,
          protocolVersion: request.protocolVersion,
          url: request.url,
          scriptName: request.scriptName
      );

      // read out the requests body as string for further processing
      return request.readAsString().then((String body) {
        ctx.injectables["body"] = body;
        return route.handler(req);
      }).catchError((err) {
        ctx.injectables["body"] = "";
        return route.handler(req);
      });


    }
  }

  /**
   * Matches request uri against registered routes and returns
   * the route handler if one could be found.
   */
  Route _getHandler(shelf.Request request) {
    if(request.method is String) {
      if(routes.containsKey(request.method)) {
        return routes[request.method].firstWhere((Route route) {
          return route.match(request.requestedUri);
        }, orElse:() => null);
      }
    }
  }

  /**
   * Adds a new route to this router and registers its handler for the given route
   * and HTTP method.
   */
  Route addRoute(String route, Function handler, {String method: 'GET', String overrideBasePath}) {
    String base = overrideBasePath == null ? basePath : overrideBasePath;
    Route routeInstance = new Route(base + route, handler);
    _addMethodRoute(method, routeInstance);
    return routeInstance;
  }

  void _addMethodRoute(String method, Route route) {
    if(!routes.containsKey(method)) {
      routes[method] = new List<Route>();
    }
    routes[method].add(route);
  }

}