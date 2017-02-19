const gulp = require('gulp');
const sass = require('gulp-sass');
const sourcemaps = require('gulp-sourcemaps');
const path = require('path');

const saneWatch = require('../../util/saneWatch');
const config = require('../../config');

function buildStyles() {
  return gulp.src(config.styles.files, { cwd: config.styles.src })
  .pipe(sourcemaps.init())
  .pipe(sass())
  .pipe(sourcemaps.write())
  .pipe(gulp.dest(path.join(config.frontend.dest, 'styles')));
}

module.exports = {
  build: buildStyles,
  watch: saneWatch({
    label: 'Frontend Styles',
    path: config.styles.src,
    glob: config.styles.files,
    rebuild: buildStyles,
  }),
};
