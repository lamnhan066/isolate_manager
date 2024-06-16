import 'generate_shared.dart' as shared;
import 'generate_single.dart' as single;

void main(List<String> args) async {
  print('>> Generating the single Workers...');
  await single.generate(args);
  print('>> Generated.');
  print('>> Generating the shared Worker...');
  await shared.generate(args);
  print('>> Generated.');
}
