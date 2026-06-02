import { useRouter } from "expo-router";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Pressable,
  Alert,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { AppTile } from "@/components/AppTile";
import { TimeRing } from "@/components/TimeRing";
import { useDoomQuiz } from "@/context/DoomQuizContext";
import { unrot } from "@/lib/theme";

const BUDGET_OPTIONS = [30, 45, 60, 90];

export default function FocusScreen() {
  const router = useRouter();
  const { state, activeDeck, tryOpenApp, setDailyBudget, toggleApp } =
    useDoomQuiz();
  const locked = state.remainingMinutes <= 0;
  const enabledApps = state.blockedApps.filter((a) => a.enabled);

  async function onAppPress(appId: string) {
    const app = state.blockedApps.find((a) => a.id === appId);
    if (!app) return;

    if (!activeDeck) {
      Alert.alert(
        "Add a study deck first",
        "Upload syllabus or enter a topic on the Study tab so gate quizzes have material.",
        [{ text: "Go to Study", onPress: () => router.push("/study") }]
      );
      return;
    }

    const result = await tryOpenApp(app);
    if (result === "quiz") {
      router.push({ pathname: "/gate-quiz", params: { appId: app.id } });
      return;
    }
    router.push({ pathname: "/session", params: { appId: app.id } });
  }

  return (
    <SafeAreaView style={styles.safe} edges={["top"]}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.brand}>doomquiz</Text>
        <Text style={styles.tagline}>Earn scroll time with your syllabus</Text>

        <View style={styles.ringWrap}>
          <TimeRing
            remaining={state.remainingMinutes}
            total={state.dailyBudgetMinutes}
          />
        </View>

        <Text style={styles.used}>
          {state.usedTodayMinutes} min used today · budget {state.dailyBudgetMinutes} min
        </Text>

        {locked && (
          <View style={styles.banner}>
            <Text style={styles.bannerTitle}>Time's up</Text>
            <Text style={styles.bannerBody}>
              Opening a blocked app triggers a 5-question quiz. Score 3+ to unlock
              more minutes.
            </Text>
          </View>
        )}

        <View style={styles.budgetRow}>
          {BUDGET_OPTIONS.map((m) => (
            <Pressable
              key={m}
              onPress={() => setDailyBudget(m)}
              style={[
                styles.budgetChip,
                state.dailyBudgetMinutes === m && styles.budgetChipOn,
              ]}
            >
              <Text
                style={[
                  styles.budgetText,
                  state.dailyBudgetMinutes === m && styles.budgetTextOn,
                ]}
              >
                {m}m
              </Text>
            </Pressable>
          ))}
        </View>

        <Text style={styles.section}>Blocked apps</Text>
        <Text style={styles.sectionHint}>
          Tap to open · long-press to toggle block. Real OS shields need Screen Time
          (iOS) next.
        </Text>

        <View style={styles.grid}>
          {state.blockedApps.map((app) => (
            <AppTile
              key={app.id}
              app={app}
              locked={locked && app.enabled}
              onPress={() => onAppPress(app.id)}
              onLongPress={() => toggleApp(app.id)}
            />
          ))}
        </View>

        {enabledApps.length === 0 && (
          <Text style={styles.warn}>Enable at least one app to block.</Text>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: unrot.bg },
  scroll: { padding: 20, paddingBottom: 40 },
  brand: {
    color: unrot.text,
    fontSize: 28,
    fontWeight: "900",
    letterSpacing: -0.5,
  },
  tagline: { color: unrot.textMuted, marginTop: 4, fontSize: 15 },
  ringWrap: { alignItems: "center", marginVertical: 28 },
  used: { textAlign: "center", color: unrot.textMuted, fontSize: 13 },
  banner: {
    backgroundColor: unrot.accentSoft,
    borderRadius: 16,
    padding: 16,
    marginTop: 20,
    borderWidth: 1,
    borderColor: unrot.accent,
  },
  bannerTitle: { color: unrot.accent, fontWeight: "800", fontSize: 16 },
  bannerBody: { color: unrot.text, marginTop: 6, lineHeight: 20 },
  budgetRow: {
    flexDirection: "row",
    justifyContent: "center",
    gap: 8,
    marginTop: 24,
  },
  budgetChip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: unrot.card,
    borderWidth: 1,
    borderColor: unrot.cardBorder,
  },
  budgetChipOn: {
    backgroundColor: unrot.accentSoft,
    borderColor: unrot.accent,
  },
  budgetText: { color: unrot.textMuted, fontWeight: "700" },
  budgetTextOn: { color: unrot.accent },
  section: {
    color: unrot.text,
    fontSize: 20,
    fontWeight: "800",
    marginTop: 32,
  },
  sectionHint: { color: unrot.textMuted, fontSize: 13, marginTop: 4 },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "space-between",
    gap: 12,
    marginTop: 16,
  },
  warn: { color: unrot.danger, marginTop: 12, textAlign: "center" },
});
