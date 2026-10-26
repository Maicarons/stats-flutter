/// ODS（OpenDocument 电子表格）读取器 — v1.9.0 M3
/// 取第一个工作表：table:table-row / table:table-cell（含
/// number-columns-repeated 展开），单元格按 office:value-type 取值：
/// float → 数值、string → 文本、其余（percent / currency / date…）按
/// office:value 数值或文本兜底。首行非空单元格作表头。
library;

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../models/dataset.dart';

class OdsException implements Exception {
  final String message;
  OdsException(this.message);
  @override
  String toString() => 'OdsException: $message';
}

Dataset readOdsBytes(List<int> bytes, {String name = 'ods'}) {
  Archive? zip;
  try {
    zip = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw OdsException('not a valid ODS (zip) file');
  }
  final entry = zip.findFile('content.xml');
  if (entry == null) throw OdsException('content.xml missing');
  XmlDocument doc;
  try {
    doc = XmlDocument.parse(utf8.decode(entry.content as List<int>, allowMalformed: true));
  } catch (e) {
    throw OdsException('content.xml parse failed: $e');
  }

  final tables =
      doc.findAllElements('table', namespace: '*').toList();
  if (tables.isEmpty) throw OdsException('no table found');
  final table = tables.first;

  // 命名空间属性取法：本地名匹配
  String? attr(XmlElement e, String local) {
    for (final a in e.attributes) {
      if (a.name.local == local) return a.value;
    }
    return null;
  }

  final rows = <List<String>>[];
  for (final tr in table.findElements('table-row', namespace: '*')) {
    final rowRepeat =
        int.tryParse(attr(tr, 'number-rows-repeated') ?? '1') ?? 1;
    final cells = <String>[];
    for (final tc in tr.findElements('table-cell', namespace: '*')) {
      final repeat =
          int.tryParse(attr(tc, 'number-columns-repeated') ?? '1') ?? 1;
      final valueType = attr(tc, 'value-type');
      String text;
      if (valueType == 'float' ||
          valueType == 'percentage' ||
          valueType == 'currency') {
        text = attr(tc, 'value') ?? tc.innerText.trim();
      } else {
        text = attr(tc, 'string-value') ?? tc.innerText.trim();
      }
      // 列展开（行尾空占位可能重复上千列，封顶防炸）
      final take = repeat > 4096 ? 1 : repeat;
      for (var i = 0; i < take; i++) {
        cells.add(text);
      }
    }
    // 去掉行尾空单元格；整行空（常见于尾部 number-rows-repeated 占位）跳过
    while (cells.isNotEmpty && cells.last.isEmpty) {
      cells.removeLast();
    }
    if (cells.isEmpty) continue;
    rows.add(cells);
    for (var i = 1; i < rowRepeat && i < 16; i++) {
      rows.add(List.of(cells));
    }
  }

  if (rows.isEmpty) throw OdsException('empty sheet');
  final headers = [for (var c = 0; c < rows.first.length; c++) 'V${c + 1}'];
  final headerRow = rows.first;
  final body = rows.skip(1).toList();
  return Dataset.fromRows(
    headers: [
      for (var c = 0; c < headerRow.length; c++)
        headerRow[c].isEmpty ? headers[c] : headerRow[c],
    ],
    rows: body,
    name: name,
  );
}
