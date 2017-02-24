const gulp = require('gulp');
const elm = require('gulp-elm');
const sourcemaps = require('gulp-sourcemaps');

const config = require('../../config');
const saneWatch = require('../../util/saneWatch');

function compileElm() {
  return gulp.src(config.frontend.files, { cwd: config.frontend.src })
  .pipe(sourcemaps.init())
  .pipe(elm.bundle('pq-app.js'))
  .pipe(sourcemaps.write())
  .pipe(gulp.dest(config.frontend.dest));
}

gulp.task('elm:build', gulp.series(elm.init, compileElm));

module.exports = {
  build: 'elm:build',
  watch: saneWatch({
    label: 'Elm',
    path: config.frontend.src,
    glob: '**/*.elm',
    rebuild: compileElm,
  }),
};
