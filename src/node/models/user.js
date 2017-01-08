export class User {
  constructor(name, email) {
    this.$name = name;
    this.$email = email;
    this.$classes = [];
  }

  addClass(period) {
    this.$classes.push(period);
  }

  get name() {
    return this.$name;
  }

  get email() {
    return this.$email;
  }

  get classList() {
    return this.$classes;
  }

  set editName(newName) {
    this.$name = newName;
  }

  set editEmail(newEmail) {
    this.$email = newEmail;
  }
}
