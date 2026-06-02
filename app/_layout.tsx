import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { DoomQuizProvider } from "@/context/DoomQuizContext";

export default function RootLayout() {
  return (
    <DoomQuizProvider>
      <StatusBar style="light" />
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="(tabs)" />
        <Stack.Screen
          name="gate-quiz"
          options={{
            presentation: "fullScreenModal",
            animation: "slide_from_bottom",
          }}
        />
        <Stack.Screen
          name="session"
          options={{
            presentation: "card",
            animation: "fade",
          }}
        />
      </Stack>
    </DoomQuizProvider>
  );
}
