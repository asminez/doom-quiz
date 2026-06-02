import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { generateDeckFromContent } from "@/lib/ai";
import { minutesForScore } from "@/lib/rewards";
import {
  consumeMinutes,
  defaultState,
  grantMinutes,
  loadState,
  saveState,
  upsertDeck,
} from "@/lib/storage";
import type { BlockedApp, PersistedState, StudyDeck } from "@/lib/types";

type DoomQuizContextValue = {
  state: PersistedState;
  loading: boolean;
  activeDeck: StudyDeck | null;
  refresh: () => Promise<void>;
  setDailyBudget: (minutes: number) => Promise<void>;
  toggleApp: (id: string) => Promise<void>;
  tryOpenApp: (app: BlockedApp) => Promise<"ok" | "quiz">;
  closeSession: () => Promise<void>;
  useSessionMinute: () => Promise<void>;
  addDeck: (deck: StudyDeck) => Promise<void>;
  generateDeck: (input: {
    title: string;
    content: string;
    source: StudyDeck["source"];
  }) => Promise<StudyDeck>;
  applyQuizReward: (correct: number) => Promise<number>;
};

const DoomQuizContext = createContext<DoomQuizContextValue | null>(null);

export function DoomQuizProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<PersistedState>(defaultState());
  const [loading, setLoading] = useState(true);

  const persist = useCallback(async (next: PersistedState) => {
    setState(next);
    await saveState(next);
  }, []);

  const refresh = useCallback(async () => {
    const loaded = await loadState();
    setState(loaded);
  }, []);

  useEffect(() => {
    refresh().finally(() => setLoading(false));
  }, [refresh]);

  const activeDeck = useMemo(() => {
    if (!state.activeDeckId) return null;
    return state.decks.find((d) => d.id === state.activeDeckId) ?? null;
  }, [state.activeDeckId, state.decks]);

  const setDailyBudget = useCallback(
    async (minutes: number) => {
      const next = {
        ...state,
        dailyBudgetMinutes: minutes,
        remainingMinutes: minutes,
        usedTodayMinutes: 0,
      };
      await persist(next);
    },
    [persist, state]
  );

  const toggleApp = useCallback(
    async (id: string) => {
      const blockedApps = state.blockedApps.map((a) =>
        a.id === id ? { ...a, enabled: !a.enabled } : a
      );
      await persist({ ...state, blockedApps });
    },
    [persist, state]
  );

  const tryOpenApp = useCallback(
    async (app: BlockedApp): Promise<"ok" | "quiz"> => {
      if (!app.enabled) {
        await persist({ ...state, sessionOpenAppId: app.id });
        return "ok";
      }
      if (state.remainingMinutes <= 0) {
        return "quiz";
      }
      await persist({ ...state, sessionOpenAppId: app.id });
      return "ok";
    },
    [persist, state]
  );

  const closeSession = useCallback(async () => {
    await persist({ ...state, sessionOpenAppId: null });
  }, [persist, state]);

  const useSessionMinute = useCallback(async () => {
    if (!state.sessionOpenAppId) return;
    await persist(consumeMinutes(state, 1));
  }, [persist, state]);

  const addDeck = useCallback(
    async (deck: StudyDeck) => {
      await persist(upsertDeck(state, deck));
    },
    [persist, state]
  );

  const generateDeck = useCallback(
    async (input: {
      title: string;
      content: string;
      source: StudyDeck["source"];
    }) => {
      const deck = await generateDeckFromContent(input);
      const loaded = await loadState();
      await persist(upsertDeck(loaded, deck));
      return deck;
    },
    [persist]
  );

  const applyQuizReward = useCallback(
    async (correct: number) => {
      const mins = minutesForScore(correct, 5);
      const loaded = await loadState();
      if (mins > 0) {
        await persist(grantMinutes(loaded, mins));
      }
      return mins;
    },
    [persist]
  );

  const value: DoomQuizContextValue = {
    state,
    loading,
    activeDeck,
    refresh,
    setDailyBudget,
    toggleApp,
    tryOpenApp,
    closeSession,
    useSessionMinute,
    addDeck,
    generateDeck,
    applyQuizReward,
  };

  return (
    <DoomQuizContext.Provider value={value}>{children}</DoomQuizContext.Provider>
  );
}

export function useDoomQuiz() {
  const ctx = useContext(DoomQuizContext);
  if (!ctx) throw new Error("useDoomQuiz must be used within DoomQuizProvider");
  return ctx;
}
