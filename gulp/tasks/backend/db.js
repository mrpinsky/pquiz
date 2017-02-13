import gulp from 'gulp';
import shell from 'gulp-shell';
import Knex from 'knex';
import through from 'through2';

const config = require('../../config');

function migrate() {
  const knex = Knex({ // eslint-disable-line new-cap
    client: 'postgres',
    debug: true,
    connection: {
      user: 'postgres',
      host: 'localhost',
      port: '5432',
      database: 'pq',
      charset: 'utf8',
    },
    pool: {
      max: 1, min: 1,
    },
  });

  return knex('migrations')
  .where({
    status: 'up',
  }).pluck('filename')
  .then((files) => {
    return gulp.src(`${config.dest}/backend/db/sql_migrations/*`)
    .pipe(through.obj((file, enc, callback) => {
      const filename = file.path.split('/').pop();
      if (files.indexOf(filename) >= 0) {
        console.log(`skipping ${filename}`);
        callback();
      } else if (filename.match(/\.sql$/) !== null) {
        console.log(`sourcing ${filename}`);
        knex.raw(file.contents.toString())
        .then(() => {
          callback();
        })
        .catch((err) => {
          callback(err);
        });
      } else if (filename.match(/\.js$/) !== null) {
        console.log(`sourcing ${filename}`);
        require(file.path)()
        .then(() => {
          callback();
        })
        .catch((err) => {
          callback(err);
        });
      }
    }, () => {
      return knex.destroy().then(() => {
        console.log('migration complete');
        process.exit();
      });
    }));
  });
}

gulp.task('db:reset',
  gulp.series(
    shell.task([
      'psql -U postgres -d postgres -c \'DROP DATABASE if exists pq\'',
      'psql -U postgres -d postgres -c \'CREATE DATABASE pq\'',
      // `psql -U flo -d ${nodeConfig.DATABASE_NAME} -c 'CREATE EXTENSION pg_stat_statements'`,
      'psql -U postgres -d pq -c \'\\i src/node/db/schema.sql\'',
      // `psql -U flo -d pq -c '\\i src/node/db/db_structuredata.sql'`,
    ]),
    migrate
  )
);

module.exports = {
  migrate: migrate,
};
