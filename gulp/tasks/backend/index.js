const gulp = require('gulp');
const config = require('../../config');
const sourcemaps = require('gulp-sourcemaps');
const babel = require('gulp-babel');

const del = require('del');

function clean() {
  return del([config.backend.dest]);
}

function buildBackend() {
  return gulp.src('src/node/server.js')
  .pipe(sourcemaps.init())
  .pipe(babel({
    presets: ['es2015', 'stage-0'],
    plugins: ['transform-es2015-modules-commonjs', 'add-module-exports'],
  }))
  .pipe(sourcemaps.write())
  .pipe(gulp.dest(config.backend.dest));
}

gulp.task('clean:backend', clean);

gulp.task('build:backend',
  gulp.series(
    clean,
    buildBackend
  )
);
