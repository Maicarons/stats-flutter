// ignore_for_file: avoid_print
import 'dart:io';
import 'package:stats_flutter/core/io/sav_io.dart';

void main() {
  final dir = Directory(r'F:\workspace\stats-flutter\_ref\pspp-2.1.2\examples');
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.toLowerCase().endsWith('.sav')) continue;
    try {
      final bytes = f.readAsBytesSync();
      final info = SavReader.readBytes(bytes, name: f.uri.pathSegments.last);
      print('OK ${f.uri.pathSegments.last}: '
          '${info.dataset.nCases} cases x ${info.dataset.nVars} vars '
          '| ${info.dataset.variables.map((v) => v.name).take(6).join(",")} '
          '| enc=${info.header.productName}');
    } catch (e) {
      print('FAIL ${f.uri.pathSegments.last}: $e');
    }
  }
}
