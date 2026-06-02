import { useState } from "react";
import { Pressable, Text, StyleSheet, View } from "react-native";
import type { MemorizePoint } from "@/lib/types";
import { quizlet } from "@/lib/theme";

type Props = { point: MemorizePoint; index: number };

export function MemorizeCard({ point, index }: Props) {
  const [flipped, setFlipped] = useState(false);

  return (
    <Pressable onPress={() => setFlipped((f) => !f)} style={styles.card}>
      <Text style={styles.index}>{index + 1}</Text>
      <View style={styles.body}>
        <Text style={styles.hint}>{flipped ? "Definition" : "Term"}</Text>
        <Text style={styles.main}>
          {flipped ? point.definition : point.term}
        </Text>
        <Text style={styles.tap}>Tap to flip</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: quizlet.card,
    borderRadius: 16,
    padding: 20,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: quizlet.border,
    minHeight: 140,
  },
  index: {
    color: quizlet.primary,
    fontWeight: "800",
    fontSize: 12,
    marginBottom: 8,
  },
  body: { flex: 1, justifyContent: "center" },
  hint: {
    color: quizlet.textMuted,
    fontSize: 12,
    fontWeight: "600",
    textTransform: "uppercase",
    letterSpacing: 0.6,
  },
  main: {
    color: quizlet.text,
    fontSize: 20,
    fontWeight: "700",
    marginTop: 8,
    lineHeight: 28,
  },
  tap: { color: quizlet.textMuted, fontSize: 12, marginTop: 16 },
});
