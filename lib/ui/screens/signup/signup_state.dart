class SignupState {
  final bool agreed;
  final bool showPassword;

  const SignupState({this.agreed = false, this.showPassword = false});

  SignupState copyWith({bool? agreed, bool? showPassword}) {
    return SignupState(
      agreed: agreed ?? this.agreed,
      showPassword: showPassword ?? this.showPassword,
    );
  }
}
