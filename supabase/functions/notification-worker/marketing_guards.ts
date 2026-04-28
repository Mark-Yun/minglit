// §50 Marketing notification guard helpers (정보통신망법 §50 준수)

// §50 ⑤: KST 21:00–07:59 야간 시간대 판별
// Accepts nowMs for testability; defaults to Date.now().
export function isNightTimeKST(nowMs = Date.now()): boolean {
  const kstHour = Math.floor((nowMs / 3600000 + 9) % 24);
  return kstHour >= 21 || kstHour < 8;
}

// §50 ⑤: 다음 KST 오전 8시까지 남은 초
export function secondsUntilKST8AM(nowMs = Date.now()): number {
  const kstMs = nowMs + 9 * 3600 * 1000;
  const kstDate = new Date(kstMs);
  const secsIntoDay =
    kstDate.getUTCHours() * 3600 + kstDate.getUTCMinutes() * 60 + kstDate.getUTCSeconds();
  return secsIntoDay < 8 * 3600
    ? 8 * 3600 - secsIntoDay
    : 24 * 3600 - secsIntoDay + 8 * 3600;
}
