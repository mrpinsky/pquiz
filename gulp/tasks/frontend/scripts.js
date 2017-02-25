const gulp = require('gulp');
const babel = require('gulp-babel');
const sourcemaps = require('gulp-sourcemaps');

const config = require('../../config');
const saneWatch = require('../../util/saneWatch');

function buildFrontendScripts() {
  return gulp.src(config.frontend.scripts, { cwd: config.frontend.src })
  .pipe(sourcemaps.init())
  .pipe(babel({
    presets: ['es2015'],
  }))
  .pipe(sourcemaps.write())
  .pipe(gulp.dest(config.frontend.dest));
}

module.exports = {
  build: buildFrontendScripts,
  watch: saneWatch({
    label: 'Frontend Scripts',
    path: config.frontend.src,
    glob: '*.js',
    rebuild: buildFrontendScripts,
  }),
};
