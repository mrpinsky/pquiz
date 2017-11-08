require('./styles/styles.scss');

var Elm = require('./elm/App.elm')
var mountNode = document.getElementById('pquiz');

var app = Elm.App.embed(mountNode);
