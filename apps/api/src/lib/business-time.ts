/**
 * Calendar dates in the business time zone (spec §8.2): stored instants are UTC, but a date-only
 * expiry such as `2027-06-30` means 23:59:59 Asia/Damascus on that date.
 */

/** Offset of `timeZone` from UTC at `instant`, in milliseconds. */
function zoneOffsetMs(instant: Date, timeZone: string): number {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).formatToParts(instant);
  const get = (type: string) => Number(parts.find((p) => p.type === type)!.value);
  const asUtc = Date.UTC(
    get('year'),
    get('month') - 1,
    get('day'),
    get('hour'),
    get('minute'),
    get('second'),
  );
  return asUtc - Math.floor(instant.getTime() / 1000) * 1000;
}

/** The UTC instant of a wall-clock time on `date` (YYYY-MM-DD) in `timeZone`. */
export function zonedInstant(date: string, time: [number, number, number], timeZone: string): Date {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  const wall = Date.UTC(y, m - 1, d, ...time);
  // Two passes settle the offset even when the date sits next to a DST change.
  let guess = wall - zoneOffsetMs(new Date(wall), timeZone);
  guess = wall - zoneOffsetMs(new Date(guess), timeZone);
  return new Date(guess);
}

export const endOfBusinessDay = (date: string, timeZone: string) =>
  zonedInstant(date, [23, 59, 59], timeZone);
export const startOfBusinessDay = (date: string, timeZone: string) => zonedInstant(date, [0, 0, 0], timeZone);

/** The calendar date of `instant` in `timeZone`, as YYYY-MM-DD. */
export function businessDate(instant: Date, timeZone: string): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(instant);
}
