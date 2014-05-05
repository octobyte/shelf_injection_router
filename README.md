## Shelf Injection Router ##
[Shelf](http://pub.dartlang.org/packages/shelf) router middleware to provide routing, params validation and injection of
params into request handlers. This is currently a very early release and some apis may be changed in the future as my work
on another project continues.

### What problem(s) does it solve ###

#### 1. Routing ####
Like all other routers for shelf this router provides a mechanism to trigger different request handlers based on the URL
called by the client. Routes can have dynamic parts that will become available in your request handler. The pattern for
dynamic route parts can be configured and params can be optional.

##### Simple usage #####
You can create a router by creating a Router instance and add it as middleware to the shelf pipeline. Routes can be added
via the addRoute method giving the route pattern as string and a handler function for the route. Per default all routes
are configured to handle "GET" requests. To handle other HTTP verbs define the "method" params with the HTTP verb of your
choosing. After adding the router to your shelf pipeline make sure to add a fallback handler that is triggered when no
previous route matched the requests url.

```dart

// create a new router
Router router = new Router();

// register a handler for a static route
router.addRoute("/hello", (request) {
  return new shelf.Response.ok("Here is the content");
});

// register a handler for a dynamic route
router.addRoute("/hello/:name", (String name) {
  return new shelf.Response.ok("Hello ${name}");
});

// register a handler for POST request with body injection
router.addRoute("/hello/:name", (String name, body) {
  return new shelf.Response.ok("Hello ${name} you posted ${body.body["content"]}");
}, method:'POST');

// use the router as shelf middleware
var handler = const shelf.Pipeline()
  .addMiddleware(router.middleware) // add router middleware (you can add more than one router)
  .addHandler((shelf.Request request){
    // this is called when no route has matched
    throw new NotFoundException();
  });

```

##### Advanced options #####
In addition to the functionality above you can set path parameters as optional by prefixing the with "?" (eg.: :?varname).
If you don't like the ":" prefix for declaring your route params you can change them to use a different format. Every Router
has the ability to only handle defined route prefixes which can be defined on construction (see /api example below).

```dart

// register a handler with optional param using ?
// make sure your handler param is optional too and/or has a default value
router.addRoute("/optional/:?name", ({String name = "unknown"}) {
  return new shelf.Response.ok("Hello ${name}");
});

// create a router responsible for a specific path. Routes are now prefixed with /api in this router
var apiRouter = new Router('/api');

// use a different params format in your route definitions (eg. {} instead of :)
apiRouter.patternPrefix = "{";
apiRouter.patternSuffix = "}";

// this will match on "/api/car/123"
apiRouter.addRoute("/car/{id}", (int id) {
	return new shelf.Response.ok("The cars id is ${id}");
});

// override base path for a single route so this will match "/parkingspace/car/123"
apiRouter.addRoute("/car/{id}", (int id) {
	return new shelf.Response.ok("The cars id is ${id}");
}, overrideBasePath: "/parkingspace");

```

#### 2. Route params, validation and body parsing ####
As you might have noticed in the examples above, the route handlers do not only take the self.Request as argument but also
different types of other arguments. This is because every route handler gets an injector function wrapped around it and
provides some values as injectables for the handler function.

For now injectables can be all route params defined in the route pattern, the original shelf.Request and the request body
if available. Route params are injected by their name. If a param type is defined on the handler function the injector tries
to convert the param to the appropriate type. If the conversion fails or a required param is missing
a [formatted](http://pub.dartlang.org/packages/tentacle_response_formatter) error response is sent to the client. the injector
also makes use of default params in the handler function if the param is missing.

```dart

// name injected as String for "/hello/you"
router.addRoute("/hello/:name", (name) {
	// name -> "you"
});

// name injected as String for "/hello/you"
router.addRoute("/hello/:name", (String name) {
	// name -> "name"
});

// returns param validation error for "/hello/you"
router.addRoute("/hello/:name", (int name) {
	// never called "you" can not be converted to int
});

// name injected as double for "/hello/123.456"
router.addRoute("/hello/:name", (double name) {
	// name -> 123.456
});

// returns missing param validation error  for "/hello"
router.addRoute("/hello/:?name", (String name) {
	// never executed
});

// default value used for "/hello"
router.addRoute("/hello/:?name", ({String name: "unknown"}) {
	// name -> "unknown"
});

```

Body and request are special injectables and reserved words (you can not use "body" or "request" as route param names). By
default the request body of a shelf.Request is a Future<String> an has to be resolved. If you inject yourself "body" (given
the request contains a body) you will get a completely resolved and parsed [HttpBody](https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/http_server/http_server.HttpBody).
Request is reserved to provide compatibility with other shelf handler and middleware. There are two ways a request
will get injected to the handler:
 * A handler param named "request" is present
 * The handler takes only on argument and its name is not in the injectables


```dart

// body parsed and injected as HttpBody
router.addRoute("/hello", (HttpBody body) {
	// body.type -> eg.: json
	// body.body["name"] -> eg.: value
}, method: 'POST');

// request will be injected as "r"
router.addRoute("/hello", (r) {
	// r -> shelf.Request
});

// value of r will be injected
router.addRoute("/hello/:r", (r) {
	// r -> value of r in request url
});

// throws request is reserved word
router.addRoute("/:request", (request) {
	// never executed
});

```

### TODO's ###
There are several things missing which I would like to add sooner or later:

1. Ability to add custom shelf middleware to a router
2. Ability to add custom shelf middleware to a single route with the injection mechanism in place
3. Ability for middleware to add additional injectables to the request
4. Request body validation with custom body types

### License ###
Apache 2.0