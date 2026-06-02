import { Pressable, Text, StyleSheet, View } from "react-native";
import type { BlockedApp } from "@/lib/types";
import { unrot } from "@/lib/theme";

type Props = {
  app: BlockedApp;
  onPress: () => void;
  onLongPress?: () => void;
  locked?: boolean;
};

export function AppTile({ app, onPress, onLongPress, locked }: Props) {
  return (
    <Pressable
      onPress={onPress}
      onLongPress={onLongPress}
      style={({ pressed }) => [
        styles.tile,
        !app.enabled && styles.tileOff,
        locked && styles.tileLocked,
        pressed && { opacity: 0.85 },
      ]}
    >
      <Text style={styles.emoji}>{app.emoji}</Text>
      <Text style={styles.name}>{app.name}</Text>
      {locked && <Text style={styles.badge}>Quiz</Text>}
      {!app.enabled && <Text style={styles.off}>Off</Text>}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  tile: {
    backgroundColor: unrot.card,
    borderRadius: 20,
    padding: 16,
    borderWidth: 1,
    borderColor: unrot.cardBorder,
    width: "47%",
    minHeight: 108,
  },
  tileOff: { opacity: 0.45 },
  tileLocked: { borderColor: unrot.accent },
  emoji: { fontSize: 28 },
  name: { color: unrot.text, fontWeight: "700", fontSize: 16, marginTop: 8 },
  badge: {
    position: "absolute",
    top: 12,
    right: 12,
    color: unrot.accent,
    fontSize: 11,
    fontWeight: "800",
    textTransform: "uppercase",
  },
  off: {
    position: "absolute",
    top: 12,
    right: 12,
    color: unrot.textMuted,
    fontSize: 11,
    fontWeight: "600",
  },
});
