import Constants from "expo-constants";
import type { MemorizePoint, QuizQuestion, StudyDeck } from "./types";

const API_URL =
  process.env.EXPO_PUBLIC_API_URL ??
  (Constants.expoConfig?.extra as { apiUrl?: string })?.apiUrl ??
  "http://localhost:8788";

type GeneratePayload = {
  title: string;
  content: string;
  source: StudyDeck["source"];
};

type AiDeckResponse = {
  title: string;
  points: Array<{ term: string; definition: string }>;
  questions: Array<{
    prompt: string;
    choices: string[];
    correctIndex: number;
  }>;
};

export async function generateDeckFromContent(
  payload: GeneratePayload
): Promise<StudyDeck> {
  const res = await fetch(`${API_URL}/generate-deck`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  const text = await res.text();
  if (!res.ok) {
    let message = text;
    try {
      const err = JSON.parse(text) as { error?: string };
      message = err.error ?? text;
    } catch {
      /* keep raw */
    }
    throw new Error(message || "Failed to generate study deck");
  }

  const data = JSON.parse(text) as AiDeckResponse;
  const id = `deck-${Date.now()}`;

  const points: MemorizePoint[] = data.points.slice(0, 8).map((p, i) => ({
    id: `${id}-p${i}`,
    term: p.term,
    definition: p.definition,
  }));

  const questions: QuizQuestion[] = data.questions.slice(0, 5).map((q, i) => {
    const choices = q.choices.slice(0, 4) as [string, string, string, string];
    while (choices.length < 4) choices.push("—");
    return {
      id: `${id}-q${i}`,
      prompt: q.prompt,
      choices,
      correctIndex: Math.min(3, Math.max(0, q.correctIndex)),
    };
  });

  return {
    id,
    title: data.title || payload.title,
    source: payload.source,
    points,
    questions,
    createdAt: Date.now(),
  };
}
