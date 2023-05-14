## 3.0.0

* Bumped Dart sdk to `>=2.18.0 <4.0.0`.

## 2.2.0+5

* Add `isolates_helper` to README.

## 2.2.0+4

* Improves README.
* Add `IsolateManager.debugLogPrefix` to set the prefix debug logs.

## 2.2.0+2

* Improve `worker.dart` imports.
* Use new `worker.dart` in testing.

## 2.2.0+1

* Improve function descriptions.
* Improve README for catching exception with `createOwnIsolate`.

## 2.2.0

* Support `try-catch` block for all platforms including Worker on Web.
* Update `worker.dart` to support `try-catch` block.
* Change all the debug logs prefix to `[Isolate Mangager]`.
* Add test for `try-catch`.
* Increase min SDK to 2.15.0.

## 2.1.2+1

* Improve pub scores.

## 2.1.2

* The method `.start()` is now optional, the plugin will automatically call this method when using `.compute` for the first time, so you have 3 way to create the instance:

    1. Basic usage:

    ``` dart
    IsolateManager<int> isolateManager = IsolateManager.create(
      fibonacci,
      concurrent: 4,
    );

    await isolateManager.start();
    ```

    2. Use `start` without `await`:

    ``` dart
    IsolateManager<int> isolateManager = IsolateManager.create(
      fibonacci,
      concurrent: 4,
    );

    isolateManager.start();
    ```

    3. Use `start` when creating the instance:

    ``` dart
    IsolateManager<int> isolateManager = IsolateManager.create(
      fibonacci,
      concurrent: 4,
    )..start();
    ```

## 2.1.1

* On Flutter >3.3.0 - `@pragma('vm:entry-point')` anotation must be added to all methods that you want to use for isolation. Read README for more information.

## 2.1.0

* **[BREADKING CHANGE]**: Change the parameter name from `numOfIsolates` to `concurrent`.
* Update dependencies.

## 2.0.2+3

* Improve README.

## 2.0.2+2

* Changes the name from `function_name` to `worker`.
* Improves `worker.dart` form.
* Improves README.

## 2.0.2

* Fixes issue in `restart` and `stop` methods.

## 2.0.1+3

* Improve function headers.

## 2.0.1+2

* Update function headers.
* Update README.
* Update dependencies.

## 2.0.1+1

* Update base `function_name.dart` to make it works with `FutureOr` function.
* Add `function_name.js` to example and create example for it.

## 2.0.1

* Remove useless `await` in README.
* Downgrade Dart SDK min version to `2.12.0`.

## 2.0.0

* **NO BREAKING CHANGE**
* Add `Worker` for Web platform (real Isolate on Web). Read README for more details.

## 1.0.0+1

* Update README

## 1.0.0

* **BREAKING CHANGE:** Change `isolateFunction` parameter of `createOwnIsolate` method from named to required parameter.
* Added `initialParams` parameter to `createOwnIsolate` method.
* Added `initialParams` getter to `IsolateManagerController`.
* Bring to stable version.

## 0.1.0

* Update example

## 0.0.1

* Initial release
