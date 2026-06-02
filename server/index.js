/**
 * Local API: DeepSeek via OpenRouter (same pattern as AIwidget worker).
 * Run: DEEPSEEK=sk-or-... node server/index.js
 */
const http = require("http");
const { readFileSync } = require("fs");
const { join } = require("path");

const PORT = Number(process.env.PORT || 8788);
const UPSTREAM = "https://openrouter.ai/api/v1/chat/completions";
const MODEL = "deepseek/deepseek-v4-flash";

function loadEnvFile() {
  try {
    const envPath = join(__dirname, "..", ".env");
    const raw = readFileSync(envPath, "utf8");
    for (const line of raw.split("\n")) {
      const t = line.trim();
      if (!t || t.startsWith("#")) continue;
      const i = t.indexOf("=");
      if (i === -1) continue;
      const key = t.slice(0, i).trim();
      const val = t.slice(i + 1).trim().replace(/^["']|["']$/g, "");
      if (!process.env[key]) process.env[key] = val;
    }
  } catch {
    /* no .env */
  }
}

loadEnvFile();

function cors(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, X-Doomquiz-Key");
}

function json(res, status, obj) {
  cors(res);
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(obj));
}

async function callDeepSeek(messages, maxTokens = 1200) {
  const apiKey = process.env.DEEPSEEK;
  if (!apiKey) throw new Error("Missing DEEPSEEK in .env");

  const upstream = await fetch(UPSTREAM, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
      "HTTP-Referer": "https://doomquiz.app",
      "X-Title": "DoomQuiz",
    },
    body: JSON.stringify({
      model: MODEL,
      messages,
      temperature: 0.3,
      max_tokens: maxTokens,
      reasoning: { effort: "minimal", exclude: true },
    }),
  });

  const body = await upstream.text();
  if (!upstream.ok) throw new Error(body || "OpenRouter error");

  const parsed = JSON.parse(body);
  const content = parsed.choices?.[0]?.message?.content;
  if (!content) throw new Error("Empty model response");
  return content;
}

function extractJson(text) {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  const raw = fenced ? fenced[1].trim() : text.trim();
  return JSON.parse(raw);
}

const SYSTEM = `You are a study coach for DoomQuiz. Given syllabus text or a learning topic, output ONLY valid JSON (no markdown outside the JSON) with this shape:
{
  "title": "short deck title",
  "points": [
    { "term": "key concept", "definition": "1-2 sentence explanation to memorize" }
  ],
  "questions": [
    {
      "prompt": "multiple choice question",
      "choices": ["A", "B", "C", "D"],
      "correctIndex": 0
    }
  ]
}
Rules:
- Exactly 7 or 8 points in "points" (Quizlet-style memorize list).
- Exactly 5 questions in "questions", each with 4 choices and correctIndex 0-3.
- Questions must test the memorize points.
- Keep language clear and student-friendly.`;

const server = http.createServer(async (req, res) => {
  cors(res);
  if (req.method === "OPTIONS") {
    res.writeHead(204);
    return res.end();
  }

  if (req.method === "GET" && req.url === "/health") {
    return json(res, 200, { ok: true });
  }

  if (req.method !== "POST" || req.url !== "/generate-deck") {
    return json(res, 404, { error: "Not found" });
  }

  if (process.env.CLIENT_SECRET) {
    const key = req.headers["x-doomquiz-key"] || "";
    if (key !== process.env.CLIENT_SECRET) {
      return json(res, 401, { error: "Unauthorized" });
    }
  }

  let body = "";
  req.on("data", (chunk) => (body += chunk));
  req.on("end", async () => {
    try {
      const { title, content, source } = JSON.parse(body || "{}");
      if (!content || typeof content !== "string" || content.trim().length < 20) {
        return json(res, 400, {
          error: "Provide at least ~20 characters of syllabus or topic text.",
        });
      }

      const userLabel =
        source === "topic"
          ? `Learning topic: ${title}\n\nExpand and teach this topic.`
          : `Study material (${title}):\n\n${content.slice(0, 12000)}`;

      const reply = await callDeepSeek([
        { role: "system", content: SYSTEM },
        { role: "user", content: userLabel },
      ]);

      const deck = extractJson(reply);
      return json(res, 200, deck);
    } catch (e) {
      const message = e instanceof Error ? e.message : "Server error";
      return json(res, 500, { error: message });
    }
  });
});

server.listen(PORT, () => {
  console.log(`DoomQuiz API on http://localhost:${PORT}`);
});
