import { BaseController } from './base';
// import { Model } from '../models/user';
// import { services } from '../services';

export class ClassesController extends BaseController {}

ClassesController.$name = 'classes';
ClassesController.hapiOptions = {
  routes: {
    prefix: '/classes',
  },
};
