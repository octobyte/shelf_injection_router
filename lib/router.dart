library tentacle.core.router;

import 'dart:async';
import 'package:shelf/shelf.dart' as shelf;
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
   *
   * If no Route matches the requested url a 404 HttpException is thrown.
   */
  dynamic _handle(shelf.Request request) {
    Function routeHandler = _getHandler(request);
    if(routeHandler is Function) {
      return routeHandler(request);
    }
  }

  /**
   * Matches request uri against registered routes and returns
   * the route handler if one could be found.
   */
  Handler _getHandler(shelf.Request request) {
    if(request.method is String) {
      if(routes.containsKey(request.method)) {
        Route route = routes[request.method].firstWhere((Route route) {
          return route.match(request.requestedUri);
        }, orElse:() => null);

        if(route != null) {
          return route.handler;
        }
      }
      // match against registered handlers
      // found -> parse route params and convert according to handler
      // return handler
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