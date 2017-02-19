export class BaseModel {
  constructor(opts) {
    this.$attributes = {};
    this.$relationships = {};
    for (const key in opts) {
      if (this.constructor.$schema.attributes) {
        this.$attributes[key] = opts[key];
      }
    }
  }
}

BaseModel.$name = 'base';
BaseModel.$schema = { attributes: {}, relationships: {} };
