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
    this.constructor.plugin = plugin.bind(this);
    this.constructor.plugin.attributes = {
      name: this.constructor.$name,
      version: '0.0.1',
    };
  }

  createHandler(action) {
    return (request, reply) => {
      reply(`<h1>${this.constructor.$name} ${action.toUpperCase()}</h1><p>${request.params}</p>`);
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
