#!/usr/bin/env python3
"""Exercise startup with a clean environment and synthetic secrets only."""
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="dotfiles-shell-") as temporary:
    test_home = Path(temporary)
    config = test_home / ".config/zsh"
    config.mkdir(parents=True)
    (config / "environment.sh").symlink_to(repo / "zsh/.config/zsh/environment.sh")
    (test_home / ".zshenv").symlink_to(repo / "zsh/.zshenv")
    secret = "synthetic 'quoted' $value `literal` \\ and\nnewline"
    (config / "secrets.zsh").write_text("export DOTFILES_TEST_SECRET=" + shlex.quote(secret) + "\n")
    original_rc = b'case $- in *i*) ;; *) return ;; esac\n# local settings\n'
    (test_home / ".bashrc").write_bytes(original_rc)
    (test_home / ".profile").write_text('# existing login settings\n')
    env = {"HOME": str(test_home), "PATH": os.environ["PATH"], "TERM": "dumb"}
    installer = [shutil.which("python3"), str(repo / "scripts/configure-bash")]
    subprocess.run(installer, env=env, check=True, stdout=subprocess.DEVNULL)
    before = (test_home / ".bashrc").read_bytes()
    assert before.endswith(original_rc), "Local Bash settings were changed"
    subprocess.run(installer, env=env, check=True, stdout=subprocess.DEVNULL)
    assert (test_home / ".bashrc").read_bytes() == before, "Hook installation is not idempotent"
    probe = shlex.quote(shutil.which("python3")) + " -c " + shlex.quote(
        "import os; assert os.environ.get('DOTFILES_TEST_SECRET') == " + repr(secret)
    )
    cases = [
        ("Bash interactive", ["bash", "-ic", probe], {}),
        ("Bash login", ["bash", "-lc", probe], {}),
        ("Bash SSH startup", ["bash", "-c", probe], {"SSH_CLIENT": "127.0.0.1 12345 22", "SHLVL": "0"}),
        ("Bash BASH_ENV", ["bash", "-c", probe], {"BASH_ENV": str(config / "environment.sh")}),
        ("Zsh noninteractive", ["zsh", "-c", probe], {}),
        ("Zsh login", ["zsh", "-lc", probe], {}),
        ("Zsh to Bash", ["zsh", "-c", "unset DOTFILES_TEST_SECRET; bash -c " + shlex.quote(probe)], {}),
    ]
    for label, command, extra in cases:
        result = subprocess.run(command, env=env | extra, capture_output=True, timeout=10)
        assert result.returncode == 0, f"{label} failed (output suppressed)"
        assert result.stdout == b"", f"{label} produced unexpected output"
        print(f"ok - {label}")
    (config / "secrets.zsh").unlink()
    for shell in ("bash", "zsh"):
        subprocess.run([shell, "-c", '. "$HOME/.config/zsh/environment.sh"'], env=env, check=True)
    print("ok - missing secrets file is harmless")

    # Run harmless stand-ins through the same names a user types at the prompt.
    # Set PATH after shell startup so login profiles cannot select a real agent.
    (config / "homebrew.zsh").symlink_to(repo / "zsh/.config/zsh/homebrew.zsh")
    (test_home / ".zshrc").symlink_to(repo / "zsh/.zshrc")
    (test_home / ".zprofile").symlink_to(repo / "zsh/.zprofile")
    (test_home / ".config/oh-my-posh").symlink_to(repo / "zsh/.config/oh-my-posh")
    env["SHELL"] = "/bin/bash"  # An already-running Herdr server's stale value.
    fake_bin = test_home / "agent-probes"
    fake_bin.mkdir()
    for agent in ("claude", "codex"):
        executable = fake_bin / agent
        executable.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
        executable.chmod(0o755)
    agent_probe = (
        'export PATH=' + shlex.quote(str(fake_bin)) + ':"$PATH"; '
        'claude dotfiles-probe; codex dotfiles-probe'
    )
    expected = (
        b"--dangerously-skip-permissions\ndotfiles-probe\n"
        b"--dangerously-bypass-approvals-and-sandbox\ndotfiles-probe\n"
    )
    for shell in ("bash", "zsh"):
        for mode in ("-ic", "-lic"):
            probe_command = agent_probe
            if shell == "zsh":
                probe_command += '; [[ "$SHELL" == */zsh ]]'
            result = subprocess.run([shell, mode, probe_command], env=env,
                                    capture_output=True, timeout=10)
            shell_expected = expected if shell == "zsh" else b"dotfiles-probe\ndotfiles-probe\n"
            assert result.returncode == 0 and result.stdout == shell_expected, (
                f"{shell} {mode}: agent aliases did not pass the requested permission flags"
            )
            print(f"ok - {shell} {mode} agent arguments and shell environment")
        for mode in ("-c", "-lc"):
            result = subprocess.run([shell, mode, agent_probe], env=env,
                                    capture_output=True, timeout=10)
            assert result.returncode == 0 and result.stdout == b"dotfiles-probe\ndotfiles-probe\n", (
                f"{shell} {mode}: interactive aliases affected a script"
            )
        bypass = agent_probe.replace("; claude ", "; command claude ").replace("; codex ", "; command codex ")
        result = subprocess.run([shell, "-ic", bypass], env=env,
                                capture_output=True, timeout=10)
        assert result.returncode == 0 and result.stdout == b"dotfiles-probe\ndotfiles-probe\n"
    print("ok - scripts and explicit command bypass keep native agent arguments")
