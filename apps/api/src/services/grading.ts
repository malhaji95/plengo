import { NORMALIZATION_VERSION, normalizeArabic } from '@plengo/arabic-normalizer';
import type { CheckResult } from '@plengo/contracts';
import { AppError } from '../lib/app-error.js';
import type { QuestionWithContent } from '../repositories/question-repository.js';

/*
 * Grading and snapshots (spec §14.3–§14.6), shared by single-question checks now and attempts from
 * Phase 7. Deterministic: exact match after normalization, no partial credit, no fuzzy matching.
 */

export type AnswerInput = { selectedOptionId?: string | undefined; writtenAnswer?: string | undefined };

/** The normalized form to compare with; a value from an older normalizer is recomputed (§14.5). */
const normalizedOf = (a: QuestionWithContent['answers'][number]) =>
  a.normalizationVersion === NORMALIZATION_VERSION ? a.answerNormalized : normalizeArabic(a.answerOriginal);

export function grade(q: QuestionWithContent, input: AnswerInput): CheckResult {
  const correctOption = q.options.find((o) => o.isCorrect) ?? null;
  if (q.type === 'written') {
    if (input.writtenAnswer === undefined || input.selectedOptionId !== undefined) {
      throw new AppError('VALIDATION_ERROR', { details: { field: 'writtenAnswer' } });
    }
    const given = normalizeArabic(input.writtenAnswer);
    const accepted = q.answers.filter((a) => a.isActive);
    return {
      isCorrect: given.length > 0 && accepted.some((a) => normalizedOf(a) === given),
      correctOptionId: null,
      correctAnswer: accepted[0]?.answerOriginal ?? null,
      explanation: q.explanation,
    };
  }
  if (!input.selectedOptionId || input.writtenAnswer !== undefined) {
    throw new AppError('VALIDATION_ERROR', { details: { field: 'selectedOptionId' } });
  }
  if (!q.options.some((o) => o.id === input.selectedOptionId)) {
    throw new AppError('VALIDATION_ERROR', { details: { field: 'selectedOptionId' } });
  }
  return {
    isCorrect: correctOption?.id === input.selectedOptionId,
    correctOptionId: correctOption?.id ?? null,
    correctAnswer: null,
    explanation: q.explanation,
  };
}

/** What the student saw, stored with each graded attempt answer so later edits never rewrite history. */
export interface QuestionSnapshot {
  questionId: string;
  contentVersion: number;
  type: QuestionWithContent['type'];
  questionText: string;
  explanation: string | null;
  options: { id: string; text: string; isCorrect: boolean }[];
  acceptedAnswers: string[];
}

export function questionSnapshot(q: QuestionWithContent): QuestionSnapshot {
  return {
    questionId: q.id,
    contentVersion: q.contentVersion,
    type: q.type,
    questionText: q.questionText,
    explanation: q.explanation,
    options: q.options.map((o) => ({ id: o.id, text: o.text, isCorrect: o.isCorrect })),
    acceptedAnswers: q.answers.filter((a) => a.isActive).map((a) => a.answerOriginal),
  };
}
