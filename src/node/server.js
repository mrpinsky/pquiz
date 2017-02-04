import * as Hapi from 'hapi';
import * as Good from 'good';
// import Knex from 'knex';
// import * as Bluebird from 'bluebird';

import { controllers } from './controllers/index.js';

// const knex = Knex({ // eslint-disable-line new-cap
//   client: 'postgres',
//   debug: true,
//   connection: {
//     host: 'localhost',
//     user: 'nate',
//     password: '',
//     database: 'myapp_test',
//   },
// });

const server = new Hapi.Server({
  debug: {
    log: ['error'],
  },
});

server.connection({
  host: 'localhost',
  port: 3000,
});

server.register({
  register: Good,
  options: {
    reporters: {
      console: [{
        module: 'good-squeeze',
        name: 'Squeeze',
        args: [{
          response: '*',
          log: '*',
        }],
      }, {
        module: 'good-console',
      }, 'stdout'],
    },
  },
}).then(() => {
  return server.route({
    method: 'GET',
    path: '/',
    handler: (request, reply) => {
      reply('<h1>Home</h1>');
    },
  });
}).then(() => {
  return Promise.all(
    controllers.map(C => {
      return server.register(new C().plugin, C.hapiOptions);
    })
  );
}).then(() => {
  server.start(() => {
    console.log(`Server running at: ${server.info.uri}`);
  });
}).catch((err) => {
  console.error(err.stack);
  throw err;
});
