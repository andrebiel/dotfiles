"""Exercise account skill links, idempotence, conflicts and removal without touching user skills."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

repository = Path(__file__).resolve().parents[1]
script = repository / "scripts/link-account-skills"
with tempfile.TemporaryDirectory(prefix="account-skills-test-") as temporary:
    root = Path(temporary)
    fixture_home = root / "user"
    dotfiles = root / "dotfiles"
    (dotfiles / "agents").mkdir(parents=True)
    (dotfiles / "agents/account-skills").write_text("# comment\nfull-send\n\ngit-cleanup  # trailing\n")
    environment = dict(os.environ, HOME=str(fixture_home), DOTFILES_DIR=str(dotfiles))
    environment.pop("CLAUDE_CONFIG_DIR", None)

    def run(*args, success=True):
        result = subprocess.run([str(script), *args], env=environment,
                                capture_output=True, text=True)
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result.stdout

    def sync(claude_dir, organization, name):
        skill = claude_dir / "skills/synced" / organization / name
        skill.mkdir(parents=True, exist_ok=True)
        (skill / "SKILL.md").write_text(f"---\nname: {name}\n---\n")
        return skill

    # Before Claude Code has synced anything, both modes only report.
    assert "not synced here yet" in run("--check")
    assert "not synced here yet" in run()
    assert not (fixture_home / ".agents").exists(), "nothing synced must not create links"

    claude_dir = fixture_home / ".claude"
    full_send = sync(claude_dir, "org-a", "full-send")
    git_cleanup = sync(claude_dir, "org-a", "git-cleanup")
    run("--check", success=False)
    run()
    agents_skills = fixture_home / ".agents/skills"
    for name, source in (("full-send", full_send), ("git-cleanup", git_cleanup)):
        assert os.readlink(agents_skills / name) == str(source)
        assert os.readlink(claude_dir / "skills" / name) == str(agents_skills / name)
        assert (claude_dir / "skills" / name / "SKILL.md").is_file()
    run("--check")
    run()
    run("--check")

    # Separate installations are reported, never replaced.
    (agents_skills / "git-cleanup").unlink()
    (agents_skills / "git-cleanup").mkdir()
    (agents_skills / "git-cleanup/SKILL.md").write_text("User's own skill")
    run(success=False)
    assert (agents_skills / "git-cleanup/SKILL.md").read_text() == "User's own skill"
    shutil.rmtree(agents_skills / "git-cleanup")
    run()

    # The same skill in two organizations has no clear source.
    sync(claude_dir, "org-b", "full-send")
    run(success=False)
    shutil.rmtree(claude_dir / "skills/synced/org-b")

    # A skill removed from the account drops its now-dangling links.
    shutil.rmtree(full_send)
    run()
    assert not os.path.lexists(agents_skills / "full-send")
    assert not os.path.lexists(claude_dir / "skills/full-send")
    assert (claude_dir / "skills/git-cleanup/SKILL.md").is_file()

    (dotfiles / "agents/account-skills").write_text("../escape\n")
    run(success=False)
    (dotfiles / "agents/account-skills").write_text("git-cleanup\n")

    custom = root / "custom-claude"
    environment["CLAUDE_CONFIG_DIR"] = str(custom)
    custom_source = sync(custom, "org-a", "git-cleanup")
    run()
    run("--check")
    assert os.readlink(agents_skills / "git-cleanup") == str(custom_source)
    assert os.readlink(custom / "skills/git-cleanup") == str(agents_skills / "git-cleanup")

print("ok - account skill links, idempotence, conflicts, ambiguity, removal, custom Claude path")
