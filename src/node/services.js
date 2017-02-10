import knex from 'knex';

export const services = {
  knex: null,
  server: null,
  initialize: (opts = {}) => {
    // Promise.longStackTraces();
    const knexOpts = Object.assign(
      {},
      {
        client: 'postgres',
        debug: true,
        connection: {
          user: 'nodeapp',
          host: 'localhost',
          port: '5432',
          database: 'pq',
          password: 'tenace',
          charset: 'utf8',
        },
        pool: {
          max: 1, min: 1,
        },
      },
      opts.knex
    );

    services.knex = knex(knexOpts);
  },
};
