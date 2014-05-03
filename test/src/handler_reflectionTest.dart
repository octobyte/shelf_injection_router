library shelf_injection_router.test.handler_reflection;
import 'package:shelf/shelf.dart' as shelf;
import 'package:unittest/unittest.dart';
import 'package:shelf_injection_router/src/handler_reflection.dart';
import 'utils.dart';

void main() {

  var standardType = (shelf.Request request){};
  var simpleTypeHandler = (String a, num b, bool c) {};
  var complexTypeHandler = (String s, num n, bool b, {String ns:"qwer", int nn:5678, bool nb: true, String os: "asdf", num ons: 1234, bool ob}) {};

  group("construct", () {

    test("reads arguments", () {
      HandlerReflection ref = new HandlerReflection(complexTypeHandler);
    });

  });

  group("createHandler", () {

    HandlerReflection stdRef = new HandlerReflection(standardType);

    test("returns function", () {
      Function handler = stdRef.createHandler();
      handler(createShelfRequest("GET", "/asdf"));
    });

  });

  group("injects request", () {

    test("dynamic single arg", () {

      var r = createShelfRequest("GET", "/");
      new HandlerReflection((request) {
        expect(request is shelf.Request, isTrue);
      }).createHandler()(r);

      new HandlerReflection((req) {
        expect(req is shelf.Request, isTrue);
      }).createHandler()(r);

      new HandlerReflection((r) {
        expect(r is shelf.Request, isTrue);
      }).createHandler()(r);
    });

    test("static single arg", () {

      var r = createShelfRequest("GET", "/");
      new HandlerReflection((shelf.Request request) {
        expect(request is shelf.Request, isTrue);
      }).createHandler()(r);

      new HandlerReflection((shelf.Request req) {
        expect(req is shelf.Request, isTrue);
      }).createHandler()(r);

      new HandlerReflection((shelf.Request r) {
        expect(r is shelf.Request, isTrue);
      }).createHandler()(r);
    });

    test("static multiple arg", () {

      var r = createShelfRequest("GET", "/", {"a": "true"});
      new HandlerReflection((shelf.Request request, bool a) {
        expect(request is shelf.Request, isTrue);
      }).createHandler()(r);

      new HandlerReflection((bool a, shelf.Request req) {
        expect(req is shelf.Request, isTrue);
      }).createHandler()(r);

      new HandlerReflection((shelf.Request r, [bool a]) {
        expect(r is shelf.Request, isTrue);
      }).createHandler()(createShelfRequest("GET", "/"));
    });

    test("dynamic by name 'request' with multiple arg", () {
      var r = createShelfRequest("GET", "/", {"a": true});
      new HandlerReflection((bool a, request) {
        expect(request is shelf.Request, isTrue);
      }).createHandler()(r);
    });

    test("dynamic by name 'req' with multiple arg", () {
      var r = createShelfRequest("GET", "/", {"a": true});
      new HandlerReflection((req, bool a) {
        expect(req is shelf.Request, isTrue);
      }).createHandler()(r);
    });

  });

  group("injects body", () {

    test("by name 'body'", () {
      new HandlerReflection((body) {
        expect(body == "body", isTrue);
      }).createHandler()(createShelfRequest("GET", "/asdf", {"body": "body"}));
    });

  });

  group("inject postional arguments", () {

    test("throws on missing non optional param", () {
      var r = createShelfRequest("GET", "/", {"a": "1"});
      expect((){new HandlerReflection((int b){}).createHandler()(r);}, throws);
    });

    test("succeeds on missing optional param", () {
      var r = createShelfRequest("GET", "/", {"a": "1"});
      new HandlerReflection(([int b]){
        expect(b, isNull);
      }).createHandler()(r);
    });

    group("numeric", () {

      var r = createShelfRequest("GET", "/", {"a": "1", "b": "1.2"});

      test("num", () {
        new HandlerReflection((num a, num b) {
          expect(a, equals(1));
          expect(a is num, isTrue);
          expect(b, equals(1.2));
          expect(b is num, isTrue);
        }).createHandler()(r);

      });

      test("int", () {
        new HandlerReflection((int a) {
          expect(a, equals(1));
          expect(a is int, isTrue);
        }).createHandler()(r);

      });

      test("int on float value throws", () {
        expect(() {new HandlerReflection((int b) {}).createHandler()(r);}, throws);
      });

      test("double", () {
        new HandlerReflection((double b) {
          expect(b, equals(1.2));
          expect(b is double, isTrue);
        }).createHandler()(r);

      });

      test("double on int value", () {
        new HandlerReflection((double a) {
          expect(a, equals(1.0));
          expect(a is double, isTrue);
        }).createHandler()(r);

      });

    });

    group("string", () {

      var r = createShelfRequest("GET", "/", {"a": "asdf", "b": true, "c": 1234});

      test("simply returns string", () {
        new HandlerReflection((String a) {
          expect(a, equals('asdf'));
          expect(a is String, isTrue);
        }).createHandler()(r);
      });

      test("calls toString on non string", () {
        new HandlerReflection((String b, String c) {
          expect(b, equals('true'));
          expect(c, equals('1234'));
          expect(b is String, isTrue);
        }).createHandler()(r);
      });

    });

    group("boolean", () {

      var r = createShelfRequest("GET", "/", {"a": "false", "b": "true", "c": "0", "d": "1", "e": "hello"});

      test("'false' is boolean false", () {
        new HandlerReflection((bool a) {
          expect(a, equals(false));
          expect(a is bool, isTrue);
        }).createHandler()(r);
      });

      test("'true' is boolean true", () {
        new HandlerReflection((bool b) {
          expect(b, equals(true));
          expect(b is bool, isTrue);
        }).createHandler()(r);
      });

      test("'0' is boolean false", () {
        new HandlerReflection((bool c) {
          expect(c, equals(false));
          expect(c is bool, isTrue);
        }).createHandler()(r);
      });

      test("'1' is boolean true", () {
        new HandlerReflection((bool d) {
          expect(d, equals(true));
          expect(d is bool, isTrue);
        }).createHandler()(r);
      });

      test("other strings throw", () {
        expect((){new HandlerReflection((bool e) {}).createHandler()(r);}, throws);
      });

    });

    group("dynamics", () {

      test("assigned as present in injectables", () {
        var mi = {};
        var li = [];
        var oi = new Exception();
        var r = createShelfRequest("GET", "/", {"s": "asdf", "m": mi, "l": li, "o": oi});
        new HandlerReflection((s, m, l, o) {
          expect(s, equals("asdf"));
          expect(m, equals(mi));
          expect(l, equals(li));
          expect(o, equals(oi));
        }).createHandler()(r);
      });

    });


  });

  group("inject named arguments", () {

    var r = createShelfRequest("GET", "/", {
        "body": "body", "b": "true", "i": "22", "d": "1.22"
    });

    test("all are optional", () {
      new HandlerReflection(({String z, g, int w}) {
        expect(z, isNull);
        expect(g, isNull);
        expect(w, isNull);
      });
    });

    test("are injected and converted", () {
      new HandlerReflection(({body, bool b, int i, double d}) {
        expect(body, equals("body"));
        expect(b, equals(true));
        expect(i, equals(22));
        expect(d, equals(1.22));
      });

    });

    test("can be combined with positionals", () {
      new HandlerReflection((body, bool b, {int i, double d}) {
        expect(body, equals("body"));
        expect(b, equals(true));
        expect(i, equals(22));
        expect(d, equals(1.22));
      });

    });

  });

}