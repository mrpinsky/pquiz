const gulp = require('gulp');
const elm = require('gulp-elm');
const sourcemaps = require('gulp-sourcemaps');
const inject = require('gulp-inject');

const del = require('del');
const config = require('../../config');
const serve = require('./serve');
const styles = require('./styles');

function clean() {
  return del([config.frontend.dest]);
}

function compileElm() {
  return gulp.src('src/elm/*.elm')
  .pipe(sourcemaps.init())
  .pipe(elm.bundle('pq-app.js'))
  .pipe(sourcemaps.write())
  .pipe(gulp.dest(config.frontend.dest));
}

function buildIndex() {
  console.log(config.frontend.dest);
  const appCss = gulp.src('styles/*.css', { cwd: config.frontend.dest });
  const appJs = gulp.src('*.js', { cwd: config.frontend.dest });
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

gulp.task('clean:frontend', clean);

gulp.task('elm-init', elm.init);

gulp.task('build:frontend',
  gulp.series(
    clean,
    elm.init,
    compileElm,
    styles.build,
    buildIndex
  )
);

gulp.task('watch:frontend', () => {});

gulp.task('serve:frontend',
  gulp.series(
    'build:frontend',
    serve.serve
  )
);

gulp.task('test:frontend', () => Promise.resolve());
