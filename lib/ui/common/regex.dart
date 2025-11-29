class Regex {
  static final RegExp email = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
  static final RegExp phone = RegExp(r'^01[0-9]-\d{3,4}-\d{4}$');
  static final RegExp password = RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9]).{8,}$');
}
