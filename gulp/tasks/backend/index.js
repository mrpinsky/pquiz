const gulp = require('gulp');
const shell = require('gulp-shell');
const config = require('../../config');
const sourcemaps = require('gulp-sourcemaps');
const babel = require('gulp-babel');

const del = require('del');

function clean() {
  return del([config.backend.dest]);
}

gulp.task('db:reset', shell.task([
  'psql -U flo -d postgres -c \'DROP DATABASE if exists pq\'',
  'psql -U flo -d postgres -c \'CREATE DATABASE pq\'',
  // `psql -U flo -d ${nodeConfig.DATABASE_NAME} -c 'CREATE EXTENSION pg_stat_statements'`,
  'psql -U flo -d pq -c \'\\i src/node/db/schema.sql\'',
  // `psql -U flo -d pq -c '\\i src/node/db/db_structuredata.sql'`,
]));

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
