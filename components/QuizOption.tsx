import { Pressable, Text, StyleSheet } from "react-native";
import { quizlet } from "@/lib/theme";

type Props = {
  label: string;
  selected: boolean;
  result?: "correct" | "wrong" | null;
  onPress: () => void;
  disabled?: boolean;
};

export function QuizOption({
  label,
  selected,
  result,
  onPress,
  disabled,
}: Props) {
  let border = quizlet.border;
  let bg = quizlet.card;
  if (result === "correct") {
    border = quizlet.correct;
    bg = "rgba(35, 178, 109, 0.12)";
  } else if (result === "wrong") {
    border = quizlet.wrong;
    bg = "rgba(255, 114, 91, 0.12)";
  } else if (selected) {
    border = quizlet.primary;
    bg = quizlet.primarySoft;
  }

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={[styles.option, { borderColor: border, backgroundColor: bg }]}
    >
      <Text style={styles.text}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  option: {
    borderWidth: 2,
    borderRadius: 14,
    paddingVertical: 16,
    paddingHorizontal: 18,
    marginBottom: 10,
  },
  text: { color: quizlet.text, fontSize: 16, fontWeight: "600" },
});
