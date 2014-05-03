import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_injection_router/src/handler_reflection.dart';

/**
 * Represents a single [Route] for a [Router]. Prepares
 * regex matcher for given [Uri] and parameter extraction
 * from a given [Uri].
 *
 * Example [Route] with empty handler:
 * Route route = new Route('/hello/:name', (){});
 *
 * Example [Route] matching:
 * route.match(Uri.parse('/world')) -> false
 * route.match(Uri.parse('/hello')) -> false
 * route.match(Uri.parse('/hello/dave')) -> true
 *
 * Example [Route] params extraction
 * route.placeholders -> ['name']
 * route.params(Uri.parse('hello/dave')['name'] -> dave
 *
 * Routes can use a different params format if you define [varPrefix]
 * and optionally [varSuffix].
 * Example other route params format:
 * Rote route = new Route('/hello/{dave}', (){}, varPrefix: '{' varSuffix: '}');
 */
class Route {

  static final String VAR_PATTERN = r'([\w\d]+)';
  static final String VALUE_PATTERN = r'([^\/]+)';
  final List<String> reservedParams = ["request", "body"];

  // Handler for this Route
  Function handler;

  String _route;
  RegExp _prepareExpression;
  RegExp _variableExpression = new RegExp(VAR_PATTERN);
  RegExp _matcher;

  // List of placeholders in this route
  List<String> placeholders = [];

  /**
   * Route constructor takes a route definition string and a [shelf.Handler]
   * function which handles this route. You can optionally define a different
   * Route params format with [varPrefix] and [varSuffix].
   */
  Route(String route, handler, {varPrefix: ':', varSuffix: ''}) {
    HandlerReflection ref = new HandlerReflection(handler);
    this.handler = ref.createHandler();
    _prepareExpression = new RegExp(varPrefix + VAR_PATTERN + varSuffix);
    this.route = route;
  }

  /**
   * Matches this [Route] against a given [Uri]. Returns true if this
   * [Route] matches false otherwise.
   */
  bool match(Uri uri) {
    return (uri.path.contains(_matcher));
  }

  /**
   * Returns the [Route] params for a given [Uri]. Checks for a match
   * first and returns an empty map if no match. On match a Map in the
   * form: {'placeholder':'value'} is returned containing all names from
   * [placeholder] and the extracted values as [String].
   *
   */
  Map<String, String> params(Uri uri) {
    Map<String, String> result = {};
    if(match(uri)) {
      Match m = _matcher.firstMatch(uri.path);
      if(m != null) {
        for(var i = 0; i < m.groupCount; i++) {
          if(placeholders[i] is String) {
            result[placeholders[i]] = m[i+1];
          }
        }
      }
    }
    return result;
  }

  /**
   * Sets a new route definition for this [Route].
   * Recompile matcher and reset placeholders.
   */
  void set route(String route) {
    _route = route;
    _compileMatcher(route);
  }

  // Compile route definition to matcher and sets placeholders.
  void _compileMatcher(String route) {
    _matcher = new RegExp('^' + route.replaceAll(_prepareExpression, VALUE_PATTERN) + r'$');
    placeholders = [];
    _prepareExpression.allMatches(route).forEach((m) {
      for(var i = 1; i<=m.groupCount; i++) {
        String placeholder = m.group(i);
        if(reservedParams.contains(placeholder)) {
          throw new Exception("Can't use ':${placeholder}' in route ${route}. ${placeholder} is a reserved word.");
        }
        placeholders.add(placeholder);
      }
    });
  }

}