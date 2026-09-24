import { Database } from "bun:sqlite";
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { join } from "node:path";

const schemaVersion = 1;
const home = process.env.HOME ?? "";
const cacheDirectory = process.env.AI_USAGE_CACHE_DIR ?? join(home, "Library", "Caches", "ai-usage");
const cursorDatabasePath =
  process.env.CURSOR_STATE_DB ??
  join(home, "Library", "Application Support", "Cursor", "User", "globalStorage", "state.vscdb");
const codexbarBinary = process.env.CODEXBAR_BIN ?? "codexbar";
const snapshotPath = join(cacheDirectory, "snapshot.json");
const fixedNow = process.env.AI_USAGE_NOW ?? null;
const timeZone = process.env.TZ ?? Intl.DateTimeFormat().resolvedOptions().timeZone;

function currentTime() {
  return new Date(fixedNow ?? Date.now());
}

function dateInTimeZone(date) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map(({ type, value }) => [type, value]));
  return `${values.year}-${values.month}-${values.day}`;
}

function addDays(date, amount) {
  const parsed = new Date(`${date}T12:00:00Z`);
  parsed.setUTCDate(parsed.getUTCDate() + amount);
  return parsed.toISOString().slice(0, 10);
}

function finiteNumberOrZero(value) {
  return Number.isFinite(Number(value)) ? Number(value) : 0;
}

function round(value, digits = 6) {
  const scale = 10 ** digits;
  return Math.round((value + Number.EPSILON) * scale) / scale;
}

function emptyPeriod() {
  return { costUSD: 0, tokens: 0 };
}

function aggregateCost(days, startDate, endDate) {
  return days.reduce(
    (total, day) => {
      if (day.date < startDate || day.date > endDate) return total;
      total.costUSD += finiteNumberOrZero(day.totalCost);
      total.tokens += finiteNumberOrZero(day.totalTokens);
      return total;
    },
    emptyPeriod(),
  );
}

function finalizePeriod(period) {
  return { costUSD: round(period.costUSD), tokens: Math.round(period.tokens) };
}

function costCommand(refresh) {
  return [
    codexbarBinary,
    "cost",
    "--provider",
    "both",
    "--provider-native-only",
    "--days",
    "30",
    "--format",
    "json",
    ...(refresh ? ["--refresh"] : []),
  ];
}

function readCostPayload(refresh = false) {
  const child = Bun.spawnSync(costCommand(refresh), { stdout: "pipe", stderr: "pipe" });
  if (child.exitCode !== 0) {
    const message = child.stderr.toString().trim() || `codexbar exited with ${child.exitCode}`;
    throw new Error(message);
  }
  const payload = JSON.parse(child.stdout.toString());
  if (!Array.isArray(payload)) throw new Error("codexbar cost returned an unexpected payload");
  return payload;
}

function normalizeCost(payload, today) {
  const starts = { today, sevenDays: addDays(today, -6), thirtyDays: addDays(today, -29) };
  const providers = {};
  const dailyByDate = new Map();
  const modelTotals = new Map();

  for (const providerPayload of payload) {
    const provider = String(providerPayload.provider ?? "unknown");
    const days = Array.isArray(providerPayload.daily) ? providerPayload.daily : [];
    providers[provider] = {
      today: finalizePeriod(aggregateCost(days, starts.today, today)),
      sevenDays: finalizePeriod(aggregateCost(days, starts.sevenDays, today)),
      thirtyDays: finalizePeriod(aggregateCost(days, starts.thirtyDays, today)),
      updatedAt: providerPayload.updatedAt ?? null,
    };

    for (const day of days) {
      if (typeof day.date !== "string" || day.date < starts.thirtyDays || day.date > today) continue;
      const combined = dailyByDate.get(day.date) ?? { date: day.date, costUSD: 0, tokens: 0, providers: {} };
      const providerCost = finiteNumberOrZero(day.totalCost);
      const providerTokens = finiteNumberOrZero(day.totalTokens);
      combined.costUSD += providerCost;
      combined.tokens += providerTokens;
      combined.providers[provider] = { costUSD: round(providerCost), tokens: Math.round(providerTokens) };
      dailyByDate.set(day.date, combined);

      for (const breakdown of Array.isArray(day.modelBreakdowns) ? day.modelBreakdowns : []) {
        const model = String(breakdown.modelName ?? "unknown");
        const key = `${provider}\0${model}`;
        const aggregate = modelTotals.get(key) ?? { provider, model, costUSD: 0, tokens: 0 };
        aggregate.costUSD += finiteNumberOrZero(breakdown.cost);
        aggregate.tokens += finiteNumberOrZero(breakdown.totalTokens);
        modelTotals.set(key, aggregate);
      }
    }
  }

  const allDays = payload.flatMap((provider) => (Array.isArray(provider.daily) ? provider.daily : []));
  return {
    throughDate: today,
    todayAvailable: true,
    currency: "USD",
    updatedAt:
      payload
        .map((provider) => provider.updatedAt)
        .filter(Boolean)
        .sort()
        .at(-1) ?? null,
    today: finalizePeriod(aggregateCost(allDays, starts.today, today)),
    sevenDays: finalizePeriod(aggregateCost(allDays, starts.sevenDays, today)),
    thirtyDays: finalizePeriod(aggregateCost(allDays, starts.thirtyDays, today)),
    providers,
    daily: [...dailyByDate.values()]
      .sort((left, right) => left.date.localeCompare(right.date))
      .map((day) => ({ ...day, costUSD: round(day.costUSD), tokens: Math.round(day.tokens) })),
    models: [...modelTotals.values()]
      .map((model) => ({ ...model, costUSD: round(model.costUSD), tokens: Math.round(model.tokens) }))
      .sort((left, right) => right.costUSD - left.costUSD),
  };
}

function emptyCursorPeriod() {
  return { acceptedLines: 0, suggestedLines: 0, acceptanceRate: null };
}

function finalizeCursorPeriod(period) {
  return {
    acceptedLines: period.acceptedLines,
    suggestedLines: period.suggestedLines,
    acceptanceRate:
      period.suggestedLines > 0 && period.acceptedLines <= period.suggestedLines
        ? round(period.acceptedLines / period.suggestedLines, 4)
        : null,
  };
}

function readCursorData() {
  let database;
  try {
    database = new Database(cursorDatabasePath, { readonly: true, strict: true });
    const rows = database
      .query(
        `SELECT value FROM ItemTable
         WHERE key >= 'aiCodeTracking.dailyStats.v1.5.'
           AND key < 'aiCodeTracking.dailyStats.v1.5/'`,
      )
      .all();
    let invalidRows = 0;
    const days = rows.flatMap(({ value }) => {
      try {
        const text = typeof value === "string" ? value : new TextDecoder().decode(value);
        const parsed = JSON.parse(text);
        return typeof parsed.date === "string" ? [parsed] : [];
      } catch {
        invalidRows += 1;
        return [];
      }
    });
    if (rows.length > 0 && days.length === 0 && invalidRows > 0) {
      return { status: "unavailable", days: [], error: "local Cursor statistics are corrupt" };
    }
    return { status: "ok", days };
  } catch {
    return { status: "unavailable", days: [], error: "local Cursor statistics unavailable" };
  } finally {
    database?.close();
  }
}

function aggregateCursor(days, startDate, endDate) {
  const period = days.reduce((total, day) => {
    if (day.date < startDate || day.date > endDate) return total;
    total.acceptedLines += finiteNumberOrZero(day.composerAcceptedLines) + finiteNumberOrZero(day.tabAcceptedLines);
    total.suggestedLines += finiteNumberOrZero(day.composerSuggestedLines) + finiteNumberOrZero(day.tabSuggestedLines);
    return total;
  }, emptyCursorPeriod());
  return finalizeCursorPeriod(period);
}

function normalizeCursor(data, today) {
  return {
    status: data.status,
    ...(data.error ? { error: data.error } : {}),
    today: aggregateCursor(data.days, today, today),
    sevenDays: aggregateCursor(data.days, addDays(today, -6), today),
    thirtyDays: aggregateCursor(data.days, addDays(today, -29), today),
  };
}

function limitLabel(window, fallback) {
  if (finiteNumberOrZero(window.windowMinutes) === 300) return "5h";
  if (finiteNumberOrZero(window.windowMinutes) === 10_080) return "weekly";
  if (finiteNumberOrZero(window.windowMinutes) >= 40_000) return "monthly";
  return fallback;
}

function normalizeLimit(payload) {
  const values = Array.isArray(payload) ? payload : [payload];
  const value = values.find((candidate) => candidate?.usage && !candidate.error) ?? values[0];
  if (!value || value.error || !value.usage) {
    const error = value?.error;
    return {
      status: availabilityStatus(error),
      source: value?.source ?? null,
      windows: [],
      error: error?.message ?? "usage unavailable",
    };
  }
  const rawWindows = [
    ["primary", "primary"],
    ["secondary", "secondary"],
    ["tertiary", "tertiary"],
  ].flatMap(([key, fallback]) => {
    const window = value.usage[key];
    if (!window || !Number.isFinite(Number(window.usedPercent))) return [];
    const usedPercent = Math.max(0, Math.min(100, finiteNumberOrZero(window.usedPercent)));
    return [
      {
        label: limitLabel(window, fallback),
        usedPercent: round(usedPercent, 2),
        leftPercent: round(100 - usedPercent, 2),
        resetsAt: window.resetsAt ?? null,
      },
    ];
  });
  const seenWindows = new Set();
  const windows = rawWindows.filter((window) => {
    const key = `${window.label}\0${window.usedPercent}\0${window.resetsAt ?? ""}`;
    if (seenWindows.has(key)) return false;
    seenWindows.add(key);
    return true;
  });
  if (windows.length === 0) {
    return { status: "unavailable", source: value.source ?? null, windows: [], error: "no quota windows" };
  }
  return {
    status: "ok",
    source: value.source ?? null,
    updatedAt: value.usage.updatedAt ?? value.updatedAt ?? currentTime().toISOString(),
    windows,
  };
}

async function fetchLimit(provider) {
  try {
    const child = Bun.spawn(
      [
        codexbarBinary,
        "usage",
        "--provider",
        provider,
        "--format",
        "json",
        "--web-timeout",
        "10",
        "--no-color",
      ],
      { stdout: "pipe", stderr: "pipe" },
    );
    const [stdout, stderr, exitCode] = await Promise.all([
      new Response(child.stdout).text(),
      new Response(child.stderr).text(),
      child.exited,
    ]);
    if (exitCode !== 0) throw new Error(stderr.trim() || `codexbar exited with ${exitCode}`);
    return normalizeLimit(JSON.parse(stdout));
  } catch (error) {
    const message = String(error?.message ?? error);
    return { status: availabilityStatus({ message }), source: null, windows: [], error: message };
  }
}

function availabilityStatus(error) {
  const text = JSON.stringify(error ?? {}).toLowerCase();
  if (/auth|login|cookie|credential|unauthorized|forbidden/.test(text)) return "auth_required";
  if (/offline|network|timeout|timed out|connection/.test(text)) return "offline";
  return "unavailable";
}

async function readCachedSnapshot() {
  try {
    const cached = JSON.parse(await readFile(snapshotPath, "utf8"));
    return cached.schemaVersion === schemaVersion ? cached : null;
  } catch {
    return null;
  }
}

function retainStaleLimit(current, cached) {
  if (
    current.status === "ok" ||
    !["ok", "stale"].includes(cached?.status) ||
    !Array.isArray(cached.windows)
  ) return current;
  return { ...cached, status: "stale", error: current.error ?? "refresh failed" };
}

async function buildSnapshot({ refresh = false, fetchLimits = false } = {}) {
  const generatedAt = currentTime();
  const today = dateInTimeZone(generatedAt);
  const cached = await readCachedSnapshot();
  let limits = cached?.limits ?? Object.fromEntries(
    ["codex", "claude", "cursor"].map((provider) => [provider, { status: "unavailable", windows: [] }]),
  );
  if (fetchLimits) {
    const providers = ["codex", "claude", "cursor"];
    const fetched = await Promise.all(providers.map((provider) => fetchLimit(provider)));
    limits = Object.fromEntries(
      providers.map((provider, index) => [provider, retainStaleLimit(fetched[index], cached?.limits?.[provider])]),
    );
  }
  let local;
  try {
    local = { status: "ok", ...normalizeCost(readCostPayload(refresh), today) };
    local.updatedAt ??= generatedAt.toISOString();
  } catch {
    local = cached?.local
      ? { ...cached.local, status: "stale", error: "local cost refresh failed" }
      : { status: "unavailable", error: "local cost data unavailable", ...normalizeCost([], today) };
    if (local.throughDate && local.throughDate !== today) {
      local = {
        ...local,
        throughDate: today,
        todayAvailable: false,
        today: { costUSD: null, tokens: null },
        providers: Object.fromEntries(
          Object.entries(local.providers).map(([provider, periods]) => [
            provider,
            { ...periods, today: { costUSD: null, tokens: null } },
          ]),
        ),
      };
    }
  }
  const cursorData = readCursorData();
  let cursor = normalizeCursor(cursorData, today);
  if (cursor.status === "ok") {
    cursor.updatedAt = generatedAt.toISOString();
  } else if (["ok", "stale"].includes(cached?.cursor?.status)) {
    cursor = { ...cached.cursor, status: "stale", error: cursor.error };
  }
  return {
    schemaVersion,
    generatedAt: generatedAt.toISOString(),
    timeZone,
    local,
    cursor,
    limits,
  };
}

async function writeSnapshot(snapshot) {
  await mkdir(cacheDirectory, { recursive: true });
  const temporary = join(cacheDirectory, `.snapshot.${process.pid}.json`);
  await writeFile(temporary, `${JSON.stringify(snapshot)}\n`, { mode: 0o600 });
  await rename(temporary, snapshotPath);
}

async function refreshAll({ fetchLimits = true } = {}) {
  const snapshot = await buildSnapshot({ refresh: true, fetchLimits });
  await writeSnapshot(snapshot);
  return snapshot;
}

export {
  addDays,
  buildSnapshot,
  dateInTimeZone,
  finiteNumberOrZero,
  refreshAll,
  timeZone,
};
