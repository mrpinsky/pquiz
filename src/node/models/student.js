export class Student {
  constructor(id, name, classPeriod) {
    this.$id = id;
    this.$name = name;
    this.$classPeriod = classPeriod;
  }

  get id() {
    return this.$id;
  }

  get name() {
    return this.$name;
  }

  set editName(newName) {
    this.$name = newName;
  }

  get class() {
    return this.$classPeriod;
  }

  set changeClass(newClass) {
    this.$classPeriod = newClass;
  }
}
