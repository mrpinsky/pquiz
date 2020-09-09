import './styles/styles.scss';

import { Elm } from './elm/App.elm'
const cachedQuiz = localStorage.getItem('pquiz-cached')

var app = Elm.App.init(JSON.parse(cachedQuiz));

app.ports.focus.subscribe(function (groupId) {
  const group = document.getElementById("group-" + groupId);
  if (group) {
    setTimeout(function () {
      const textarea = group.querySelector("textarea");
      if (textarea) {
        textarea.focus();
      }
    }, 50);
  }
})

app.ports.cacheQuiz.subscribe(function (quiz) {
  localStorage.setItem('pquiz-cached', JSON.stringify(quiz));
})
