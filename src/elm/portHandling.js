/* global Elm */

const storedState = localStorage.getItem('elm-pq-save');
const startingState = storedState ? JSON.parse(storedState) : null;
const storedToken = localStorage.getItem('pq-token') || null;
const app = Elm.App.fullscreen({ quiz: startingState, token: storedToken });

app.ports.focus.subscribe(selector => {
  setTimeout(() => {
    const nodes = document.querySelectorAll(selector);
    if (nodes.length === 1 && document.activeElement !== nodes[0]) {
      nodes[0].focus();
    }
  }, 50);
});

app.ports.setLocalStorage.subscribe(state => {
  localStorage.setItem('elm-pq-save', JSON.stringify(state));
});

app.ports.cacheBearerToken.subscribe(token => {
  console.log(`Caching token ${token}`);
  localStorage.setItem('pq-token', token);
});


app.ports.log.subscribe(a => console.log(a));
