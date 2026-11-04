# DBM-CoA v6.0.0 — Knowledge Summary (stable)

- Bundle source-provenance research files from CoA-Research v6 for seven priority custom dungeons, including dungeon dossiers, encounter registries, source maps, difficulty data, implementation notes, and validation guidance.
- Add passive custom-dungeon visit discovery. Use `/coadungeons` to review observed visits and candidate map IDs.
- Preserve existing native DBM modules, learner data, SavedVariables, and SmartSync v3 peer-to-peer synchronization.
- Keep research records labeled as reference candidates. This release does not claim seven complete native boss modules or verified encounter timers.
- The in-game knowledge summary was reviewed by the maintainer. Broader live encounter and timer coverage remains an open research and validation area.
# DBM-CoA v5.2.24 — Native Classic dungeon roster integration (test build)

- Register 13 additional Classic dungeon categories in DBM-Party-Vanilla's native LoadZone/SubCategories metadata.
- Add research-roster-based native encounter registration files for those dungeons. NPC-ID display names are provisional and not yet all boss-verified.
- Enable experimental dungeon predictive timers by default unless manually disabled; preserve explicit false in SavedVariables.
- Extend experimental observed-cast warnings to all 19 indexed Classic dungeons; include Uldaman Ironaya live-observed spells.
- Apply limited same-source prediction cooldowns. Full cross-engine bar arbitration and all-difficulty live testing remain pending.
- Preserve existing DBM encounter modules, learner and SmartSync wire compatibility.

**Prerelease/test build**: Native module load, encounter behavior and timers must be validated in game; not a claim that every boss has complete countdowns.

# DBM-CoA v5.2.23 — SmartSync pending-queue coalescing

- Coalesce identical unsent SmartSync v3 packets across peers to reduce repeated inventory and reconciliation traffic.
- Preserve legacy K/R/D and newer K2/R2 wire formats; no new packet requirements or SavedVariables migrations.
- Add queueDedup diagnostics and Lua 5.1 regression for concurrent legacy K and K2 inventory responses.
- Keep existing throttle, bounded queue, and encounter behavior. This optimization cannot guarantee an empty queue with active peers.

Stable release. Live v5.2.23 test: two active peers, queue decreased 159 → 135 → 117, 33 duplicate enqueue attempts coalesced, 51 data packets received (3 new records imported, 48 duplicates), rejected=0 and throttled=0. Lua 5.1 and packaging checks passed on prerelease. Mixed-version peer testing and long-duration queue behavior remain to be verified.

# DBM-CoA v5.2.22 — Collision-safe SmartSync identity

- Preserve all canonical records sharing a short fingerprint and add a second fingerprint for exact K2/R2 inventory reconciliation.
- Continue reading legacy K/R requests and D records; legacy collision requests return every record sharing the short hash.
- Expand diagnostics with inventory requests, record requests, data sent/received, and collision counts.
- Add Lua 5.1 regression coverage for inventory fingerprints and exact R2 responses.
- Keep in-game version labels tied to the installed addon metadata (5.2.22).
- Preserve existing saved knowledge, protocols and encounter features.

Stable release. Automated Lua and package checks run before publication. In-game multi-client verification remains pending.

# DBM-CoA v5.2.21 (prerelease) — CoASync identity validation

- Require both the local CoASync channel number and matching plain/decorated channel name before SmartSync v3 receives packets.
- Regression test loads the same compatibility helper used by the actual event handler and verifies valid peer receipt plus wrong-name/index rejection.
- Preserves existing protocols, saved data, and encounter functionality.

Automated Lua and package checks run before publication. In-game multi-client verification remains pending.

# DBM-CoA v5.2.20 (prerelease) — CoASync channel identity validation

- SmartSync v3 now accepts a channel message only when the local CoASync number and the plain or decorated channel name both match.
- Add Lua 5.1 regression checks for valid decorated/plain channel names, peer receipt, and rejection of wrong channel names/numbers.
- Preserve protocol framing, throttling, duplicate protection, existing SavedVariables and all encounter features.

Automated Lua and package checks run before publication. Live multi-client verification remains pending.

DBM-CoA v5.2.19 (prerelease): CoA-Research Shared Database v2.0.1 evidence integration. Learner now excludes non-hostile, friendly and player-controlled source events from new spell discovery and cast-timing knowledge, and target discovery requires an attackable NPC. Historical pet/summon IDs are retained as unverified research candidates, not static blacklists. Source-driven Classic19 timer opt-in now defaults OFF for new installs while preserving existing choices; 3.3.5a research cast/timer engines also reject player-controlled sources. Documented v2.0.1 provenance and outstanding ownership gaps. Existing SavedVariables, UI, CoASync, and v5.2.18 encounter research retained. Automated ZIP/Lua checks required; in-game validation pending.

DBM-CoA v5.2.18 (prerelease): Integrates passive, provenance-preserving CoA-Research priority encounter candidate snapshot from coa-priority-encounters-41510655077. Includes 22-instance coverage, 128 complete boss-kit SQL candidates, and selected historical ScriptDev2 boss/timer expressions. All public-source data remains explicitly NOT live Conquest Reborn verified; no new automatic boss timers are enabled. Classic19 source-derived predictive bars now require explicit opt-in (coaDungeonPredictiveTimers=true). Razorfen Kraul boss-AI and dungeon trash attribution gaps remain unresolved. Retains the v5.2.17 Status button correction and CoASync safeguards. Runtime in-game verification remains pending.

DBM-CoA v5.2.16 fixes the Learner Status button by placing it permanently on the main button row and restores chat notifications when new local NPC/spell discoveries are recorded. Verified Wailing Caverns local discovery data from user export. Existing CoASync safety and learning preserved. In-game verification pending.
