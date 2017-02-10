const sane = require('sane');

function debounce(func, wait) {
  let timeout;
  return function debounced(...args) {
    const context = this;
    function later() {
      timeout = null;
      func.apply(context, args);
    }
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}


module.exports = function saneWatch(opts) {
  console.log(`Initializing ${opts.label}`);
  return function watch() {
    const watcher = sane(opts.path, { glob: opts.glob, watchman: false });
    const reload = debounce(() => {
      console.log(`Rebuilding ${opts.label}`);
      opts.rebuild();
    }, 200);
    watcher.on('ready', () => {
      console.log(`${opts.label} Ready`);
    });
    watcher.on('change', () => reload());
    watcher.on('add', () => reload());
    watcher.on('delete', () => reload());
  };
};
