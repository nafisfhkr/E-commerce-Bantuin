class RoleUpdateModel {
  final String email;
  final String targetRole;
  final List<String> currentRoles;

  RoleUpdateModel({
    required this.email,
    required this.targetRole,
    required this.currentRoles,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'targetRole': targetRole,
      'currentRoles': currentRoles,
    };
  }
}