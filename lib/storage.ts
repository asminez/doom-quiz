import AsyncStorage from "@react-native-async-storage/async-storage";
import type { BlockedApp, PersistedState, StudyDeck } from "./types";

const KEY = "@doomquiz/state/v1";

const DEFAULT_APPS: BlockedApp[] = [
  { id: "instagram", name: "Instagram", emoji: "📸", enabled: true },
  { id: "tiktok", name: "TikTok", emoji: "🎵", enabled: true },
  { id: "youtube", name: "YouTube", emoji: "▶️", enabled: true },
  { id: "x", name: "X", emoji: "✖️", enabled: true },
  { id: "snapchat", name: "Snapchat", emoji: "👻", enabled: false },
  { id: "reddit", name: "Reddit", emoji: "🔴", enabled: false },
];

function todayKey(): string {
  return new Date().toISOString().slice(0, 10);
}

export function defaultState(): PersistedState {
  return {
    dailyBudgetMinutes: 45,
    remainingMinutes: 45,
    usedTodayMinutes: 0,
    lastResetDate: todayKey(),
    blockedApps: DEFAULT_APPS,
    decks: [],
    activeDeckId: null,
    sessionOpenAppId: null,
  };
}

export async function loadState(): Promise<PersistedState> {
  const raw = await AsyncStorage.getItem(KEY);
  if (!raw) return defaultState();
  try {
    const parsed = JSON.parse(raw) as PersistedState;
    return normalizeState(parsed);
  } catch {
    return defaultState();
  }
}

export async function saveState(state: PersistedState): Promise<void> {
  await AsyncStorage.setItem(KEY, JSON.stringify(state));
}

function normalizeState(state: PersistedState): PersistedState {
  const today = todayKey();
  let next = { ...state };
  if (!next.blockedApps?.length) next.blockedApps = DEFAULT_APPS;
  if (!next.lastResetDate || next.lastResetDate !== today) {
    next = {
      ...next,
      lastResetDate: today,
      remainingMinutes: next.dailyBudgetMinutes,
      usedTodayMinutes: 0,
      sessionOpenAppId: null,
    };
  }
  return next;
}

export function consumeMinutes(state: PersistedState, minutes: number): PersistedState {
  const used = Math.min(minutes, state.remainingMinutes);
  return {
    ...state,
    remainingMinutes: Math.max(0, state.remainingMinutes - used),
    usedTodayMinutes: state.usedTodayMinutes + used,
  };
}

export function grantMinutes(state: PersistedState, minutes: number): PersistedState {
  return {
    ...state,
    remainingMinutes: state.remainingMinutes + minutes,
  };
}

export function upsertDeck(state: PersistedState, deck: StudyDeck): PersistedState {
  const decks = state.decks.filter((d) => d.id !== deck.id).concat(deck);
  return { ...state, decks, activeDeckId: deck.id };
}
