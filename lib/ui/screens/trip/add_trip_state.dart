class AddTripState {
  final bool loading;

  const AddTripState({this.loading = false});

  AddTripState copyWith({bool? loading}) {
    return AddTripState(loading: loading ?? this.loading);
  }
}
