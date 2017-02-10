import { BaseController } from './base';
// import { Model } from '../models/user';
// import { services } from '../services';

export class UsersController extends BaseController {
  // read() {
  //   return (request) => {
  //     return services.knex('users').where({ id: request.params.itemId }).select();
  //   };
  // }
}

UsersController.$name = 'users';
UsersController.hapiOptions = {
  routes: {
    prefix: '/users',
  },
};
