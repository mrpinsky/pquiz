import { BaseModel } from './base';

export class Quiz extends BaseModel {}

Quiz.$name = 'quizzes';
Quiz.$schema = {
  attributes: {
    class: 'integer',
    label: 'string',
    model: 'object',
  },
  relationships: {},
};
