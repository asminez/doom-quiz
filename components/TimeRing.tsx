import { View, Text, StyleSheet } from "react-native";
import { unrot } from "@/lib/theme";

type Props = {
  remaining: number;
  total: number;
  size?: number;
};

export function TimeRing({ remaining, total, size = 168 }: Props) {
  const pct = total > 0 ? Math.min(1, remaining / total) : 0;
  const stroke = 10;
  const r = (size - stroke) / 2;
  const circumference = 2 * Math.PI * r;
  const dash = circumference * pct;

  return (
    <View style={[styles.wrap, { width: size, height: size }]}>
      <View
        style={[
          styles.track,
          {
            width: size,
            height: size,
            borderRadius: size / 2,
            borderWidth: stroke,
            borderColor: unrot.ringTrack,
          },
        ]}
      />
      <View
        style={[
          styles.progress,
          {
            width: size,
            height: size,
            borderRadius: size / 2,
            borderWidth: stroke,
            borderColor: pct > 0.2 ? unrot.accent : unrot.danger,
            borderTopColor: "transparent",
            borderRightColor: pct > 0.5 ? unrot.accent : "transparent",
            borderBottomColor: pct > 0.75 ? unrot.accent : "transparent",
            transform: [{ rotate: `${-90 + pct * 360}deg` }],
          },
        ]}
      />
      <View style={styles.center}>
        <Text style={styles.minutes}>{remaining}</Text>
        <Text style={styles.label}>min left</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { alignItems: "center", justifyContent: "center" },
  track: { position: "absolute" },
  progress: { position: "absolute" },
  center: { alignItems: "center" },
  minutes: {
    fontSize: 44,
    fontWeight: "800",
    color: unrot.text,
    letterSpacing: -1,
  },
  label: { fontSize: 14, color: unrot.textMuted, marginTop: 2 },
});
