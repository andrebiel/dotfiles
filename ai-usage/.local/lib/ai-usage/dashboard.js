import {
  addDays,
  buildSnapshot,
  dateInTimeZone,
  finiteNumberOrZero,
  refreshAll,
  timeZone,
} from "./snapshot.js";

const colorEnabled = !process.env.NO_COLOR && Boolean(process.stdout.isTTY);
const colors = {
  accent: "\u001b[38;2;137;180;250m",
  green: "\u001b[38;2;166;227;161m",
  muted: "\u001b[38;2;127;132;156m",
  peach: "\u001b[38;2;250;179;135m",
  yellow: "\u001b[38;2;249;226;175m",
  reset: "\u001b[0m",
};

function paint(value, color) {
  return colorEnabled ? `${colors[color]}${value}${colors.reset}` : value;
}

function money(value) {
  return `$${finiteNumberOrZero(value).toFixed(2)}`;
}

function moneyOrUnavailable(value) {
  return value == null ? "—" : money(value);
}

function integerOrUnavailable(value) {
  return value == null ? "—" : integer(value);
}

function integer(value) {
  return Math.round(finiteNumberOrZero(value)).toLocaleString("en-US");
}

function percentage(value) {
  return value == null ? "—" : `${Math.round(value * 100)}%`;
}

function quotaBar(leftPercent, width = 12) {
  const percent = Math.max(0, Math.min(100, finiteNumberOrZero(leftPercent)));
  const filled = Math.round((percent / 100) * width);
  return `${"█".repeat(filled)}${"░".repeat(width - filled)}`;
}

function trend(local, today, length = 14) {
  const byDate = new Map(local.daily.map((day) => [day.date, day.costUSD]));
  const values = Array.from({ length }, (_, index) =>
    finiteNumberOrZero(byDate.get(addDays(today, index - length + 1))),
  );
  const maximum = Math.max(...values, 0);
  const blocks = "▁▂▃▄▅▆▇█";
  if (maximum === 0) return "·".repeat(length);
  return values.map((value) => blocks[Math.min(7, Math.floor((value / maximum) * 7))]).join("");
}

function ageText(timestamp, checkedAt) {
  if (!timestamp) return "age unknown";
  const ageSeconds = Math.max(0, (new Date(checkedAt).getTime() - new Date(timestamp).getTime()) / 1000);
  if (!Number.isFinite(ageSeconds)) return "age unknown";
  if (ageSeconds < 60) return "just now";
  if (ageSeconds < 3600) return `${Math.floor(ageSeconds / 60)}m old`;
  if (ageSeconds < 86_400) return `${Math.floor(ageSeconds / 3600)}h old`;
  return `${Math.floor(ageSeconds / 86_400)}d old`;
}

function resetText(value) {
  if (!value) return "reset unknown";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return `resets ${new Intl.DateTimeFormat("en-GB", {
    timeZone,
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date)}`;
}

function renderSnapshot(snapshot) {
  const width = Math.max(
    60,
    Math.min(110, finiteNumberOrZero(process.env.COLUMNS) || process.stdout.columns || 90),
  );
  const line = "─".repeat(width);
  const today = dateInTimeZone(new Date(snapshot.generatedAt));
  const checkedTime = new Date(snapshot.generatedAt).toLocaleTimeString("en-GB", {
    timeZone,
    hour: "2-digit",
    minute: "2-digit",
  });
  const output = [];
  output.push(`${paint("AI USAGE", "accent")}  ${paint(`checked ${checkedTime}`, "muted")}`);
  if (snapshot.refreshError) output.push(paint(snapshot.refreshError, "peach"));
  output.push(paint(line, "muted"));
  output.push(
    `${paint("API-EQUIVALENT COST", "yellow")}  ${paint(`${snapshot.local.status} · data ${ageText(snapshot.local.updatedAt, snapshot.generatedAt)}`, snapshot.local.status === "ok" ? "muted" : "peach")}`,
  );
  output.push(`Today       ${moneyOrUnavailable(snapshot.local.today.costUSD).padStart(8)}   ${integerOrUnavailable(snapshot.local.today.tokens).padStart(11)} tokens`);
  output.push(`Last 7d     ${money(snapshot.local.sevenDays.costUSD).padStart(8)}   ${integer(snapshot.local.sevenDays.tokens).padStart(11)} tokens`);
  output.push(`Last 30d    ${money(snapshot.local.thirtyDays.costUSD).padStart(8)}   ${integer(snapshot.local.thirtyDays.tokens).padStart(11)} tokens`);
  output.push(`Daily 14d   ${paint(trend(snapshot.local, today), "peach")}`);
  output.push("");

  const providerRows = Object.entries(snapshot.local.providers)
    .sort((left, right) => right[1].thirtyDays.costUSD - left[1].thirtyDays.costUSD)
    .map(
      ([provider, periods]) =>
        `${provider.padEnd(10)} ${moneyOrUnavailable(periods.today.costUSD).padStart(8)} today   ${money(periods.thirtyDays.costUSD).padStart(8)} / 30d`,
    );
  output.push(...providerRows);
  if (snapshot.local.models.length > 0) {
    output.push("");
    output.push(paint("TOP MODELS · 30D", "yellow"));
    for (const model of snapshot.local.models.slice(0, 5)) {
      const label = `${model.provider} · ${model.model}`;
      output.push(
        `${label.slice(0, Math.max(20, width - 28)).padEnd(Math.max(20, width - 28))} ${money(model.costUSD).padStart(8)}  ${integer(model.tokens).padStart(10)} tok`,
      );
    }
  }

  output.push("");
  output.push(paint("CURRENT LIMITS", "yellow"));
  for (const provider of ["codex", "claude", "cursor"]) {
    const limit = snapshot.limits[provider] ?? { status: "unavailable", windows: [] };
    const label = `${provider[0].toUpperCase()}${provider.slice(1)}`;
    if (!Array.isArray(limit.windows) || limit.windows.length === 0) {
      output.push(`${label.padEnd(10)} ${paint(limit.status.replaceAll("_", " "), "muted")}`);
      continue;
    }
    limit.windows.forEach((window, index) => {
      const prefix = index === 0 ? label.padEnd(10) : " ".repeat(10);
      const status = limit.status === "stale" ? "stale" : "ok";
      const age = ageText(limit.updatedAt, snapshot.generatedAt);
      output.push(
        `${prefix} ${window.label.padEnd(8)} ${paint(quotaBar(window.leftPercent), window.leftPercent < 20 ? "peach" : "green")} ${String(window.leftPercent).padStart(3)}% left · ${resetText(window.resetsAt)} · ${status}, ${age}`,
      );
    });
  }

  output.push("");
  output.push(
    `${paint("CURSOR CODE ACCEPTANCE", "yellow")}  ${paint(`${snapshot.cursor.status} · data ${ageText(snapshot.cursor.updatedAt, snapshot.generatedAt)}`, snapshot.cursor.status === "ok" ? "muted" : "peach")}`,
  );
  for (const [label, key] of [
    ["Today", "today"],
    ["Last 7d", "sevenDays"],
    ["Last 30d", "thirtyDays"],
  ]) {
    const period = snapshot.cursor[key];
    output.push(
      `${label.padEnd(10)} ${String(`${integer(period.acceptedLines)} / ${integer(period.suggestedLines)} lines`).padEnd(22)} ${percentage(period.acceptanceRate)} accepted`,
    );
  }
  output.push("");
  output.push(paint("API-equivalent estimate, not subscription billing · Cursor dollars excluded", "muted"));
  output.push(paint("r refreshes · q or Esc closes", "muted"));
  return output.join("\n");
}

function draw(snapshot, clear = false) {
  if (clear && process.stdout.isTTY) process.stdout.write("\u001b[2J\u001b[H");
  process.stdout.write(`${renderSnapshot(snapshot)}\n`);
}

async function readKey() {
  if (!process.stdin.isTTY || typeof process.stdin.setRawMode !== "function") return "q";
  process.stdin.setRawMode(true);
  process.stdin.resume();
  try {
    const data = await new Promise((resolve) => process.stdin.once("data", resolve));
    return data.toString();
  } finally {
    process.stdin.setRawMode(false);
    process.stdin.pause();
  }
}

async function refreshForDisplay(snapshot) {
  try {
    return await refreshAll();
  } catch {
    return { ...snapshot, refreshError: "refresh failed; showing cached data" };
  }
}

async function show({ once = false } = {}) {
  let snapshot = await buildSnapshot();
  draw(snapshot);
  if (once || !process.stdout.isTTY) return;
  snapshot = await refreshForDisplay(snapshot);
  draw(snapshot, true);
  while (true) {
    const key = await readKey();
    if (key === "q" || key.includes("\u001b")) return;
    if (key.toLowerCase() === "r") {
      snapshot = await refreshForDisplay(snapshot);
      draw(snapshot, true);
    }
  }
}

export { renderSnapshot, show };
