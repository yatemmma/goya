var ws = new WebSocket("ws://127.0.0.1:8081");

ws.onmessage = function(e) {
  print(e.data);
};

ws.onopen = function(e) {
  print("[log] websocket open");
  console.log(e);
};

ws.onclose = function(e) {
  print("[log] websocket close");
  console.log(e);
};

$(function() {
  $("#send").click(post);
  $("#command").keydown(function(e){
    if(e.keyCode == 13) post();
  });
});

var post = function() {
  var msg = $("#command").val();
  ws.send('{"job":"' + msg + '"}');
};

var print = function(msg) {
  if (msg.substring(0,4) == "raw=") {
    console.log(JSON.parse(msg.substring(4,msg.length)));
  } else {
    $("#chat").prepend($("<li>").text(msg));  
  }
};
