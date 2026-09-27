'use client';

import { ArrowRight } from 'lucide-react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Suspense } from 'react';
import { QuestionEditor } from '@/components/questions/question-editor';

function NewQuestion() {
  const params = useSearchParams();
  return (
    <QuestionEditor
      initialPlacement={{
        subjectId: params.get('subjectId'),
        track: params.get('track') ?? 'general',
        unitId: params.get('unitId'),
        lessonId: params.get('lessonId'),
      }}
    />
  );
}

export default function NewQuestionPage() {
  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <Link href="/questions" className="inline-flex items-center gap-1 text-sm text-brand">
        <ArrowRight className="size-4" aria-hidden />
        كل الأسئلة
      </Link>
      <h1 className="text-xl font-semibold">سؤال جديد</h1>
      <Suspense>
        <NewQuestion />
      </Suspense>
    </div>
  );
}
