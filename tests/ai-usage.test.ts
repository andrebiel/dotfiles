import { afterEach, describe, expect, test } from "bun:test";
import { Database } from "bun:sqlite";
import { chmod, mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const cli = join(import.meta.dir, "..", "ai-usage", ".local", "bin", "ai-usage");
const temporaryDirectories: string[] = [];

afterEach(async () => {
  await Promise.all(temporaryDirectories.splice(0).map((path) => rm(path, { recursive: true, force: true })));
});

async function runCli(args: string[], variables: Record<string, string>, extraEnvironment = {}) {
  const child = Bun.spawn([cli, ...args], {
    env: { ...process.env, ...variables, ...extraEnvironment },
  });
  const [stdout, stderr, exitCode] = await Promise.all([
    new Response(child.stdout).text(),
    new Response(child.stderr).text(),
    child.exited,
  ]);
  return { stdout, stderr, exitCode };
}

async function runPopupKeys(keys: string, variables: Record<string, string>) {
  const driver = join(import.meta.dir, "helpers", "pty-driver.py");
  const child = Bun.spawn(["/usr/bin/python3", driver, cli, keys], {
    env: { ...process.env, ...variables, TERM: "xterm-256color" },
    stdout: "pipe",
    stderr: "pipe",
  });
  const [stdout, stderr, exitCode] = await Promise.all([
    new Response(child.stdout).text(),
    new Response(child.stderr).text(),
    child.exited,
  ]);
  return { stdout, stderr, exitCode };
}

async function fixtureEnvironment(usagePayloads: Record<string, unknown> = {}) {
  const root = await mkdtemp(join(tmpdir(), "ai-usage-test."));
  temporaryDirectories.push(root);

  const codexbar = join(root, "codexbar");
  const codexbarLog = join(root, "codexbar.log");
  const failCostFile = join(root, "fail-cost");
  const failUsageFile = join(root, "fail-usage");
  const encodedUsage = Object.fromEntries(
    ["codex", "claude", "cursor"].map((provider) => [
      provider,
      JSON.stringify(
        usagePayloads[provider] ?? [{ provider, source: "fixture", error: { message: "offline" } }],
      ).replaceAll("'", "'\\''"),
    ]),
  );
  await writeFile(
    codexbar,
    `#!/bin/sh
printf '%s\\n' "$*" >> '${codexbarLog.replaceAll("'", "'\\''")}'
if [ "$1" = "cost" ]; then
  if [ -e "$AI_USAGE_FAIL_COST_FILE" ]; then
    printf '%s\\n' 'cost unavailable' >&2
    exit 1
  fi
  printf '%s\\n' '${JSON.stringify([
    {
      provider: "codex",
      source: "local",
      updatedAt: "2026-08-17T08:00:00Z",
      daily: [
        {
          date: "2026-08-17",
          totalCost: 2.25,
          totalTokens: 1_000,
          modelBreakdowns: [{ modelName: "gpt-5", cost: 2.25, totalTokens: 1_000 }],
        },
        {
          date: "2026-08-16",
          totalCost: 1.5,
          totalTokens: 500,
          modelBreakdowns: [{ modelName: "gpt-5", cost: 1.5, totalTokens: 500 }],
        },
      ],
    },
    {
      provider: "claude",
      source: "local",
      updatedAt: "2026-08-17T08:00:00Z",
      daily: [
        {
          date: "2026-08-17",
          totalCost: 1.25,
          totalTokens: 800,
          modelBreakdowns: [{ modelName: "claude-opus-4-6", cost: 1.25, totalTokens: 800 }],
        },
        {
          date: "2026-07-20",
          totalCost: 0.75,
          totalTokens: 200,
          modelBreakdowns: [{ modelName: "claude-opus-4-6", cost: 0.75, totalTokens: 200 }],
        },
      ],
    },
  ]).replaceAll("'", "'\\''")}'
  exit 0
fi
if [ -e "$AI_USAGE_FAIL_USAGE_FILE" ]; then
  printf '%s\\n' '[{"provider":"'$3'","source":"fixture","error":{"message":"offline"}}]'
  exit 0
fi
case "$3" in
  codex) printf '%s\\n' '${encodedUsage.codex}' ;;
  claude) printf '%s\\n' '${encodedUsage.claude}' ;;
  cursor) printf '%s\\n' '${encodedUsage.cursor}' ;;
esac
`,
  );
  await chmod(codexbar, 0o755);

  const cursorDatabase = join(root, "state.vscdb");
  const database = new Database(cursorDatabase, { create: true });
  database.run("CREATE TABLE ItemTable (key TEXT PRIMARY KEY, value BLOB)");
  const insert = database.prepare("INSERT INTO ItemTable (key, value) VALUES (?, ?)");
  insert.run(
    "aiCodeTracking.dailyStats.v1.5.2026-08-17",
    JSON.stringify({
      date: "2026-08-17",
      composerAcceptedLines: 30,
      composerSuggestedLines: 60,
      tabAcceptedLines: 20,
      tabSuggestedLines: 40,
    }),
  );
  insert.run(
    "aiCodeTracking.dailyStats.v1.5.2026-08-16",
    JSON.stringify({
      date: "2026-08-16",
      composerAcceptedLines: 10,
      composerSuggestedLines: 20,
      tabAcceptedLines: 5,
      tabSuggestedLines: 10,
    }),
  );
  database.close();

  const herdrLog = join(root, "herdr.log");
  const herdr = join(root, "herdr");
  await writeFile(herdrLog, "");
  await writeFile(
    herdr,
    `#!/bin/sh
printf '%s\\n' "$*" >> '${herdrLog.replaceAll("'", "'\\''")}'
`,
  );
  await chmod(herdr, 0o755);

  return {
    root,
    codexbarLog,
    herdrLog,
    variables: {
    AI_USAGE_CACHE_DIR: join(root, "cache"),
    AI_USAGE_FAIL_COST_FILE: failCostFile,
    AI_USAGE_FAIL_USAGE_FILE: failUsageFile,
    AI_USAGE_NOW: "2026-08-17T12:00:00+02:00",
    CODEXBAR_BIN: codexbar,
    CURSOR_STATE_DB: cursorDatabase,
    HERDR_BIN: herdr,
    HOME: root,
    NO_COLOR: "1",
    TZ: "Europe/Berlin",
    },
  };
}

describe("ai-usage snapshot", () => {
  test("aggregates local cost and Cursor acceptance for today, 7 days, and 30 days", async () => {
    const fixture = await fixtureEnvironment();
    const { stdout, stderr, exitCode } = await runCli(["snapshot", "--json"], fixture.variables);

    expect(stderr).toBe("");
    expect(exitCode).toBe(0);
    const snapshot = JSON.parse(stdout);
    expect(snapshot.schemaVersion).toBe(1);
    expect(snapshot.local.today).toMatchObject({ costUSD: 3.5, tokens: 1_800 });
    expect(snapshot.local.sevenDays).toMatchObject({ costUSD: 5, tokens: 2_300 });
    expect(snapshot.local.thirtyDays).toMatchObject({ costUSD: 5.75, tokens: 2_500 });
    expect(snapshot.local.providers.codex.today.costUSD).toBe(2.25);
    expect(snapshot.local.providers.claude.today.costUSD).toBe(1.25);
    expect(snapshot.cursor.today).toEqual({ acceptedLines: 50, suggestedLines: 100, acceptanceRate: 0.5 });
    expect(snapshot.cursor.sevenDays).toEqual({ acceptedLines: 65, suggestedLines: 130, acceptanceRate: 0.5 });
    expect(snapshot.cursor.thirtyDays).toEqual({ acceptedLines: 65, suggestedLines: 130, acceptanceRate: 0.5 });
  });

  test("refresh caches provider limits without calling Herdr", async () => {
    const fixture = await fixtureEnvironment({
      codex: {
        provider: "codex",
        source: "fixture",
        usage: {
          primary: { usedPercent: 28, windowMinutes: 300, resetsAt: "2026-08-17T15:00:00Z" },
          secondary: { usedPercent: 59, windowMinutes: 10080, resetsAt: "2026-08-21T08:00:00Z" },
        },
      },
      claude: {
        provider: "claude",
        source: "fixture",
        usage: {
          primary: { usedPercent: 27, windowMinutes: 300, resetsAt: "2026-08-17T16:00:00Z" },
        },
      },
    });
    const { stdout, stderr, exitCode } = await runCli(["refresh", "--json"], fixture.variables);

    expect(stderr).toBe("");
    expect(exitCode).toBe(0);
    const snapshot = JSON.parse(stdout);
    expect(snapshot.limits.codex).toMatchObject({
      status: "ok",
      source: "fixture",
      windows: [
        { label: "5h", usedPercent: 28, leftPercent: 72, resetsAt: "2026-08-17T15:00:00Z" },
        { label: "weekly", usedPercent: 59, leftPercent: 41, resetsAt: "2026-08-21T08:00:00Z" },
      ],
    });
    expect(snapshot.limits.claude.status).toBe("ok");
    expect(snapshot.limits.cursor.status).toBe("offline");

    const cached = await Bun.file(join(fixture.variables.AI_USAGE_CACHE_DIR, "snapshot.json")).json();
    expect(cached.generatedAt).toBe("2026-08-17T10:00:00.000Z");
    const herdrCalls = await Bun.file(fixture.herdrLog).text();
    expect(herdrCalls).toBe("");
  });

  test("show renders trends, model costs, limits, and Cursor acceptance", async () => {
    const fixture = await fixtureEnvironment({
      codex: {
        provider: "codex",
        source: "fixture",
        usage: { primary: { usedPercent: 28, windowMinutes: 300, resetsAt: "2026-08-17T15:00:00Z" } },
      },
      claude: {
        provider: "claude",
        source: "fixture",
        usage: { secondary: { usedPercent: 59, windowMinutes: 10080, resetsAt: "2026-08-21T08:00:00Z" } },
      },
    });
    expect((await runCli(["refresh", "--json"], fixture.variables)).exitCode).toBe(0);

    const { stdout, stderr, exitCode } = await runCli(
      ["show", "--once"],
      fixture.variables,
      { COLUMNS: "100" },
    );

    expect(stderr).toBe("");
    expect(exitCode).toBe(0);
    expect(stdout).toContain("AI USAGE");
    expect(stdout).toContain("checked 12:00");
    expect(stdout).toContain("API-EQUIVALENT COST");
    expect(stdout).toMatch(/Today\s+\$3\.50/);
    expect(stdout).toContain("gpt-5");
    expect(stdout).toContain("Codex");
    expect(stdout).toContain("72% left");
    expect(stdout).toContain("CURSOR CODE ACCEPTANCE");
    expect(stdout).toContain("50 / 100 lines");
    expect(stdout).toContain("API-equivalent estimate, not subscription billing");
  });

  test("local-only refresh does not poll provider limits", async () => {
    const fixture = await fixtureEnvironment();
    expect((await runCli(["refresh", "--local-only", "--json"], fixture.variables)).exitCode).toBe(0);

    const calls = await Bun.file(fixture.codexbarLog).text();
    expect(calls).toContain("cost --provider both");
    expect(calls).not.toContain("usage --provider");
  });

  test("keeps the last successful limits and local totals as stale after refresh failures", async () => {
    const fixture = await fixtureEnvironment({
      codex: {
        provider: "codex",
        source: "fixture",
        usage: { primary: { usedPercent: 28, windowMinutes: 300 } },
      },
    });
    expect((await runCli(["refresh", "--json"], fixture.variables)).exitCode).toBe(0);
    await writeFile(fixture.variables.AI_USAGE_FAIL_COST_FILE, "1");
    await writeFile(fixture.variables.AI_USAGE_FAIL_USAGE_FILE, "1");

    fixture.variables.AI_USAGE_NOW = "2026-08-18T13:00:00+02:00";
    await rm(fixture.variables.CURSOR_STATE_DB);
    const { stdout, exitCode } = await runCli(["refresh", "--json"], fixture.variables);
    expect(exitCode).toBe(0);
    const snapshot = JSON.parse(stdout);
    expect(snapshot.generatedAt).toBe("2026-08-18T11:00:00.000Z");
    expect(snapshot.local.status).toBe("stale");
    expect(snapshot.local.updatedAt).toBe("2026-08-17T08:00:00Z");
    expect(snapshot.local.today).toEqual({ costUSD: null, tokens: null });
    expect(snapshot.local.todayAvailable).toBe(false);
    expect(snapshot.limits.codex.status).toBe("stale");
    expect(snapshot.limits.codex.updatedAt).toBe("2026-08-17T10:00:00.000Z");
    expect(snapshot.limits.codex.windows[0].leftPercent).toBe(72);
    expect(snapshot.cursor.status).toBe("stale");
    expect(snapshot.cursor.updatedAt).toBe("2026-08-17T10:00:00.000Z");

    const display = await runCli(["show", "--once"], fixture.variables, { COLUMNS: "100" });
    expect(display.stdout).toContain("checked 13:00");
    expect(display.stdout).toContain("stale · data 1d old");
    expect(display.stdout).toMatch(/Today\s+—\s+— tokens/);
  });

  test("marks missing Cursor statistics as unavailable instead of reporting a real zero", async () => {
    const fixture = await fixtureEnvironment();
    fixture.variables.CURSOR_STATE_DB = join(fixture.root, "missing.vscdb");
    const result = await runCli(["snapshot", "--json"], fixture.variables);
    const snapshot = JSON.parse(result.stdout);
    expect(result.exitCode).toBe(0);
    expect(snapshot.cursor.status).toBe("unavailable");
    expect(snapshot.cursor.today).toEqual({ acceptedLines: 0, suggestedLines: 0, acceptanceRate: null });
  });

  test("marks an entirely corrupt Cursor statistics range as unavailable", async () => {
    const fixture = await fixtureEnvironment();
    const database = new Database(fixture.variables.CURSOR_STATE_DB);
    database.run("UPDATE ItemTable SET value = ?", "not-json");
    database.close();

    const { stdout, exitCode } = await runCli(["snapshot", "--json"], fixture.variables);
    expect(exitCode).toBe(0);
    const snapshot = JSON.parse(stdout);
    expect(snapshot.cursor.status).toBe("unavailable");
    expect(snapshot.cursor.error).toBe("local Cursor statistics are corrupt");
  });

  test("does not invent a Cursor acceptance percentage when local counters are not comparable", async () => {
    const fixture = await fixtureEnvironment();
    const database = new Database(fixture.variables.CURSOR_STATE_DB);
    database.run(
      "UPDATE ItemTable SET value = ? WHERE key = ?",
      JSON.stringify({
        date: "2026-08-17",
        composerAcceptedLines: 200,
        composerSuggestedLines: 100,
        tabAcceptedLines: 0,
        tabSuggestedLines: 0,
      }),
      "aiCodeTracking.dailyStats.v1.5.2026-08-17",
    );
    database.close();

    const result = await runCli(["snapshot", "--json"], fixture.variables);
    const snapshot = JSON.parse(result.stdout);
    expect(result.exitCode).toBe(0);
    expect(snapshot.cursor.today).toEqual({ acceptedLines: 200, suggestedLines: 100, acceptanceRate: null });
  });

  test("deduplicates identical provider quota windows", async () => {
    const repeated = { usedPercent: 100, windowMinutes: 43_200, resetsAt: "2026-09-01T00:00:00Z" };
    const fixture = await fixtureEnvironment({
      cursor: {
        provider: "cursor",
        source: "fixture",
        usage: { primary: repeated, secondary: repeated, tertiary: repeated },
      },
    });
    const result = await runCli(["refresh", "--json"], fixture.variables);
    const snapshot = JSON.parse(result.stdout);
    expect(result.exitCode).toBe(0);
    expect(snapshot.limits.cursor.windows).toEqual([
      {
        label: "monthly",
        usedPercent: 100,
        leftPercent: 0,
        resetsAt: "2026-09-01T00:00:00Z",
      },
    ]);
  });

  test(
    "popup controls refresh with r and close with q or Esc",
    async () => {
      const refreshFixture = await fixtureEnvironment();
      const refreshed = await runPopupKeys("rq", refreshFixture.variables);
      expect({ exitCode: refreshed.exitCode, stderr: refreshed.stderr }).toEqual({ exitCode: 0, stderr: "" });
      const calls = await Bun.file(refreshFixture.codexbarLog).text();
      expect(calls.match(/usage --provider codex/g)?.length).toBe(2);

      const escapeFixture = await fixtureEnvironment();
      const escaped = await runPopupKeys("\u001b", escapeFixture.variables);
      expect(escaped.exitCode).toBe(0);
      expect(escaped.stderr).toBe("");
    },
    10_000,
  );
});
