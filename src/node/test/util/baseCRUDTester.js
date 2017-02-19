/* eslint-env node, mocha */

import chai from 'chai';
import chaiAsPromised from 'chai-as-promised';

chai.use(chaiAsPromised);
chai.should();

// import { server } from '../server';
// import { services } from '../services';

export function testRoutes(ctrl) {
  describe(`${ctrl.$name} routes`, () => {
    it('should create resources from provided data');
    it('should read and return resources from the database');
    it('should update resources with the provided delta');
    it('should delete and return resources from the database');
  });
}
