import 'dart:convert';
import 'dart:io';

// Byte packaging only: keep every original PNG unchanged.
void main() {
  final dir = Directory('assets/quizipedia');
  final pattern = RegExp(r'^flag-([a-z]{2})\.png$');
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => pattern.hasMatch(f.uri.pathSegments.last))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final flags = <String, String>{};
  for (final file in files) {
    final id = pattern
        .firstMatch(file.uri.pathSegments.last)!
        .group(1)!
        .toUpperCase();
    flags[id] = base64Encode(file.readAsBytesSync());
  }
  final output = File('assets/quizipedia/country_flag_images.json');
  output.writeAsStringSync(
    '${jsonEncode({'schema_version': 'qm-country-flag-images/v1', 'flags': flags})}\n',
  );
  stdout.writeln(
    '${flags.length} unchanged PNGs, ${output.lengthSync()} bytes',
  );
}
