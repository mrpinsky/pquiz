import { BaseController } from './base';

export class UsersController extends BaseController {}

UsersController.$name = 'Users';
UsersController.hapiOptions = {
  routes: {
    prefix: '/users',
  },
};
