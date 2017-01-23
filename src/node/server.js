import * as Hapi from 'hapi';

const server = new Hapi.Server({
  debug: {
    log: ['error'],
  },
});

server.connection({
  host: 'localhost',
  port: 3000,
});

server.register(require('inert'), (err) => {
  if (err) {
    throw err;
  }

  server.route({
    method: 'GET',
    path: '/',
    handler: (request, reply) => {
      return reply.file('../frontend/index.html');
    },
  });
});

server.start((err) => {
  if (err) {
    throw err;
  }
  console.log(__dirname);
  console.log(`Server running at: ${server.info.uri}`);
});
