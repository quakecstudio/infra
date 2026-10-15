// CloudFront Function (viewer request): map directory-style URLs to index.html.
//   /           -> /index.html   (also handled by default_root_object)
//   /about/     -> /about/index.html
//   /about      -> /about/index.html
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.endsWith("/")) {
    request.uri = uri + "index.html";
  } else if (uri.lastIndexOf(".") < uri.lastIndexOf("/") + 1) {
    request.uri = uri + "/index.html";
  }

  return request;
}
