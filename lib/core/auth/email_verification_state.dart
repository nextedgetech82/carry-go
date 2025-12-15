class EmailVerificationState {
  final bool sending;
  final bool verified;

  const EmailVerificationState({this.sending = false, this.verified = false});

  EmailVerificationState copyWith({bool? sending, bool? verified}) {
    return EmailVerificationState(
      sending: sending ?? this.sending,
      verified: verified ?? this.verified,
    );
  }
}
