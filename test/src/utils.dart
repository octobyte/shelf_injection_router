library shelf_injection_router.test.utils;
import 'package:shelf/shelf.dart' as shelf;
import 'dart:async';
import 'dart:io';
import 'package:shelf_injection_router/src/injection_context.dart';
import 'package:unittest/mock.dart';

String BASE_URL = "http://www.test.io";

shelf.Request createShelfRequest(String method, String path, [Map<String, dynamic> ctx, String body = "src/body.json"]) {
  Uri uri = Uri.parse(BASE_URL + path);

  Map<String, String>headers = {};
  var mockRequest = new HttpRequestMock(body);
  Map<String, Object> context = {};

  if(ctx != null) {
    var inj = new InjectionContext();
    inj.injectables.addAll(ctx);
    context["shelf_injection_router.ctx"] = inj;
  }

  return new shelf.Request(method, uri, body: mockRequest, context: context);
}

class HttpRequestMock extends Mock implements HttpRequest {
  Stream<List<int>> _real;
  HttpHeaders headers;

  HttpRequestMock(String path) {
    this._real = new File(path).openRead();
    if(path.indexOf('.json') != -1) {
      headers = new HttpHeadersMock('application/json; charset=utf-8');
    }
    if(path.indexOf('.txt') != -1) {
      headers = new HttpHeadersMock('text/plain; charset=utf-8');
    }
    when(callsTo('fold')).alwaysCall(_real.fold);
    when(callsTo('transform')).alwaysCall(_real.transform);

  }
}

class HttpHeadersMock extends Mock implements HttpHeaders {

  ContentType contentType;

  HttpHeadersMock(String contentType) {
    this.contentType = ContentType.parse(contentType);
  }
}