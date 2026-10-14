class AuthUser {
  const AuthUser({required this.uid, required this.phone, this.displayName});

  final String uid;
  final String phone;
  final String? displayName;
}
