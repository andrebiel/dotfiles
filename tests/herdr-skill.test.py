"""Exercise installation, updates, and conflicts without touching user skills."""
import os
from pathlib import Path
import subprocess
import tempfile

installer = Path(__file__).resolve().parents[1] / "scripts/install-herdr-skill"
with tempfile.TemporaryDirectory(prefix="herdr-skill-test-") as temporary:
    root = Path(temporary)
    fixture_home = root / "user"
    binary_dir = root / "bin"
    binary_dir.mkdir()
    bundled = root / "bundled.md"
    original = '---\nname: herdr\ndescription: "Herdr requires HERDR_ENV=1"\n---\nVersion one\n'
    bundled.write_text(original)
    binary = binary_dir / "herdr"
    binary.write_text('#!/bin/sh\n[ "$1" = --skill ] || exit 2\ncat "$TEST_HERDR_SKILL"\n')
    binary.chmod(0o755)
    environment = dict(os.environ, HOME=str(fixture_home),
                       PATH=str(binary_dir) + os.pathsep + os.environ["PATH"],
                       TEST_HERDR_SKILL=str(bundled))
    environment.pop("CLAUDE_CONFIG_DIR", None)

    def run(*args, success=True):
        result = subprocess.run([str(installer), *args], env=environment,
                                capture_output=True, text=True)
        assert (result.returncode == 0) == success, result.stdout + result.stderr

    run("--check", success=False)
    assert not fixture_home.exists(), "check must not create skill directories"
    run()
    skill_dir = fixture_home / ".agents/skills/herdr"
    skill = skill_dir / "SKILL.md"
    claude_link = fixture_home / ".claude/skills/herdr"
    assert claude_link.is_symlink() and claude_link.resolve() == skill_dir.resolve()
    assert skill.read_text() == original
    run("--check")
    before = skill.stat().st_mtime_ns
    run()
    assert skill.stat().st_mtime_ns == before
    assert not list(skill_dir.glob("SKILL.md.backup.*"))

    updated = original.replace("Version one", "Version two")
    bundled.write_text(updated)
    run("--check", success=False)
    run()
    assert skill.read_text() == updated
    assert [p.read_text() for p in skill_dir.glob("SKILL.md.backup.*")] == [original]
    run("--check")

    bundled.write_text("Not a skill\n")
    run(success=False)
    assert skill.read_text() == updated
    bundled.write_text(original)
    claude_link.unlink()
    claude_link.mkdir()
    (claude_link / "SKILL.md").write_text("User's existing skill")
    run(success=False)
    assert skill.read_text() == updated, "conflict must fail before updating shared skill"
    assert (claude_link / "SKILL.md").read_text() == "User's existing skill"

    environment["CLAUDE_CONFIG_DIR"] = str(root / "custom-claude")
    run()
    run("--check")
    assert (root / "custom-claude/skills/herdr").resolve() == skill_dir.resolve()

print("ok - Herdr skill install, idempotence, update, validation, conflicts, custom Claude path")
