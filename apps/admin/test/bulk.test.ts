// @vitest-environment node
import { deflateRawSync } from 'node:zlib';
import { describe, expect, it } from 'vitest';
import { isImageName, pairFiles } from '@/lib/bulk-pairs';
import { unzipImages } from '@/lib/zip';

const named = (...names: string[]) => names.map((name) => ({ name }));

describe('flashcard bulk pairing (§27)', () => {
  it('pairs by prefix in natural order with several naming styles', () => {
    const { pairs, unmatched } = pairFiles(
      named(
        '010-back.png',
        '002-front.jpg',
        '002-back.jpg',
        '010-front.png',
        'cell_a.webp',
        'cell_b.webp',
        'ذرة أمامي.png',
        'ذرة خلفي.png',
        'notes.png',
        'extra.png',
        '003-front.png',
      ),
    );
    expect(pairs.map((p) => [p.key, p.front?.name ?? null, p.back?.name ?? null])).toEqual([
      ['002', '002-front.jpg', '002-back.jpg'],
      ['003', '003-front.png', null],
      ['010', '010-front.png', '010-back.png'],
      ['cell', 'cell_a.webp', 'cell_b.webp'],
      ['ذرة', 'ذرة أمامي.png', 'ذرة خلفي.png'],
    ]);
    expect(unmatched.map((f) => f.name)).toEqual(['extra.png', 'notes.png']);
  });

  it('keeps a second file for the same side unmatched rather than overwriting', () => {
    const { pairs, unmatched } = pairFiles(named('1-front.png', '1-f.png', '1-back.png'));
    expect(pairs).toHaveLength(1);
    expect(unmatched.map((f) => f.name)).toEqual(['1-f.png']);
  });

  it('recognises images and skips hidden files', () => {
    expect(isImageName('a/001-front.PNG')).toBe(true);
    expect(isImageName('__MACOSX/._001-front.png')).toBe(false);
    expect(isImageName('readme.txt')).toBe(false);
  });
});

/** A tiny ZIP writer for the test: one stored and one deflated entry. */
function zip(entries: { name: string; data: Buffer; deflate: boolean }[]) {
  const locals: Buffer[] = [];
  const centrals: Buffer[] = [];
  let offset = 0;
  for (const e of entries) {
    const name = Buffer.from(e.name);
    const body = e.deflate ? deflateRawSync(e.data) : e.data;
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(e.deflate ? 8 : 0, 8);
    local.writeUInt32LE(body.length, 18);
    local.writeUInt32LE(e.data.length, 22);
    local.writeUInt16LE(name.length, 26);
    locals.push(local, name, body);
    const central = Buffer.alloc(46);
    central.writeUInt32LE(0x02014b50, 0);
    central.writeUInt16LE(e.deflate ? 8 : 0, 10);
    central.writeUInt32LE(body.length, 20);
    central.writeUInt32LE(e.data.length, 24);
    central.writeUInt16LE(name.length, 28);
    central.writeUInt32LE(offset, 42);
    centrals.push(central, name);
    offset += 30 + name.length + body.length;
  }
  const size = centrals.reduce((n, b) => n + b.length, 0);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(entries.length, 8);
  end.writeUInt16LE(entries.length, 10);
  end.writeUInt32LE(size, 12);
  end.writeUInt32LE(offset, 16);
  return new Blob([Buffer.concat([...locals, ...centrals, end])]);
}

describe('ZIP reading in the browser (§27)', () => {
  it('extracts stored and deflated images, skipping other entries', async () => {
    const png = Buffer.from('fake png bytes '.repeat(50));
    const files = await unzipImages(
      zip([
        { name: 'cards/001-front.png', data: png, deflate: true },
        { name: 'cards/001-back.webp', data: Buffer.from('webp'), deflate: false },
        { name: 'cards/readme.txt', data: Buffer.from('x'), deflate: false },
      ]),
      isImageName,
    );
    expect(files.map((f) => [f.name, f.type, f.size])).toEqual([
      ['001-front.png', 'image/png', png.length],
      ['001-back.webp', 'image/webp', 4],
    ]);
    expect(Buffer.from(await files[0]!.arrayBuffer()).equals(png)).toBe(true);
  });

  it('rejects files that are not archives', async () => {
    await expect(unzipImages(new Blob(['nope']), isImageName)).rejects.toThrow();
  });
});
