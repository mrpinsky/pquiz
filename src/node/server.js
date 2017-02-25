import * as Hapi from 'hapi';
import Good from 'good';
import hapiAuthBearer from 'hapi-auth-bearer-token';

import { controllers } from './controllers/index.js';
import { services } from './services';
import { TokenStrategy } from './controllers/authenticationPlugins/token';

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

export const server = new Hapi.Server({
  debug: {
    log: ['error'],
  },
});

server.connection({
  host: 'localhost',
  port: 3000,
});

// export const serverStarted = Promise.resolve()
export const serverStarted = server.register({
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
})
.then(() => {
  return server.register(hapiAuthBearer);
}).then(() => {
  return Promise.all([
    server.route({
      method: 'GET',
      path: '/',
      handler: (_, reply) => {
        reply('<h1>Home</h1>');
      },
    }),
    server.route({
      method: 'POST',
      path: '/api/login',
      handler: (request, reply) => {
        services.knex('users').where({ email: request.payload.email }).select('id', 'name', 'email', 'bearer_token')
        .then(result => reply(result[0]));
      },
    }),
  ]);
}).then(() => {
  return server.register([require('vision'), require('inert'), { register: require('lout') }]);
}).then(() => {
  server.auth.strategy('bearer', 'bearer-access-token', TokenStrategy.strategy);
  return Promise.all(
    controllers.map(C => {
      return server.register(new C().plugin, C.hapiOptions);
    })
  );
}).then(() => {
  return services.initialize();
}).then(() => {
  if (!module.parent) {
    server.start(() => {
      console.log(`Server running at: ${server.info.uri}`);
    });
  }
}).catch((err) => {
  console.error(err.stack);
  throw err;
});
