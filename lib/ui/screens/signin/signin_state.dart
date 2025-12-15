class SigninState {
  final bool loading;
  final bool showPassword;

  const SigninState({this.loading = false, this.showPassword = false});

  SigninState copyWith({bool? loading, bool? showPassword}) {
    return SigninState(
      loading: loading ?? this.loading,
      showPassword: showPassword ?? this.showPassword,
    );
  }
}
