const gulp = require('gulp');
const del = require('del');
const sourcemaps = require('gulp-sourcemaps');
const babel = require('gulp-babel');
const concat = require('gulp-concat');

// require('./tasks');

function clean() {
  return del([gulp.config.backend.dest]);
}

gulp.task('clean', clean);

gulp.task('build', () => {});

// gulp.task('default', gulp.series('clean', 'serve'));

gulp.task('default', () => {
  return gulp.series(
    clean,
    gulp.src('src/node/*.js')
    .pipe(sourcemaps.init())
    .pipe(babel())
    .pipe(concat('all.js'))
    .pipe(sourcemaps.write('.'))
    .pipe(gulp.dest('dist'))
  );
});
