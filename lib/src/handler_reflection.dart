import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_exception_response/exception.dart';
import 'dart:mirrors';

/**
 * Inflects a request handler function and extracts params, types and metadata
 * for injection and validation use.
 */
class HandlerReflection {

  Function _handler;
  List<Type> _numerics = [num, int, double];
  Map<String, ParameterMirror> _posParams = {
  };
  Map<String, ParameterMirror> _namedParams = {
  };
  InstanceMirror _reqMirror = reflect(shelf.Request);

  /**
   * Constructs internal reflector for params preparation and injection.
   */

  HandlerReflection(Function handler) {
    _handler = handler;
    InstanceMirror tm = reflect(handler);
    if (tm.function != null) {
      tm.function.parameters.forEach((ParameterMirror p) {
        if (p.isNamed) {
          _namedParams[MirrorSystem.getName(p.simpleName)] = p;
        } else {
          _posParams[MirrorSystem.getName(p.simpleName)] = p;
        }
      });
    }
  }

  /**
   * Processes values where injectable is not available.
   */
  _processNullValue(String name, ParameterMirror param) {
    if (!param.isOptional && !param.hasDefaultValue) {
      throw new MissingParamException(name);
    }
    if (param.hasDefaultValue) {
      return param.defaultValue.reflectee;
    }
    return null;
  }

  /**
   * Processes a single injectable and maps/converts it to specified inject param.
   */
  _processParam(String name, ParameterMirror param, shelf.Request req, [value]) {

    // original request and strings always just returned
    if (param.type.reflectedType == shelf.Request || name == "request" || name == "req") {
      return req;
    }

    if (name == "body") {
      return value != null ? value : "";
      // if type other than string create new instance of type with body as param
      // here we have to implement some sort of body parser with respect to request
      // content type. Maybe move these named conversions outside of _processParam?
    }

    // no value for param
    if (value == null) {
      return _processNullValue(name, param);
    }

    // simply return strings
    if (param.type.reflectedType == String) {
      return value.toString();
    }

    // try parsing numeric
    if (_numerics.contains(param.type.reflectedType) && value is String) {
      try {
        return param.type.invoke(#parse, [value]).reflectee;
      }
      on Exception catch(e) {
        throw new InvalidParamException(name, MirrorSystem.getName(param.type.simpleName));
      }
    }

    // try parsing booleans
    if (param.type.reflectedType == bool && value is String) {
      if (value == "true" || value == "1") return true;
      if (value == "false" || value == "0") return false;
      throw new InvalidParamException(name, MirrorSystem.getName(param.type.simpleName));
    }

    // otherwise assign value if assignable
    if (reflect(value).type.isAssignableTo(param.type)) {
      return value;
    } else {
      throw new InvalidParamException(name, MirrorSystem.getName(param.type.simpleName));
    }

  }

  /**
   * Adds all positional argument values for given injectables to given ArgumentsResult. On error
   * errors are added to the ArgumentsResult.
   */
  ArgumentsResult _getPosArgs(Map<String, dynamic> injectables, shelf.Request req, ArgumentsResult res) {

    // single argument not in injectables and assignable always injects request
    if (_posParams.length == 1 && !injectables.containsKey(_posParams.keys.first)) {
      if (_reqMirror.type.isAssignableTo(_posParams.values.first.type)) {
        res.addPositionalArgument(req);
        return res;
      }
    }

    _posParams.forEach((name, param) {
      var injectable = injectables.containsKey(name) ? injectables[name] : null;
      try {
        res.addPositionalArgument(_processParam(name, param, req, injectable));
      }
      on Exception catch (e) {
        res.addError(e.toString());
      }
    });
    return res;
  }

  /**
   * Adds named arguments to the given ArgumentsResult. On error adds error messages
   * to argument result errors.
   */
  ArgumentsResult _getNamedArgs(Map<String, dynamic> injectables, shelf.Request req, ArgumentsResult res) {
    _namedParams.forEach((name, param) {
      var injectable = injectables.containsKey(name) ? injectables[name] : null;
      try {
        var argument = _processParam(name, param, req, injectable);
        if(argument != null) {
          res.addNamedArgument(param.qualifiedName, argument);
        }
      }
      on Exception catch (e) {
        res.addError(e.toString());
      }
    });
    return res;
  }

  /**
   * Collects a arguments from request and maps it to inject positional and named arguments.
   */
  ArgumentsResult getArguments(shelf.Request request) {
    var ctx = request.context["shelf_injection_router.ctx"];
    ArgumentsResult res = _getPosArgs(ctx.injectables, request, new ArgumentsResult());
    return _getNamedArgs(ctx.injectables, request, res);
  }

  /**
   * Creates the actual shelf handler from an injectable handler.
   */
  Function createHandler() {
    return (shelf.Request request) {
      var arguments = getArguments(request);
      if(arguments.errors.length > 0) {
        throw new PreconditionFailedException({"errors": arguments.errors});
      }
      return Function.apply(_handler, arguments.positionalArguments, arguments.namedArguments);
    };
  }

}

/**
 * A arguments result object containing errors, named and positional arguments.
 */
class ArgumentsResult {

  List positionalArguments = [];
  Map<Symbol, dynamic> namedArguments = {};
  List errors = [];

  addPositionalArgument(dynamic argument) {
    positionalArguments.add(argument);
  }

  addNamedArgument(Symbol name, dynamic argument) {
    namedArguments[name] = argument;
  }

  addError(String message) {
    errors.add(message);
  }

}

/**
 * Required param is missing
 */
class InvalidParamException implements Exception {
  final String name;
  final String type;

  const InvalidParamException([this.name, this.type]);

  String toString() => "Could not convert param: $name to $type";
}

/**
 * Required param is missing
 */
class MissingParamException extends InvalidParamException {
  final String name;

  const MissingParamException([this.name]);

  String toString() => "Missing required param: $name";
}

