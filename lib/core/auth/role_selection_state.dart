class RoleSelectionState {
  final String? selectedRole;
  final bool loading;
  final String? error;

  const RoleSelectionState({
    this.selectedRole,
    this.loading = false,
    this.error,
  });

  RoleSelectionState copyWith({
    String? selectedRole,
    bool? loading,
    String? error,
  }) {
    return RoleSelectionState(
      selectedRole: selectedRole ?? this.selectedRole,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}
