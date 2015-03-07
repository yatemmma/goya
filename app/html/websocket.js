var ws = new WebSocket("ws://127.0.0.1:8081");

ws.onmessage = function(e) {
  print(e.data);
};

ws.onopen = function(e) {
  print("websocket open");
  console.log(e);
};

ws.onclose = function(e) {
  print("websocket close");
  console.log(e);
};

$(function() {
  $("#send").click(post);
  $("#command").keydown(function(e){
    if(e.keyCode == 13) post();
  });
});

var post = function() {
  ws.send($("#command").val());
};

var print = function(msg) {
  var response = null;
  try {
    response = JSON.parse(msg);
  } catch (e) {
    response = {};
  }

  var $li = $("<li>");
  $li.addClass(response.type);
  $span = $("<span>");

  if (response.type === "info") {
    $span.text(response.params);
    $li.append($span);
    $("#chat").prepend($li);
    return;
  }
  
  if (response.type === "wait") {
    $span.text('wait ' + response.time + ' sec');
  } else if (response.type === "job") {
    $span.text(response.message);
  } else if (response.type === "uri") {
    $span.text(response.uri);
    console.log(response.data);
    if (response.uri == '/api_start2') master = response.data;
    if (response.uri == '/api_port/port') port = response.data;
  } else if (response.type === "click") {
    $span.text('[' + response.page + '] > [' + response.button + '] ' + response.expects.join(','));
  } else if (response.type === "error") {
    $span.text(response.message);
  } else if (response.type === "reload") {
    $span.text("reload game window");
    reload();
  } else {
    $span.text(msg);
  }
  $li.prepend($("<span>").text(Date.create().format('{M}/{d} {HH}:{mm}:{ss}')));
  $li.append($span);
  $("#chat").prepend($li);
};
