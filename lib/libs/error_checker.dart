class PossibleError {
  final String errorMessage;

  ///
  /// If this function returns false, [errorMessage] will be shown.
  /// If [invert] is true, [errorMessage] will be shown when this function returns true.
  ///
  final Future<bool> Function() checkFunction;
  final bool invert;

  const PossibleError(this.errorMessage, this.checkFunction,
      {this.invert = false});

  Future<bool> check() async {
    var result = await checkFunction();
    print(result);
    return invert ? !result : result;
  }
}
