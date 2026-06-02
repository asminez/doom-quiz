/** Minutes unlocked after a 5-question gate quiz. */
export function minutesForScore(correct: number, total = 5): number {
  if (total <= 0) return 0;
  const ratio = correct / total;
  if (ratio >= 1) return 10;
  if (ratio >= 0.8) return 5;
  if (ratio >= 0.6) return 2;
  return 0;
}

export function rewardLabel(correct: number, total = 5): string {
  const mins = minutesForScore(correct, total);
  if (mins === 0) return "No extra time — try again later.";
  if (mins === 10) return "Perfect! +10 minutes unlocked.";
  if (mins === 5) return "Great! +5 minutes unlocked.";
  return "+2 minutes unlocked.";
}
