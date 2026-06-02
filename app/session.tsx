import { useEffect, useRef } from "react";
import { View, Text, StyleSheet, Pressable } from "react-native";
import { useLocalSearchParams, useRouter } from "expo-router";
import { SafeAreaView } from "react-native-safe-area-context";
import { useDoomQuiz } from "@/context/DoomQuizContext";
import { unrot } from "@/lib/theme";

/** Simulated app session — ticks down 1 min / 60s while "in app". */
export default function SessionScreen() {
  const router = useRouter();
  const { appId } = useLocalSearchParams<{ appId?: string }>();
  const { state, useSessionMinute, closeSession } = useDoomQuiz();
  const tickRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const app = state.blockedApps.find((a) => a.id === appId);

  useEffect(() => {
    tickRef.current = setInterval(() => {
      useSessionMinute();
    }, 60000);

    return () => {
      if (tickRef.current) clearInterval(tickRef.current);
    };
  }, [useSessionMinute]);

  useEffect(() => {
    if (state.remainingMinutes <= 0) {
      router.replace({ pathname: "/gate-quiz", params: { appId } });
    }
  }, [state.remainingMinutes, appId, router]);

  async function onLeave() {
    await closeSession();
    router.back();
  }

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.card}>
        <Text style={styles.emoji}>{app?.emoji ?? "📱"}</Text>
        <Text style={styles.name}>{app?.name ?? "App"}</Text>
        <Text style={styles.sub}>Simulated session</Text>
        <Text style={styles.timer}>{state.remainingMinutes} min remaining</Text>
        <Text style={styles.hint}>
          When time hits zero, the gate quiz appears automatically.
        </Text>
        <Pressable style={styles.leave} onPress={onLeave}>
          <Text style={styles.leaveText}>Leave app</Text>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: unrot.bg,
    justifyContent: "center",
    padding: 24,
  },
  card: {
    backgroundColor: unrot.card,
    borderRadius: 24,
    padding: 32,
    alignItems: "center",
    borderWidth: 1,
    borderColor: unrot.cardBorder,
  },
  emoji: { fontSize: 64 },
  name: { color: unrot.text, fontSize: 28, fontWeight: "900", marginTop: 12 },
  sub: { color: unrot.textMuted, marginTop: 4 },
  timer: { color: unrot.accent, fontSize: 22, fontWeight: "800", marginTop: 24 },
  hint: {
    color: unrot.textMuted,
    textAlign: "center",
    marginTop: 12,
    lineHeight: 20,
  },
  leave: {
    marginTop: 32,
    backgroundColor: unrot.accent,
    paddingHorizontal: 28,
    paddingVertical: 14,
    borderRadius: 14,
  },
  leaveText: { color: "#fff", fontWeight: "800" },
});
