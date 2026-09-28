import { describe, expect, it } from 'vitest';
import { parseCsv, readXlsx, TabularError, toCsv, toXlsx, zip } from '../src/lib/tabular.js';

const table = {
  header: ['subject_code', 'question', 'option_a'],
  rows: [
    ['g12-physics', 'ما وحدة القوة، "النيوتن"؟', '=SUM(A1)'],
    ['g12-physics', 'سطر\nثانٍ', '-5'],
    ['g12-physics', '', ''],
  ],
};

describe('tabular readers (§27)', () => {
  it('round-trips CSV, including quotes, newlines, Arabic and neutralised formulas', () => {
    const rows = parseCsv(toCsv(table));
    expect(rows).toEqual([table.header, ...table.rows]);
  });

  it('reads semicolon CSV and LF endings, and rejects an unterminated quote', () => {
    expect(parseCsv(Buffer.from('a;b\n1;"x;y"\n'))).toEqual([
      ['a', 'b'],
      ['1', 'x;y'],
    ]);
    expect(() => parseCsv(Buffer.from('a,b\n"open'))).toThrow(TabularError);
  });

  it('round-trips our own XLSX', () => {
    expect(readXlsx(toXlsx(table))).toEqual([table.header, ...table.rows.map((r) => r.map((c) => c))]);
  });

  it('reads Excel-style workbooks: shared strings, rich text, numbers, booleans, gaps', () => {
    const files: [string, string][] = [
      [
        'xl/workbook.xml',
        '<workbook xmlns:r="r"><sheets><sheet name="Q" sheetId="1" r:id="rId7"/></sheets></workbook>',
      ],
      [
        'xl/_rels/workbook.xml.rels',
        '<Relationships><Relationship Id="rId7" Type="ws" Target="worksheets/data.xml"/></Relationships>',
      ],
      [
        'xl/sharedStrings.xml',
        '<sst><si><t>question</t></si><si><r><t>عاصمة </t></r><r><t xml:space="preserve">سوريا؟</t></r><rPh><t>x</t></rPh></si><si><t>A &amp; B</t></si></sst>',
      ],
      [
        'xl/worksheets/data.xml',
        '<worksheet><sheetData>' +
          '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="C1" t="inlineStr"><is><t>n</t></is></c></row>' +
          '<row r="3"><c r="A3" t="s"><v>1</v></c><c r="B3" t="b"><v>1</v></c><c r="C3"><v>3.5</v></c><c r="D3" t="s"><v>2</v></c></row>' +
          '</sheetData></worksheet>',
      ],
    ];
    const book = zip(files.map(([name, text]) => ({ name, data: Buffer.from(text) })));
    expect(readXlsx(book)).toEqual([['question', '', 'n'], [], ['عاصمة سوريا؟', 'true', '3.5', 'A & B']]);
  });

  it('refuses non-archives and oversized entries', () => {
    expect(() => readXlsx(Buffer.from('not a zip'))).toThrow(TabularError);
    // A 60 MB entry of zeros compresses to a few KB: refused by its declared size.
    const bomb = zip([{ name: 'xl/workbook.xml', data: Buffer.alloc(60 * 1024 * 1024) }]);
    expect(bomb.length).toBeLessThan(200_000);
    expect(() => readXlsx(bomb)).toThrow(TabularError);
  });
});
