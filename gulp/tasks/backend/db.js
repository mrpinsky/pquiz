import gulp from 'gulp';
import shell from 'gulp-shell';

gulp.task('db:reset', shell.task([
  'psql -U flo -d postgres -c \'DROP DATABASE if exists pq',
  'psql -U flo -d postgres -c \'CREATE DATABASE pq',
  // `psql -U flo -d ${nodeConfig.DATABASE_NAME} -c 'CREATE EXTENSION pg_stat_statements'`,
  'psql -U flo -d pq -c \'\\i src/node/db/schema.sql\'',
  // `psql -U flo -d pq -c '\\i src/node/db/db_structuredata.sql'`,
]));
