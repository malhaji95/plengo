/** Saves a file response (export, template) under the name the API gives it. */
export function saveFile(blob: Blob, response: Response, fallback: string) {
  const match = /filename="([^"]+)"/.exec(response.headers.get('content-disposition') ?? '');
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = match?.[1] ?? fallback;
  a.click();
  URL.revokeObjectURL(url);
}

/** A File as base64 without the data-URL prefix. */
export function fileToBase64(file: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result).replace(/^data:[^,]*,/, ''));
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}
