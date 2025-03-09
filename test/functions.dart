import 'dart:convert';

import 'package:isolate_manager/isolate_manager.dart';

import 'models/custom_isolate_exception.dart';

@isolateManagerWorker
ImNum throwsIsolateException(ImNum number) {
  throw const IsolateException('IsolateException');
}

@isolateManagerWorker
ImNum throwsUnsupportedImTypeException(ImNum number) {
  throw const UnsupportedImTypeException(
    'UnsupportedImTypeException',
  );
}

@isolateManagerWorker
ImNum throwsCustomIsolateException(ImNum number) {
  throw const CustomIsolateException('CustomIsolateException');
}

@isolateManagerWorker
int fibonacci(int n) {
  if (n < 0) throw StateError('n<0');
  if (n == 0) return 0;
  if (n == 1) return 1;

  var f1 = 0;
  var f2 = 1;
  var r = 1;

  for (var i = 2; i <= n; i++) {
    r = f1 + f2;
    f1 = f2;
    f2 = r;
  }

  return r;
}

@isolateManagerWorker
Future<int> fibonacciFuture(int n) async {
  if (n < 0) throw StateError('n<0');
  if (n == 0) return 0;
  if (n == 1) return 1;

  var f1 = 0;
  var f2 = 1;
  var r = 1;

  for (var i = 2; i <= n; i++) {
    r = f1 + f2;
    f1 = f2;
    f2 = r;
  }

  return r;
}

@isolateManagerWorker
int fibonacciRecursive(int n) {
  if (n == 0) return 0;
  if (n == 1) return 1;

  return fibonacciRecursive(n - 1) + fibonacciRecursive(n - 2);
}

@isolateManagerWorker
List<dynamic> aStringList(List<dynamic> params) {
  return params;
}

@isolateManagerSharedWorker
@isolateManagerWorker
Map<dynamic, dynamic> aDynamicMap(Map<dynamic, dynamic> params) {
  return params;
}

@isolateManagerWorker
List<dynamic> a2DTo1DList(List<dynamic> params) {
  return params.map((e) => (e as List).join()).toList();
}

@isolateManagerWorker
List<dynamic> a1DTo2DList(List<dynamic> params) {
  final result = <List<dynamic>>[<dynamic>[], <dynamic>[]];
  for (var i = 0; i < params.length; i++) {
    if (i.isEven) {
      result[0].add(params[i]);
    } else {
      result[1].add(params[i]);
    }
  }
  return result;
}

Future<void> isolateFunction(dynamic params) async {
  await IsolateManagerFunction.customFunction<int, int>(
    params,
    onEvent: (IsolateManagerController<int, int> controller, int message) {
      try {
        final result = fibonacci(message);
        controller.sendResult(result);
      } catch (err, stack) {
        controller.sendResultError(IsolateException(err, stack));
      }
      return 0;
    },
    onInit: (IsolateManagerController<int, int> controller) {},
    onDispose: (IsolateManagerController<int, int> controller) {},
    autoHandleException: false,
    autoHandleResult: false,
  );
}

@pragma('vm:entry-point')
void isolateFunctionWithAutomaticallyHandlers(dynamic params) {
  IsolateManagerFunction.customFunction<int, int>(
    params,
    onEvent: (IsolateManagerController<int, int> controller, int message) {
      return fibonacci(message);
    },
    onInit: (IsolateManagerController<int, int> controller) {},
    onDispose: (IsolateManagerController<int, int> controller) {},
  );
}

@isolateManagerCustomWorker
void isolateCallbackFunction(dynamic params) {
  IsolateManagerFunction.customFunction(
    params,
    onEvent: (
      IsolateManagerController<Object?, Object?> controller,
      Object? message,
    ) {
      try {
        for (var i = 0; i < 10; i++) {
          controller.sendResult(jsonEncode(<String, String>{'source': '$i'}));
        }

        controller.sendResult(jsonEncode(<String, String>{'data': 'data'}));
      } catch (err, stack) {
        controller.sendResultError(IsolateException(err, stack));
      }

      // Just returns something that unused to complete this method.
      return '';
    },
    autoHandleException: false,
    autoHandleResult: false,
  );
}

@isolateManagerCustomWorker
void isolateCallbackSimpleFunction(dynamic params) {
  IsolateManagerFunction.customFunction(
    params,
    onEvent: (
      IsolateManagerController<Object?, Object?> controller,
      Object? message,
    ) {
      for (var i = 0; i < 10; i++) {
        controller.sendResult(jsonEncode(<String, String>{'source': '$i'}));
      }

      return jsonEncode(<String, Object?>{'data': message});
    },
  );
}

@isolateManagerCustomWorker
void isolateCallbackSimpleFunctionWithSpecifiedType(dynamic params) {
  IsolateManagerFunction.customFunction<String, int>(
    params,
    onEvent: (IsolateManagerController<String, int> controller, int message) {
      for (var i = 0; i < 10; i++) {
        controller.sendResult(jsonEncode(<String, String>{'source': '$i'}));
      }

      return jsonEncode(<String, int>{'data': message});
    },
  );
}

@isolateManagerSharedWorker
@isolateManagerWorker
ImNum isolateTypeNum(ImNum number) {
  return ImNum(number.unwrap);
}

@isolateManagerSharedWorker
@isolateManagerWorker
ImString isolateTypeString(ImString string) {
  return ImString(string.unwrap);
}

@isolateManagerSharedWorker
@isolateManagerWorker
ImBool isolateTypeBool(ImBool boolean) {
  return ImBool(boolean.unwrap);
}

@isolateManagerSharedWorker
@isolateManagerWorker
ImList isolateTypeList(ImList numbers) {
  return ImList(numbers.unwrap.map((e) => ImString('$e')).toList());
}

@isolateManagerSharedWorker
@isolateManagerWorker
ImMap isolateTypeMap(ImList numbers) {
  return ImMap(
    Map.fromEntries(
      numbers.unwrap.map(
        (e) => MapEntry(ImString('$e'), ImNum(e as num)),
      ),
    ),
  );
}

@isolateManagerWorker
ImMap isolateTypeMapToMap(ImMap numbers) {
  return ImMap(
    numbers.toMap().map(
          (k, v) => MapEntry(ImString('${k.unwrap}'), v),
        ),
  );
}

@isolateManagerSharedWorker
@isolateManagerWorker
int? isolateNullableInt(int? number) {
  return number;
}

@pragma('vm:entry-point')
int errorFunction(List<int> value) {
  if (value[0] == 50) {
    return throw StateError('The exception is threw at value[0] = ${value[0]}');
  }
  return value[0] + value[1];
}

@pragma('vm:entry-point')
Future<int> errorFunctionFuture(List<int> value) async {
  await Future<void>.delayed(const Duration(seconds: 1));

  if (value[0] == 50) {
    return throw StateError('The exception is threw at value[0] = ${value[0]}');
  }
  return value[0] + value[1];
}

int addWithoutWorker(List<int> params) => params[0] + params[1];

@isolateManagerSharedWorker
Future<double> addFuture(List<double> values) async {
  return values[0] + values[1];
}

@isolateManagerSharedWorker
int add(List<int> values) {
  return values[0] + values[1];
}

@isolateManagerSharedWorker
int addException(dynamic values) {
  return throw Exception('Has Exception');
}

@isolateManagerSharedWorker
String concat(List<String> params) {
  return '${params[0]} ${params[1]}';
}

@isolateManagerSharedWorker
List<List<String>> complexReturn(List<List<String>> params) {
  return params;
}
