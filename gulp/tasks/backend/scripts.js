const gulp = require('gulp');
const config = require('../../config');
const sourcemaps = require('gulp-sourcemaps');
const babel = require('gulp-babel');
const saneWatch = require('../../util/saneWatch');

function buildBackendScripts() {
  return gulp.src(config.backend.scripts, { cwd: config.backend.src })
  .pipe(sourcemaps.init())
  .pipe(babel({
    presets: ['es2015', 'stage-0'],
    plugins: ['transform-es2015-modules-commonjs', 'add-module-exports'],
  }))
  .pipe(sourcemaps.write())
  .pipe(gulp.dest(config.backend.dest));
}

module.exports = {
  build: buildBackendScripts,
  watch: saneWatch({
    label: 'Backend Scripts',
    path: config.backend.src,
    glob: config.backend.scripts,
    rebuild: buildBackendScripts,
  }),
};
