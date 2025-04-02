class UserProfile {
  int? id;
  String name;
  String email;
  String education;
  String workExperience;
  String resumePath;

  UserProfile({
    this.id,
    required this.name,
    required this.email,
    required this.education,
    required this.workExperience,
    required this.resumePath,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'name': name,
      'email': email,
      'education': education,
      'workExperience': workExperience,
      'resumePath': resumePath,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      education: map['education'],
      workExperience: map['workExperience'],
      resumePath: map['resumePath'],
    );
  }
}
