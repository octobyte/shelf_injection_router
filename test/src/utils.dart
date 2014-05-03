library shelf_injection_router.test.utils;
import 'package:shelf/shelf.dart' as shelf;
import 'dart:async';
import 'dart:io';
import 'package:shelf_injection_router/src/injection_context.dart';

String BASE_URL = "http://www.test.io";

shelf.Request createShelfRequest(String method, String path, [Map<String, dynamic> ctx]) {
  Uri uri = Uri.parse(BASE_URL + path);
  Map<String, String>headers = {};
  File file = new File("body.json");
  Map<String, Object> context = {};
  var inj = new InjectionContext();
  if(ctx != null) {
    inj.injectables.addAll(ctx);
  }

  context["shelf_injection_router.ctx"] = inj;

  return new shelf.Request(method, uri, body: file.openRead(), context: context);
}