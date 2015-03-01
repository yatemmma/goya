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
  var $li = $("<li>");
  var response = null;
  try {
    response = JSON.parse(msg);
  } catch (e) {
    response = {};
  }
  $span = $("<span>");
  if (response.type === "wait") {
    $span.text('wait ' + response.time + ' sec');
  } else if (response.type === "job") {
    $span.text(response.message);
  } else if (response.type === "uri") {
    $span.text(response.uri);
    console.log(response.data);
  } else if (response.type === "click") {
    $span.text('[' + response.page + '] > [' + response.button + '] ' + response.expects.join(','));
  } else if (response.type === "error") {
    $span.text(response.message);
  } else {
    $span.text(msg);
  }
  $li.addClass(response.type);
  $li.prepend($("<span>").text(Date.create().format('{M}/{d} {hh}:{mm}:{ss}')));
  $li.append($span);
  $("#chat").prepend($li);
};
