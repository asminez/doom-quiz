import { useMemo, useState } from "react";
import { View, Text, StyleSheet, Pressable } from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { QuizOption } from "@/components/QuizOption";
import { useDoomQuiz } from "@/context/DoomQuizContext";
import { rewardLabel } from "@/lib/rewards";
import { quizlet } from "@/lib/theme";

export default function GateQuizScreen() {
  const router = useRouter();
  const { appId } = useLocalSearchParams<{ appId?: string }>();
  const { activeDeck, state, applyQuizReward } = useDoomQuiz();
  const questions = activeDeck?.questions ?? [];

  const [index, setIndex] = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [correctCount, setCorrectCount] = useState(0);
  const [finished, setFinished] = useState(false);
  const [rewardMinutes, setRewardMinutes] = useState(0);

  const appName = useMemo(() => {
    return state.blockedApps.find((a) => a.id === appId)?.name ?? "App";
  }, [appId, state.blockedApps]);

  const q = questions[index];

  function onSelect(choiceIndex: number) {
    if (selected !== null || !q) return;
    setSelected(choiceIndex);
    if (choiceIndex === q.correctIndex) {
      setCorrectCount((c) => c + 1);
    }
  }

  async function onNext() {
    if (!q) return;
    if (index < questions.length - 1) {
      setIndex((i) => i + 1);
      setSelected(null);
      return;
    }
    const mins = await applyQuizReward(correctCount);
    setRewardMinutes(mins);
    setFinished(true);
  }

  if (!activeDeck || questions.length === 0) {
    return (
      <SafeAreaView style={styles.safe}>
        <Text style={styles.title}>No quiz loaded</Text>
        <Pressable onPress={() => router.back()} style={styles.btn}>
          <Text style={styles.btnText}>Back</Text>
        </Pressable>
      </SafeAreaView>
    );
  }

  if (finished) {
    return (
      <SafeAreaView style={styles.safe}>
        <View style={styles.result}>
          <Text style={styles.score}>
            {correctCount}/{questions.length}
          </Text>
          <Text style={styles.resultTitle}>{rewardLabel(correctCount)}</Text>
          {rewardMinutes > 0 ? (
            <Pressable
              style={styles.btn}
              onPress={() =>
                router.replace({ pathname: "/session", params: { appId } })
              }
            >
              <Text style={styles.btnText}>Open {appName}</Text>
            </Pressable>
          ) : (
            <Pressable style={styles.btnSecondary} onPress={() => router.back()}>
              <Text style={styles.btnSecondaryText}>Back to focus</Text>
            </Pressable>
          )}
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.header}>
        <Text style={styles.kicker}>Gate quiz · {appName}</Text>
        <Text style={styles.progress}>
          {index + 1} / {questions.length}
        </Text>
      </View>

      <Text style={styles.prompt}>{q.prompt}</Text>

      <View style={styles.options}>
        {q.choices.map((choice, i) => {
          let result: "correct" | "wrong" | null = null;
          if (selected !== null) {
            if (i === q.correctIndex) result = "correct";
            else if (i === selected) result = "wrong";
          }
          return (
            <QuizOption
              key={i}
              label={choice}
              selected={selected === i}
              result={result}
              disabled={selected !== null}
              onPress={() => onSelect(i)}
            />
          );
        })}
      </View>

      {selected !== null && (
        <Pressable style={styles.btn} onPress={onNext}>
          <Text style={styles.btnText}>
            {index < questions.length - 1 ? "Next" : "See results"}
          </Text>
        </Pressable>
      )}

      <Text style={styles.legend}>
        5/5 → +10 min · 4/5 → +5 · 3/5 → +2 · below 3 → none
      </Text>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: quizlet.bg, padding: 20 },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  kicker: { color: quizlet.textMuted, fontWeight: "700" },
  progress: { color: quizlet.primary, fontWeight: "800" },
  prompt: {
    fontSize: 24,
    fontWeight: "800",
    color: quizlet.text,
    marginTop: 24,
    lineHeight: 32,
  },
  options: { marginTop: 28, flex: 1 },
  btn: {
    backgroundColor: quizlet.primary,
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: "center",
    marginTop: 8,
  },
  btnText: { color: "#fff", fontWeight: "800", fontSize: 16 },
  btnSecondary: {
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: "center",
    borderWidth: 2,
    borderColor: quizlet.border,
    marginTop: 16,
  },
  btnSecondaryText: { color: quizlet.text, fontWeight: "700" },
  legend: {
    textAlign: "center",
    color: quizlet.textMuted,
    fontSize: 12,
    marginTop: 16,
    marginBottom: 8,
  },
  result: { flex: 1, justifyContent: "center", alignItems: "center" },
  score: { fontSize: 56, fontWeight: "900", color: quizlet.primary },
  resultTitle: {
    fontSize: 18,
    color: quizlet.text,
    textAlign: "center",
    marginTop: 12,
    paddingHorizontal: 24,
  },
  title: { fontSize: 22, fontWeight: "800", color: quizlet.text },
});
