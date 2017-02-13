import { BaseController } from './base';

export class ClassesController extends BaseController {}

ClassesController.$name = 'classes';
ClassesController.hapiOptions = {
  routes: {
    prefix: '/classes',
  },
};
