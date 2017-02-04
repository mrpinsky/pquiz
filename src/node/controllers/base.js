// import Boom from 'boom';

import { baseRoutes } from './baseRoutes';

function plugin(server, _, next) {
  server.route(
    this.constructor.actions.map((action) => {
      return this.route(action, baseRoutes[action]);
    })
  );
  next();
}

export class BaseController {
  constructor() {
    this.plugin = plugin.bind(this);
    this.plugin.attributes = {
      name: this.constructor.$name,
      version: '0.0.1',
    };
  }

  createHandler(action) {
    return (request, reply) => {
      reply(`<h1>${this.constructor.$name} ${action}</h1><p>${JSON.stringify(request.params, null, 2)}</p>`);
    };
  }

  route(action, opts = {}) {
    const routeConfig = Object.assign(
      {},
      {
        handler: opts.handler || this.createHandler(action),
      },
      opts
    );
    return routeConfig;
  }
}

BaseController.actions = [
  'create',
  'read',
  'update',
  'destroy',
];
