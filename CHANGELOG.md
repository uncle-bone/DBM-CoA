## 5.1.3-TEST — Background-performance checkpoint
- Avoid polling GetInstanceInfo/map state every two seconds when no zone transition occurred; refresh encounter state on world entry and zone changes.
- Throttle archive indexing to at most one chunk per 100 ms rather than once per frame; retain no-combat guard.
- Reduce pending discovery and timing queue limits to 1,500 and 600; preserve stored saved knowledge and timing aggregates.
- Add concise Learner loading and ready chat messages, and expose existing /dbmcoa perf diagnostic counters.
- Count accepted remote discoveries in the cached UI counter.
- Preserve DBM-CoA saved observations, tracker positioning, existing shared BBLC25C channel and older message formats.
- No addon CPU attribution or live 3.3.5a test yet; use alongside BoneProfiler in controlled comparisons.

## 5.1.2 — Stable learner tracker update
- Keep a maintained learner discovery counter instead of recounting the full table on each tracker refresh.
- Preserve the learner tracker position when the window is recreated.
- Preserve existing learned data and SavedVariables.
- Full SmartSync v3 and in-game validation of research-derived mechanics remain outstanding.

# Changelog

All published versions and downloadable packages are listed under [Releases](https://github.com/robsdow87/DBM-CoA/releases).

## Unreleased

- Repository initialized; awaiting verified current addon source.
