const gulp = require('gulp');
const inject = require('gulp-inject');

const saneWatch = require('../../util/saneWatch');
const config = require('../../config');

function buildIndex() {
  const appCss = gulp.src('styles/*.css', { cwd: config.frontend.dest, read: false });
  const appJs = gulp.src('*.js', { cwd: config.frontend.dest, read: false });
  return gulp.src(config.frontend.index)
  .pipe(inject(appCss,
    {
      ignorePath: `../../${config.frontend.dest}`,
      relative: true,
      addRootSlash: true,
    }
  ))
  .pipe(inject(appJs, {
    ignorePath: `../../${config.frontend.dest}`,
    relative: true,
    addRootSlash: true,
  }))
  .pipe(gulp.dest(config.frontend.dest));
}

module.exports = {
  build: buildIndex,
  watch: saneWatch({
    label: 'Frontend Templates',
    path: config.frontend.src,
    glob: 'index.html',
    rebuild: buildIndex,
  }),
};
