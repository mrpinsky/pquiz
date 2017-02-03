import { Group } from './group';

export class ClassPeriod {
  constructor(name) {
    this.$name = name;
    this.$students = [];
    this.$groups = [];
    this.$defaultObservations = {};
  }

  get name() {
    return this.$name;
  }

  set editName(newName) {
    this.$name = newName;
  }

  get students() {
    return this.$students;
  }

  set addStudent(student) {
    this.$students.push(student);
  }

  set dropStudent(student) {
    this.$students = this.$students.filter((s) => s !== student);
  }

  get groups() {
    return this.$groups;
  }

  addGroup(label, students) {
    students.forEach(student => {
      this.$groups.forEach(group => {
        group.removeStudent(student);
      });
    });
    const newGroup = new Group(ClassPeriod.nextGroupId, label, this, students);
    this.$groups.push(newGroup);
    ClassPeriod.nextGroupId = ClassPeriod.nextGroupId + 1;
  }

  set removeGroup(id) {
    this.$groups = this.$groups.filter(g => g.id !== id);
  }
}

ClassPeriod.nextGroupId = 1;
