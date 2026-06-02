import { useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  Pressable,
  ActivityIndicator,
  Alert,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import * as DocumentPicker from "expo-document-picker";
import * as FileSystem from "expo-file-system";
import { MemorizeCard } from "@/components/MemorizeCard";
import { useDoomQuiz } from "@/context/DoomQuizContext";
import { unrot, quizlet } from "@/lib/theme";

export default function StudyScreen() {
  const { activeDeck, state, generateDeck } = useDoomQuiz();
  const [topic, setTopic] = useState("");
  const [syllabus, setSyllabus] = useState("");
  const [loading, setLoading] = useState(false);
  const [mode, setMode] = useState<"topic" | "text">("topic");

  async function onGenerate() {
    const content =
      mode === "topic"
        ? `Topic to learn: ${topic.trim()}`
        : syllabus.trim();
    const title =
      mode === "topic" ? topic.trim() || "My topic" : "Syllabus deck";

    if (content.length < 20) {
      Alert.alert(
        "Need more detail",
        "Write a clearer topic or paste more syllabus text (at least a short paragraph)."
      );
      return;
    }

    setLoading(true);
    try {
      await generateDeck({
        title,
        content,
        source: mode === "topic" ? "topic" : "text",
      });
      Alert.alert("Deck ready", "7–8 memorize points and 5 quiz questions saved.");
    } catch (e) {
      Alert.alert(
        "AI error",
        e instanceof Error ? e.message : "Could not reach DeepSeek API."
      );
    } finally {
      setLoading(false);
    }
  }

  async function onPickPdf() {
    const pick = await DocumentPicker.getDocumentAsync({
      type: "application/pdf",
      copyToCacheDirectory: true,
    });
    if (pick.canceled || !pick.assets?.[0]) return;

    const asset = pick.assets[0];
    Alert.alert(
      "PDF picked",
      `${asset.name}\n\nFor this MVP, paste key excerpts below or we read plain text if embedded. Full PDF parsing ships next — DeepSeek still summarizes what you paste.`
    );

    try {
      const uri = asset.uri;
      const b64 = await FileSystem.readAsStringAsync(uri, {
        encoding: FileSystem.EncodingType.Base64,
      });
      if (b64.length < 100) return;
      setMode("text");
      setSyllabus(
        (prev) =>
          prev +
          `\n\n[PDF: ${asset.name} — paste chapter text here for best results]`
      );
    } catch {
      setMode("text");
    }
  }

  return (
    <SafeAreaView style={styles.safe} edges={["top"]}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.title}>Study deck</Text>
        <Text style={styles.sub}>
          Quizlet-style memorize points from your syllabus or an AI topic.
        </Text>

        <View style={styles.modeRow}>
          <Pressable
            onPress={() => setMode("topic")}
            style={[styles.modeBtn, mode === "topic" && styles.modeOn]}
          >
            <Text style={[styles.modeText, mode === "topic" && styles.modeTextOn]}>
              Topic
            </Text>
          </Pressable>
          <Pressable
            onPress={() => setMode("text")}
            style={[styles.modeBtn, mode === "text" && styles.modeOn]}
          >
            <Text style={[styles.modeText, mode === "text" && styles.modeTextOn]}>
              Syllabus text
            </Text>
          </Pressable>
        </View>

        {mode === "topic" ? (
          <TextInput
            style={styles.input}
            placeholder="e.g. Cell biology — mitosis & meiosis"
            placeholderTextColor={unrot.textMuted}
            value={topic}
            onChangeText={setTopic}
            multiline
          />
        ) : (
          <TextInput
            style={[styles.input, styles.inputTall]}
            placeholder="Paste syllabus, notes, or PDF excerpts..."
            placeholderTextColor={unrot.textMuted}
            value={syllabus}
            onChangeText={setSyllabus}
            multiline
          />
        )}

        <Pressable style={styles.pdfBtn} onPress={onPickPdf}>
          <Text style={styles.pdfText}>Upload PDF (beta)</Text>
        </Pressable>

        <Pressable
          style={[styles.generate, loading && { opacity: 0.7 }]}
          onPress={onGenerate}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <Text style={styles.generateText}>Generate memorize list</Text>
          )}
        </Pressable>

        {activeDeck ? (
          <View style={styles.deckSection}>
            <Text style={styles.deckTitle}>{activeDeck.title}</Text>
            <Text style={styles.deckMeta}>
              {activeDeck.points.length} points · {activeDeck.questions.length}{" "}
              gate questions
            </Text>
            {activeDeck.points.map((p, i) => (
              <MemorizeCard key={p.id} point={p} index={i} />
            ))}
          </View>
        ) : (
          <Text style={styles.empty}>
            No deck yet. {state.decks.length} saved locally after first generate.
          </Text>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: quizlet.bg },
  scroll: { padding: 20, paddingBottom: 48 },
  title: { fontSize: 28, fontWeight: "900", color: quizlet.text },
  sub: { color: quizlet.textMuted, marginTop: 6, lineHeight: 20 },
  modeRow: { flexDirection: "row", gap: 8, marginTop: 20 },
  modeBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 12,
    backgroundColor: quizlet.card,
    borderWidth: 1,
    borderColor: quizlet.border,
    alignItems: "center",
  },
  modeOn: { backgroundColor: quizlet.primarySoft, borderColor: quizlet.primary },
  modeText: { color: quizlet.textMuted, fontWeight: "700" },
  modeTextOn: { color: quizlet.primary },
  input: {
    marginTop: 16,
    backgroundColor: quizlet.card,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: quizlet.border,
    padding: 16,
    color: quizlet.text,
    fontSize: 16,
    minHeight: 56,
  },
  inputTall: { minHeight: 160, textAlignVertical: "top" },
  pdfBtn: {
    marginTop: 12,
    alignSelf: "flex-start",
    paddingVertical: 8,
  },
  pdfText: { color: quizlet.primary, fontWeight: "700" },
  generate: {
    marginTop: 16,
    backgroundColor: quizlet.primary,
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: "center",
  },
  generateText: { color: "#fff", fontWeight: "800", fontSize: 16 },
  deckSection: { marginTop: 32 },
  deckTitle: { fontSize: 22, fontWeight: "800", color: quizlet.text },
  deckMeta: { color: quizlet.textMuted, marginBottom: 16 },
  empty: { color: quizlet.textMuted, marginTop: 32, textAlign: "center" },
});
