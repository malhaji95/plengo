/**
 * Reads image files out of a ZIP in the browser (flashcard bulk upload, §27). Stored and deflated
 * entries are supported; deflate uses the platform's DecompressionStream.
 */
export async function unzipImages(file: Blob, accept: (name: string) => boolean): Promise<File[]> {
  const buf = new Uint8Array(await file.arrayBuffer());
  const view = new DataView(buf.buffer);
  let end = -1;
  for (let i = buf.length - 22; i >= Math.max(0, buf.length - 65_557); i--) {
    if (view.getUint32(i, true) === 0x06054b50) {
      end = i;
      break;
    }
  }
  if (end < 0) throw new Error('not a zip archive');
  const count = view.getUint16(end + 10, true);
  let p = view.getUint32(end + 16, true);
  const decoder = new TextDecoder();
  const out: File[] = [];
  for (let n = 0; n < count; n++) {
    const method = view.getUint16(p + 10, true);
    const compressedSize = view.getUint32(p + 20, true);
    const nameLength = view.getUint16(p + 28, true);
    const extraLength = view.getUint16(p + 30, true);
    const commentLength = view.getUint16(p + 32, true);
    const offset = view.getUint32(p + 42, true);
    const name = decoder.decode(buf.subarray(p + 46, p + 46 + nameLength));
    p += 46 + nameLength + extraLength + commentLength;
    if (name.endsWith('/') || !accept(name)) continue;
    const start = offset + 30 + view.getUint16(offset + 26, true) + view.getUint16(offset + 28, true);
    const raw = buf.slice(start, start + compressedSize);
    let data: Uint8Array<ArrayBuffer>;
    if (method === 0) data = raw;
    else if (method === 8) {
      const stream = new Blob([raw]).stream().pipeThrough(new DecompressionStream('deflate-raw'));
      data = new Uint8Array(await new Response(stream).arrayBuffer());
    } else continue;
    const base = name.split('/').pop()!;
    const type = /\.png$/i.test(base) ? 'image/png' : /\.webp$/i.test(base) ? 'image/webp' : 'image/jpeg';
    out.push(new File([data], base, { type }));
  }
  return out;
}
