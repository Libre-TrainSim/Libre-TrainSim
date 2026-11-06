# Modernization roadmap

The game targets **Godot 4.x** (`project.godot` → `config/features`).

## Current automation

- **CI** downloads **Godot 4.4** from the official GitHub release, runs `--import` on `src/`, then parses `.gd` files under `res://` with `src/tools/ci_validate_scripts.gd`. **Editor** and **`addons/`** are skipped (they depend on autoloads and `EditorInterface`; use the editor or `--check-only --script` for those).
- **Export jobs** use `--export-release` / `--export-debug` (Godot 4 CLI) and cache `src/.godot/` instead of the Godot 3 `.import` folder.
- **Windows export** job is still disabled (`if: false`); Linux and macOS export jobs run on push/PR. Use **Actions → CI → Run workflow** (`workflow_dispatch`) to re-run without a new push after fixing environment issues.
- **Fork PRs:** first-time contributors may need a maintainer to click **Approve and run workflows** before jobs start.

## Keeping the branch merge-ready

When `master` moves on upstream:

```bash
git remote add upstream https://github.com/Libre-TrainSim/Libre-TrainSim.git  # once
git fetch upstream
git checkout cursor/godot-4-migration-2478
git rebase upstream/master
git push --force-with-lease origin cursor/godot-4-migration-2478
```

## Next steps (suggested)

- Add **gdformat** / **gdlint** with a gradual rollout.
- Add **GUT** (or similar) for regression tests of deterministic logic.
- Track remaining **legacy shader warnings** (e.g. blur material) and clean up over time.

Pull requests should stay **small and reviewable**.
