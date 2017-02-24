import { BaseModel } from './base';

export class User extends BaseModel {}

User.$name = 'users';
User.$schema = {
  attributes: {
    name: 'string',
    email: 'string',
  },
  relationships: {},
};
User.$fields = Object.keys(User.$schema.attributes).concat(Object.keys(User.$schema.relationships));
