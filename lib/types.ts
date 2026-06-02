export type MemorizePoint = {
  id: string;
  term: string;
  definition: string;
};

export type QuizQuestion = {
  id: string;
  prompt: string;
  choices: [string, string, string, string];
  correctIndex: number;
};

export type StudyDeck = {
  id: string;
  title: string;
  source: "topic" | "pdf" | "text";
  points: MemorizePoint[];
  questions: QuizQuestion[];
  createdAt: number;
};

export type BlockedApp = {
  id: string;
  name: string;
  emoji: string;
  enabled: boolean;
};

export type PersistedState = {
  dailyBudgetMinutes: number;
  remainingMinutes: number;
  usedTodayMinutes: number;
  lastResetDate: string;
  blockedApps: BlockedApp[];
  decks: StudyDeck[];
  activeDeckId: string | null;
  sessionOpenAppId: string | null;
};
