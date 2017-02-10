const gulp = require('gulp');
const del = require('del');

const config = require('../../config');
const scripts = require('./scripts');
const serve = require('./serve');
const assets = require('./assets');
const db = require('./db');

function clean() {
  return del([config.backend.dest]);
}

gulp.task('clean:backend', clean);

gulp.task('build:backend',
  gulp.series(
    clean,
    gulp.parallel(
      assets.build,
      scripts.build
      // templates.build
    )
  )
);

gulp.task('db:migrate',
  gulp.series(
    'build:backend',
    db.migrate
  )
);

gulp.task('watch:backend', scripts.watch);

gulp.task('serve:backend',
  gulp.series(
    'build:backend',
    gulp.parallel(
      'watch:backend',
      serve.serve
    )
  )
);
