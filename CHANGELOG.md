## 5.2.1

* Update the package `web` version to support a wider range (">=0.5.1 <2.0.0").

## 5.2.0

* Bump the `web` to v1.0.0.
* Update `README`.

## 5.1.0

* Stable now.

## 5.1.0-rc.1

* Improve README.

## 5.1.0-rc

* Add `IsolateManagerShared` to be able to compute the multiple Functions.
* Generate the shared Workers by using the `@isolateManagerSharedWorker` annotation.
* Able to generate a custom Worker from a `customFunction` by using the `@isolateManagerCustomWorker` annotation.
* Improve the README.
* Various improvements and optimizations.

* The generator:
  * The default `dart run isolate_manager:generate` command will generates both single and shared Workers.
  * Use `dart run isolate_manager:generate --single` to generate only the single functions (`@isolateManagerWorker` and `@isolateManagerCustomWorker` annotations).
  * Use `dart run isolate_manager:generate_shared --shared` to generate only the shared functions (`@isolateManagerSharedWorker` annotation).

* *This is an `rc` version because the various improvements may affect some edge cases so I want to make sure it's fully backward-compatible*
  
## 5.0.5+1

* Improve README.

## 5.0.5

* Avoid using static function for the log printer.

## 5.0.4

* Update the log printer to increase the performances.
* Update benchmark.

## 5.0.3

* Improve pub score.

## 5.0.2+1

* Update some comments and fix some TYPO.
* Rename from `benchmarks` to `benchmark`.

## 5.0.2

* Change the default generated js to level `O4` (Default level when using `flutter build web`).
* Remove try catch to avoid unknown issues.
* Add more test cases and improve tests.
* Update the Worker base code.
* Update missed types.
* Update README.

## 5.0.1+1

* Re-organize the README.
* Update the description.

## 5.0.1

* Add `--omit-implicit-checks` flag when compiling to `js` to avoid type check issues.
* Add comments to the `IsolateException`.
* Update README.

## 5.0.0

* Bump sdk to `^3.3.0`.
* Add a generator to generate the Web Worker by adding the `IsolateManagerWorker` and `isolateManagerWorker` annotations (See more in README).
* Implement the `call` method to the `IsolateManager`.
* Improve the `IsolateManager.create` behavior (use a new custom function).
* Improve the type of the `customFunction` and `workerFunction`.
* Remove `autoInitialize` parameter.
* Remove deprecated methods.
* Bring the `isolate_contactor` to this package to make it lighter and easier to maintain.
* **BREAKING CHANGE:** All isolate functions MUST be updated and all Workers MUST be recompiled. See the migration guide at the bottom of the README or at the changelog of the version `5.0.0-rc.1`.

## 5.0.0-rc.11

* Implement the `call` method.
* Able to generate to WASM with `--wasm` flag (But unusable right now).

## 5.0.0-rc.10

* Fix issue with null `initialParams` in `createCustom`.
* Remove unused variable `autoMarkAsInitialized` and related code in the `base`.
* Update tests.

## 5.0.0-rc.9

* Able to generate static functions (Classs.function => Class.function.js).
* Improve the generator (only generate the needed files to reduce time).
* Improve the generated logs.

## 5.0.0-rc.8

* Add a generator to generate the Worker JS by adding the `IsolateManagerWorker` and `isolateManagerWorker` annotations.
* Update README.

## 5.0.0-rc.7

* Update to improve the score.

## 5.0.0-rc.6

* Update the CHANGELOG to show the migration guide.

## 5.0.0-rc.5

* Export the `IsolateState`.
* Update the CHANGELOG to show the migration guide.

## 5.0.0-rc.4

* Bring the `isolate_contactor` to this package and make it lighter and easier to maintain.
* Update the tests.
* Remove unneeded platforms in the example.

## 5.0.0-rc.3

* Remove deprecated methods.
* Improve the `IsolateManager.create` behavior (use a new `customFunction`).
* Improve the type of the `customFunction` and `workerFunction`.

## 5.0.0-rc.2

* Update README.
* Update homepage for beta version.

## 5.0.0-rc.1

* Bump sdk to `^3.3.0`.
* Remove `autoInitialize` parameter.
* Remove deprecated methods.
* **MIGRATION:** All isolate functions MUST be update and all Workers MUST be recompiled:
  * If you're using the `IsolateManagerFunction.workerFunction`, you need to re-generate the `JS` for the Web Worker (compile from `Dart` to `JS`). The `IsolateManagerFunction.customFunction` will be automatically applied.
  * If you're using the old method, you need to send a `initialized` signal from an `Isolate` and a `Worker`:
    * Custom function of an `Isolate`: add the `controller.initialized();` to the end of the function.
      * Before:

          ```dart
          void customFunction(dynamic params) {
            final controller = IsolateManagerController(params);
            controller.onIsolateMessage.then((value){
              // ...
            });
          }
          ```

      * After:

          ```dart
          void customFunction(dynamic params) async {
            // Do something sync or async here

            final controller = IsolateManagerController(params); 
            controller.onIsolateMessage.then((value){
              // ...
            });

            controller.initialized(); // <--
          }
          ```

    * On the Web `Worker`: add `jsSendMessage(IsolateState.initialized.toJson());` to the end of the `main` method.
      * Before:

          ```dart
          void main() {
            callbackToStream('onmessage', (MessageEvent e) {
              return js_util.getProperty(e, 'data');
            }).listen((message) {
              // ...
            });  
          }
          ```

      * After:

          ```dart
          void main() async {
            // Do something sync or async here

            callbackToStream('onmessage', (MessageEvent e) {
              return js_util.getProperty(e, 'data');
            }).listen((message) {
              // ...
            });

            jsSendMessage(IsolateState.initialized.toJson()); // <--
          }
          ```

## 4.3.1

* Export the `IsolateState`.

## 4.3.0

* Support `WASM`.
* Add benchmark tests.
* Deprecate the `IsolateFunctionHelper` in favor of the `IsolateManagerFunction`.
* Improve the `IsolateManagerFunction.workerFunction`.
* **[Experiment and Optional]** Able to send an `initialized` signal from the isolate to the main app to ensure that the isolate is ready to receive the messages from the main app. **The Migration Steps:**
  * **Step 1:**
    * If you're using the `IsolateManagerFunction.workerFunction`, you need to re-generate the `JS` for the Web Worker (compile from `Dart` to `JS`). The `IsolateManagerFunction.customFunction` will be automatically applied.
    * If you're using the old method, you need to send a `initialized` signal from an `Isolate` and a `Worker`:
      * Custom function of an `Isolate`: add the `controller.initialized();` to the end of the function.
        * Before:

          ```dart
          void customFunction(dynamic params) {
            final controller = IsolateManagerController(params);
            controller.onIsolateMessage.then((value){
              // ...
            });
          }
          ```

        * After:

          ```dart
          void customFunction(dynamic params) async {
            // Do something sync or async here

            final controller = IsolateManagerController(params); 
            controller.onIsolateMessage.then((value){
              // ...
            });

            controller.initialized(); // <--
          }
          ```

      * On the Web `Worker`: add `jsSendMessage(IsolateState.initialized.toJson());` to the end of the `main` method.
        * Before:

          ```dart
          void main() {
            callbackToStream('onmessage', (MessageEvent e) {
              return js_util.getProperty(e, 'data');
            }).listen((message) {
              // ...
            });  
          }
          ```

        * After:

          ```dart
          void main() async {
            // Do something sync or async here

            callbackToStream('onmessage', (MessageEvent e) {
              return js_util.getProperty(e, 'data');
            }).listen((message) {
              // ...
            });

            jsSendMessage(IsolateState.initialized.toJson()); // <--
          }
          ```

    * **Step 2:** Update the `create` and `createCustom` method:
      * Before:

      ```dart
      final isolate = await IsolateManager.create(
        function, 
        workerName: 'function',
      );
        ```

      * After:

      ```dart
      final isolate = await IsolateManager.create(
        function, 
        workerName: 'function',
        autoInitialize: false, // <--
      );
      ```

## 4.2.2

* Bump `isolate_contacter` to `v4.1.0`.
* Add a class `IsolateFunctionHelper` contains `customFunction` and `workerFunction`.
* Deprecate the `createOwnIsolate` in favor of the `createCustom`.
* Deprecate the `isolateWorker` in favor of the `IsolateFunctionHelper.workerFunction`.
* Improve README.

## 4.2.1+1

* Fixed the issue that causes the `sendMessage` to be unable to throw the `Exception` when the `callback` is set.
* Easier to create a Worker by using `isolateWorker` method (Detail in README).
* Remove unused methods of the `IsolateManagerController`.
* Improve README.
* Improve tests.
* Improve the code coverage.

## 4.1.5+1

* Improved README.

## 4.1.5

* Add `fetchAndDecode` example.
* Update README to `fetchAndDecode`.

## 4.1.4

* Add more complex examples (also for `Worker`).

## 4.1.3

* Add example for `Worker`.
* Update README.

## 4.1.2

* Update homepage URL.

## 4.1.1

* Add `queuesLength` to get the number of the current queuing elements.
* Add `ensureStarted` to able to wait for the `start` method to finish when you want to call the `start` method manually without `await` and wait for it later.
* Add `isStarted` to check if the `start` method is completed or not.

## 4.1.0

* Add `callback` parameter to `compute` method to fully control the final result (Useful when you need to send something like the progress value before sending the final result in the same `compute`).
* Mark `isolateManager.onMessage` as deprecated.
* Add example that uses `callback` parameter to build a progress bar before getting the final result.

## 4.0.0

* Add `sendResultError` to `IsolateManagerController` to make it easier to send the Exception from the Isolate to main app.
* `IsolateException` parameters are now `Object` and `StackTrace`.
* Add parameter type as `P` and change return type to `R`.
* Add return type as `void` to `onDispose` method.
* Change `isolateParams` from dynamic to `Object?`.
* Update tests.
* Update example.

## 3.0.1

* [Fixes]: The `compute` method will be failed if user tap on a button that calling it multiple times continuously.
* Improves tests.

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

* On Flutter >3.3.0 - `@pragma('vm:entry-point')` annotation must be added to all methods that you want to use for isolation. Read README for more information.

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
