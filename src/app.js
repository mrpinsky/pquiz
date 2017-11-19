require('./styles/styles.scss');

var Elm = require('./elm/App.elm')
var mountNode = document.getElementById('pquiz');
var cachedQuiz = localStorage.getItem('pquiz-cached')

var app = Elm.App.embed(mountNode, JSON.parse(cachedQuiz));

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
    }, 50);
  }
})

app.ports.cacheQuiz.subscribe(function (quiz) {
  localStorage.setItem('pquiz-cached', JSON.stringify(quiz));
})
