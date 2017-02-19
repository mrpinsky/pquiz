/* eslint-env node, mocha */

import chai from 'chai';
import chaiAsPromised from 'chai-as-promised';

import { server, serverStarted } from '../server';
import { services } from '../services';
import { controllers } from '../controllers/';
import { testRoutes } from './util/baseCRUDTester';

chai.use(chaiAsPromised);
chai.should();

before(() => {
  return serverStarted;
});

describe('API', () => {
  before(() => {
    services.initialize();
  });

  describe('server functionality', () => {
    it('should respond to requests', () => {
      return server.inject('/').should.eventually.have.property('statusCode', 200);
    });
  });

  controllers.forEach(ctrl => {
    testRoutes(ctrl);
  });

  after(() => {
    return services.teardown().then(() => {
      return server.stop({ timeout: 1000 });
    });
  });
});
