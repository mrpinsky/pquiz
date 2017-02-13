import { BaseController } from './base';

export class UsersController extends BaseController {
}

UsersController.$name = 'users';
UsersController.hapiOptions = {
  routes: {
    prefix: '/users',
  },
};
