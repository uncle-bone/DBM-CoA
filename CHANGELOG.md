## 5.1.4-TEST — SmartSync v3 discovery reconciliation
- New separate DCOAS3 protocol on the existing BBLC25C channel, alongside legacy DCOAL31 and DCOAR21.
- HELLO, bucket SUMMARY, differential REQUEST, validated DATA and periodic ACK messages.
- 32 deterministic discovery buckets with stable content digests (excluding timestamps); 80-record incremental index steps and paced sends.
- Bounded 160-message outgoing queue, 16 messages per sender per 10 seconds, 40-record bucket serving windows and 180-second request cooldown.
- Validate instance, NPC/spell identifiers, names and wire lengths; do not auto-relay imported data.
- Default enabled, separate in-game SmartSync v3 checkbox and /coasmart3 diagnostics.
- Keep prior saved data and existing Learner/ArchiveShare protocols; 10-second loading guard and combat/instance network pause.
- Scope: learned NPC/spell discovery reconciliation. Full timing aggregate reconciliation and in-game protocol validation remain future work.

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
