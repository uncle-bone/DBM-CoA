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
