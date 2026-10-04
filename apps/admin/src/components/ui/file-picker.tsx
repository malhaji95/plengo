'use client';

import { Upload, X } from 'lucide-react';
import { useEffect, useRef } from 'react';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/input';

/**
 * An Arabic file field. The browser's own control labels itself in the browser language ("Choose
 * File · No file chosen"), so the real input stays visually hidden behind an Arabic button and the
 * chosen file's name.
 */
export function FilePicker({
  id,
  label,
  accept,
  file,
  onChange,
}: {
  id: string;
  label: string;
  accept: string;
  file: File | null;
  onChange: (file: File | null) => void;
}) {
  const input = useRef<HTMLInputElement>(null);

  // Clearing the selection from outside (after an upload) also clears the hidden input, so picking
  // the same file again still fires a change.
  useEffect(() => {
    if (!file && input.current) input.current.value = '';
  }, [file]);

  return (
    <div className="space-y-1">
      <Label htmlFor={id}>{label}</Label>
      <div className="flex items-center gap-2">
        <Button type="button" variant="outline" size="sm" onClick={() => input.current?.click()}>
          <Upload className="size-4" aria-hidden />
          {file ? 'تغيير الملف' : 'اختيار ملف'}
        </Button>
        <span className="max-w-48 truncate text-sm text-muted" dir="auto">
          {file ? file.name : 'لم يُختر ملف'}
        </span>
        {file ? (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            aria-label={`إزالة ${label}`}
            onClick={() => onChange(null)}
          >
            <X className="size-4" aria-hidden />
          </Button>
        ) : null}
      </div>
      <input
        ref={input}
        id={id}
        type="file"
        accept={accept}
        tabIndex={-1}
        className="sr-only"
        onChange={(e) => onChange(e.target.files?.[0] ?? null)}
      />
    </div>
  );
}
