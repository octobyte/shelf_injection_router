import 'package:unittest/unittest.dart';
import 'package:shelf_injection_router/route.dart';

void main() {

  group("route", (){

    var handler = (r){};

    String root = "/";
    String withVars = "/:varName";
    String noVars = "/a/b/c";
    String complex = "/a/:a/b/:b";

    Map<String, Map<String, dynamic>> testRoutes = {
      "root": {"route":"/", "placeholders": []},
      "level1": {"route":"/a", "placeholders": []},
      "level2": {"route":"/a/b", "placeholders": []},
      "level3": {"route":"/a/b/c", "placeholders": []},
      "vlevel0": {"route":"/:a", "placeholders": ['a']},
      "vlevel1": {"route":"/a/:a", "placeholders": ['a']},
      "vlevel2": {"route":"/a/:a/b", "placeholders": ['a']},
      "vlevel3": {"route":"/a/:a/:b", "placeholders": ['a', 'b']},
      "vlevel4": {"route":"/a/:a/:b/b", "placeholders": ['a', 'b']},
      "vlevel5": {"route":"/a/:a/b/:b", "placeholders": ['a', 'b']},
      "vlevel6": {"route":"/a/:a/:b/:c", "placeholders": ['a', 'b', 'c']},
      "vlevel7": {"route":"/a/:a/:b/:c/b", "placeholders": ['a', 'b', 'c']}
    };

    Map<String, Map<String, dynamic>> testRoutesOtherFormat = {
        "vlevel0": {"route":"/{a}", "placeholders": ['a']},
        "vlevel1": {"route":"/a/{a}", "placeholders": ['a']},
        "vlevel2": {"route":"/a/{a}/b", "placeholders": ['a']},
        "vlevel3": {"route":"/a/{a}/{b}", "placeholders": ['a', 'b']},
        "vlevel4": {"route":"/a/{a}/{b}/b", "placeholders": ['a', 'b']},
        "vlevel5": {"route":"/a/{a}/b/{b}", "placeholders": ['a', 'b']},
        "vlevel6": {"route":"/a/{a}/{b}/{c}", "placeholders": ['a', 'b', 'c']},
        "vlevel7": {"route":"/a/{a}/{b}/{c}/b", "placeholders": ['a', 'b', 'c']}
    };

    Map<String, Route> routes = {};
    testRoutes.forEach((name, config) {
      routes[name] = new Route(config['route'], handler);
    });

    Map<String, Route> otherRoutes = {};
    testRoutesOtherFormat.forEach((name, config) {
      otherRoutes[name] = new Route(config['route'], handler, varPrefix: '{', varSuffix: '}');
    });

    Map<String, Map<String, dynamic>> testPaths = {
      "/": {
          "matches": ["root"],
          "params": [{}]
      },
      "/a": {
          "matches": ["level1", "vlevel0"],
          "params": [{}, {"a":"a"}]
      },
      "/a/b": {
          "matches": ["level2", "vlevel1"],
          "params": [{}, {"a":"b"}]
      },
      "/a/b/c": {
          "matches": ["level3", "vlevel3"],
          "params": [{}, {"a":"b", "b":"c"}]
      },
      "/var1": {
          "matches": ["vlevel0"],
          "params": [{"a": "var1"}]
      },
      "/a/var1": {
          "matches": ["vlevel1"],
          "params": [{"a": "var1"}]
      },
      "/a/var1/b": {
          "matches": ["vlevel2", "vlevel3"],
          "params": [{"a": "var1"}, {"a":"var1", "b":"b"}]
      },
      "/a/var1/var2": {
          "matches": ["vlevel3"],
          "params": [{"a": "var1", "b":"var2"}]
      },
      "/a/var1/var2/b": {
          "matches": ["vlevel4", "vlevel6"],
          "params": [{"a": "var1", "b":"var2"}, {"a":"var1", "b":"var2", "c":"b"}]
      },
      "/a/var1/b/var2": {
          "matches": ["vlevel5", "vlevel6"],
          "params": [{"a": "var1", "b":"var2"}, {"a": "var1", "b":"b", "c":"var2"}]
      },
      "/a/var1/var2/var3": {
          "matches": ["vlevel6"],
          "params": [{"a": "var1", "b":"var2", "c": "var3"}]
      },
      "/a/var2/var3/var1/b": {
          "matches": ["vlevel7"],
          "params": [{"a": "var2", "b":"var3", "c": "var1"}]
      }
    };

    group("construct", (){

      test("gives Route", (){
        var route = new Route('/', handler);
        expect(route is Route, isTrue);
      });

      test("throws on reserved word", () {
        expect(() => new Route('/:request', handler), throws);
        expect(() => new Route('/:body', handler), throws);
      });
    });

    group("placeholders", (){
      group("in testroute", () {
        routes.forEach((name, route) {
          test("${name} are correct", () {
            expect(route.placeholders, orderedEquals(testRoutes[name]['placeholders']));
          });
        });
      });
    });

    group("matcher", () {
      testPaths.forEach((path, config) {
        config['matches'].forEach((match) {
          test("${match} matches ${path}", () {
            expect(routes[match].match(Uri.parse(path)), isTrue);
          });
        });
      });

      testPaths.forEach((path, config) {
        routes.forEach((name, route){
          if(!config['matches'].contains(name)) {
            test("${name} does not match ${path}", () {
              expect(routes[name].match(Uri.parse(path)), isFalse);
            });
          }
        });
      });

    });

    group("params", () {

      // test default params format
      testPaths.forEach((path, config) {
        for(var i=0; i<config['matches'].length; i++) {
          test("from url ${path} in route ${config['matches'][i]} are OK", () {
            expect(routes[config['matches'][i]].params(Uri.parse(path)), equals(config['params'][i]));
          });
        }
      });

      // {var} params format
      testPaths.forEach((path, config) {
        for(var i=0; i<config['matches'].length; i++) {
          if(otherRoutes.containsKey(config['matches'][i])) {
            test("from url ${path} in other route format ${config['matches'][i]} are OK", () {
              expect(otherRoutes[config['matches'][i]].params(Uri.parse(path)), equals(config['params'][i]));
            });
          }
        }
      });
    });

  });

}