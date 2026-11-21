# 2026-11-21: Uninstall removes only grasp's own installs

Status: done · Claude Code · branch `main`

- **Asked:** Make `install.sh --uninstall` remove only what `install.sh` installed: a symlink, or a folder holding a `.source` file.
- **Changed:** `--uninstall` now leaves a `grasp` folder it did not install and says it skipped it; before, any folder holding a `SKILL.md` was deleted.
- **Checked:** `tests/grasp-tools.sh`: `110 passed, 0 failed`; the new test failed before the fix.
- **Problems:** none
- **Next:** nothing

<details><summary>4 files touched, 1 of them tests</summary>
<ul><li><code>install.sh</code>: uninstall removes a symlink or a folder with <code>.source</code>, and skips anything else with a message</li><li><code>tests/grasp-tools.sh</code>: <code>test_uninstall_removes_only_own_installs</code></li><li><code>docs/superpowers/specs/2026-11-21-run-records-overview-workspaces-design.md</code>: dropped the open item this fixes</li><li><code>docs/how-it-works/runs/README.md</code>: rebuilt</li></ul>
</details>
