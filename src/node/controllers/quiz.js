import { BaseController } from './base';

export class QuizController extends BaseController {}

QuizController.$name = 'quizzes';
QuizController.hapiOptions = {
  routes: {
    prefix: '/quizzes',
  },
};
