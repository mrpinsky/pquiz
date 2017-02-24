import Boom from 'boom';

import { services } from '../services';
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

  create() {
    return (request) => {
      return services.knex(this.constructor.$name).insert(request.payload)
      .then(ids => ids[0]);
    };
  }

  read() {
    return (request) => {
      return services.knex(this.constructor.$name).where({ id: request.params.itemId }).select()
      .then(results => results[0]);
    };
  }

  update() {
    return (request) => {
      return services.knex(this.constructor.$name).where({ id: request.params.itemId })
      .update(request.payload)
      .then(results => results[0]);
    };
  }

  destroy() {
    return (request) => {
      return services.knex(this.constructor.$name).where({ id: request.params.itemId }).select()
      .then(results => {
        return services.knex(this.constructor.$name).where({ id: request.params.itemId }).del()
        .then(() => results[0]);
      });
    };
  }

  createHandler(action, options) {
    const handler = this[action](options);
    return (request, reply) => {
      return handler(request)
      .then(data => {
        return reply(data).code(200);
      }).catch((err) => {
        console.log(err);
        return reply(Boom.badRequest('Something went wrong.'));
      });
      // reply(`<h1>${this.constructor.$name} ${action}</h1><p>${JSON.stringify(request.params, null, 2)}</p>`);
    };
  }

  route(action, opts = {}) {
    const routeConfig = Object.assign(
      {},
      {
        handler: this.createHandler(action),
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
