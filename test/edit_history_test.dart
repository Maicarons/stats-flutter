import 'package:flutter_test/flutter_test.dart';

import 'package:stats_flutter/core/models/dataset.dart';
import 'package:stats_flutter/shared/edit_history.dart';

void main() {
  Dataset makeDs() {
    final ds = Dataset(
      name: 't',
      variables: [
        Variable(name: 'a'),
        Variable(name: 'b'),
      ],
      cases: [
        [1.0, 2.0],
        [3.0, 4.0],
      ],
    );
    return ds;
  }

  test('cell edit undo/redo', () {
    final ds = makeDs();
    final h = EditHistory();
    h.recordCellEdit(0, 0, 1.0, 9.0);
    ds.cases[0][0] = 9.0;

    expect(h.canUndo, isTrue);
    h.undo(ds);
    expect(ds.cases[0][0], 1.0);
    expect(h.canRedo, isTrue);

    h.redo(ds);
    expect(ds.cases[0][0], 9.0);
  });

  test('consecutive edits to same cell merge', () {
    final ds = makeDs();
    final h = EditHistory();
    h.recordCellEdit(0, 0, 1.0, 2.0);
    h.recordCellEdit(0, 0, 2.0, 3.0);
    h.recordCellEdit(0, 0, 3.0, 4.0);

    h.undo(ds);
    expect(ds.cases[0][0], 1.0);
    expect(h.canUndo, isFalse);
  });

  test('snapshot checkpoint covers structural change', () {
    final ds = makeDs();
    final h = EditHistory();

    h.checkpoint(ds);
    ds.addCase();
    ds.cases[2][0] = 99.0;
    expect(ds.nCases, 3);

    h.undo(ds);
    expect(ds.nCases, 2);
    expect(ds.cases[0][0], 1.0);

    h.redo(ds);
    expect(ds.nCases, 3);
    expect(ds.cases[2][0], 99.0);
  });

  test('new push clears redo stack', () {
    final ds = makeDs();
    final h = EditHistory();
    h.recordCellEdit(0, 0, 1.0, 2.0);
    h.undo(ds);
    expect(h.canRedo, isTrue);

    h.recordCellEdit(1, 1, 4.0, 5.0);
    expect(h.canRedo, isFalse);
  });

  test('replace semantics: snapshot restores variables and cases', () {
    final ds = makeDs();
    final h = EditHistory();
    h.checkpoint(ds);

    final other = Dataset(
      name: 'other',
      variables: [Variable(name: 'x')],
      cases: [
        [7.0],
        [8.0],
      ],
    );
    ds.variables
      ..clear()
      ..addAll(other.variables);
    ds.cases
      ..clear()
      ..addAll(other.cases);

    h.undo(ds);
    expect(ds.nVars, 2);
    expect(ds.nCases, 2);
    expect(ds.variables[0].name, 'a');
  });
}
