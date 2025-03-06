/// An annotation that you want to use for the custom function.
const isolateManagerCustomWorker = IsolateManagerCustomWorker();

/// The annotation to generate a Worker JS for a specific method.
class IsolateManagerCustomWorker {
  /// The annotation to generate a custom Worker JS for a specific method.
  ///
  /// If the [name] is specified, the Worker JS will be named `<name>.js`, otherwise
  /// the name of the function will be used.
  ///
  /// If you want to put the Worker JS inside a subfolder, you can use `subfolder/name` pattern.
  ///
  /// For instance:
  ///
  /// ```dart
  /// @IsolateManagerCustomWorker('workers/add')
  /// int add(List<int> params) {
  ///   return params[0] + params[1];
  /// }
  /// ```
  ///
  /// The generated path will be:
  ///
  /// ```console
  /// web
  /// |-- workers
  /// |-- |-- add.js
  /// ```
  const IsolateManagerCustomWorker([this.name = '']);

  /// Name of the Worker JS.
  final String name;
}
