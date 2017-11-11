require('./styles/styles.scss');

var Elm = require('./elm/App.elm')
var mountNode = document.getElementById('pquiz');

var app = Elm.App.embed(mountNode);

app.ports.focus.subscribe(function (groupId) {
  var group, textarea;
  mountNode.focus();
  mountNode.blur();
  group = document.getElementById("group-" + groupId);
  if (group) {
    setTimeout(function () {
      textarea = group.querySelector("textarea");
      if (textarea) {
        textarea.focus();
      }
    }, 0);
  }
})
