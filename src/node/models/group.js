export class Group {
  constructor(id, label, classPeriod, students) {
    this.$id = id;
    this.$label = label;
    this.$class = classPeriod;
    this.$students = students || [];
  }

  get id() {
    return this.$id;
  }

  get label() {
    return this.$label;
  }

  set editLabel(newLabel) {
    this.$label = newLabel;
  }

  get class() {
    return this.$class;
  }

  set changeClass(newClass) {
    this.$class = newClass;
  }

  get students() {
    return this.$students;
  }

  set addStudent(student) {
    this.$students.push(student);
  }

  set removeStudent(student) {
    this.$students = this.$students.filter((s) => s.id !== student.id);
  }
}
