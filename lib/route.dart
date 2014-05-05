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

  static final String VAR_PATTERN = r'(\?*[\w\d]+)';
  static final String VALUE_PATTERN = r'([^\/]+)';
  static final String OPT_VALUE_PATTERN = r'([^\/]*)';
  static final String LAST_OPT_VALUE_PATTERN = r'([^\/]*)';
  final List<String> reservedParams = ["request", "body"];

  // Handler for this Route
  Function handler;

  String _route;
  String _routePattern;
  RegExp _prepareExpression;
  RegExp _variableExpression = new RegExp(VAR_PATTERN);
  RegExp _matcher;
  String _prefix = ':';
  String _suffix = '';

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
    _prefix = varPrefix;
    _suffix = varSuffix;
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
            var value = (m[i+1] != '') ? m[i+1] : null;
            result[placeholders[i]] = value;
          }
        }
      }
    }
    placeholders.forEach((name) {
      if(!result.containsKey(name)) {
        result[name] = null;
      }
    });
    return result;
  }

  /**
   * Sets a new route definition for this [Route].
   * Recompile matcher and reset placeholders.
   */
  void set route(String route) {
    _route = route;
    _routePattern = route;
    _compileMatcher();
  }

  // Compile route definition to matcher and sets placeholders.
  void _compileMatcher() {
    placeholders = [];

    _prepareExpression.allMatches(_route).forEach((m) {
      for(var i = 1; i<=m.groupCount; i++) {
        _addPlaceholder(m.group(i), i, m.groupCount);
      }
    });

    _matcher = new RegExp('^' + _routePattern + r'$');
  }

  // adds a placeholder and prepares value extraction pattern
  void _addPlaceholder(String placeholder, int index, int total) {
    String valuePattern = VALUE_PATTERN;
    String placeholderName = placeholder;
    String placeholderPattern = placeholder;
    String patternPrefix = '';
    String valuePrefix = '';

    if(placeholder.indexOf('?') == 0) {
      valuePattern = OPT_VALUE_PATTERN;
      placeholderName = placeholder.replaceAll('?', '');
      placeholderPattern = r"\?" + placeholderName;
      if(index == total) {
        // if last param is optional last slash is also optional
        patternPrefix = r'\/';
        valuePrefix = r'\/*';
      }
    }
    if(reservedParams.contains(placeholderName)) {
      throw new Exception("Can't use ':${placeholderName}' in route ${_route}. ${placeholderName} is a reserved word.");
    }
    _routePattern = _routePattern.replaceFirst(new RegExp(patternPrefix + _prefix + placeholderPattern + _suffix), valuePrefix + valuePattern);
    placeholders.add(placeholderName);
  }

}