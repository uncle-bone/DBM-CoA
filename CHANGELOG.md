## 5.2.10-TEST — CoASync channel migration
- Move DBM-CoA Learner sharing and listening from BBLC25C to CoASync.
- Preserve 20-second guarded autojoin, join notifications, Lua 5.1 validation, and Learner UI.
- Do not leave BBLC25C, change existing channel memberships, or alter /1 General.
- Other addons must migrate separately to exchange data on CoASync.

## 5.2.9-TEST — Fix Learner compile failure
- Fix malformed string concatenation in `/dbmcoa status` which prevented Learner.lua from compiling, disabling the Learner window, slash commands, and BBLC25C joining.
- Enforce Lua 5.1 syntax validation in the GitHub release pipeline.
- Preserve Learner UI and existing channel-join notifications; in-game verification still required.

## 5.2.7-TEST — Learner window recovery and channel diagnostics
- /dbmcoa ui on recenters and raises the Learner window; reports UI initialization errors.
- Learner initialization continues if the status window fails to construct.
- Print guarded BBLC25C join attempts and errors in chat; retain membership success notifications.
- Live validation required; avoid channel replacement on custom clients.

## 5.2.6-TEST — Join confirmation and chat notification
- Confirm actual BBLC25C membership and announce the assigned channel number in chat.
- Retain the 20-second startup grace, stable-channel checks and protection against unexpected channel changes.
- Limit join attempts to three, spaced 15 seconds apart, and report failed attempts in status.
- Never change chat-frame subscriptions; user controls channel visibility.
- Live Conquest Reborn validation pending.

## 5.2.5-TEST — Guarded shared-channel autojoin
- Restore BBLC25C autojoin after a 20-second startup grace period with channel-slot and stable-list checks.
- Halt autojoin if an attempted join changes the channel list without joining BBLC25C.
- Never force /1 or another channel number, leave channels, or change default chat subscriptions.
- Report join state in /dbmcoa status. Requires live client verification; cannot guarantee client slot behavior.

## 5.2.4-TEST — Restore 20-second channel maintenance interval
- Check existing BBLC25C membership on a 20-second cadence, not 10 seconds.
- Keep emergency safety: no automatic channel joins or chat-frame modifications.

## 5.2.3-TEST — Emergency channel safety
- Remove automatic BBLC25C joins and automatic chat-frame channel changes to protect /1 General on Conquest Reborn.
- Continue sharing on an already joined BBLC25C channel using its resolved number.
- Preserve SmartSync v3 controls, rate limits and saved data. No live game validation.

## 5.2.2-TEST — Faster shared-channel recovery and unified SmartSync commands
- Join BBLC25C after 10 seconds; recheck membership and retry every 15 seconds if the client does not confirm joining. Never evict existing channels.
- Hide only BBLC25C from the default chat frame once per login; manual Chat Settings opt-in remains respected afterward.
- Expose SmartSync v3 via /dbmcoa smart3 [hello/rebuild/on/off], retain /coasmart3 alias, and update help/status text.
- Not live-tested in Conquest Reborn.

## 5.2.1-TEST — Restore shared-channel autojoin
- Fix regression introduced in 5.1.9: DBM-CoA can again join BBLC25C automatically after its 20-second grace period when the channel is not already present.
- Never leave, replace, rename, or reorder existing channels; allow the game client to refuse the join if the channel limit is reached.
- Retain the 1.05-second global DBM outbound anti-spam gate and additive SmartSync v3 database protocol.
- No live 3.3.5a channel-slot verification performed.

## 5.2.0-TEST — Additive encounter database synchronization
- Keep packaged CoA archive baseline separate from persistent per-character learned encounter records; record SmartSync v3 schema and baseline identity without rewriting old SavedVariables.
- Extend DCOAS3: HELLO/SUMMARY mismatch -> fingerprint inventory (I/K) -> request only absent record hashes (R) -> validated record transfer (D) -> optional ACK.
- Incrementally build 32 fingerprint buckets, with constant-time per-bucket fingerprint lookup and bounded 20-record inventory windows.
- Reconcile in both directions through each client's independent HELLO/SUMMARY; add one initial handshake after indexing.
- Retain shared one-outgoing-message-per-1.05-seconds DBM throttle across DCOAL31, DCOAR21 and DCOAS3, existing-channel-only BBLC25C mode, and 12 v3 inbound messages per sender per 10 seconds.
- Never replace existing learned records or automatically rebroadcast received discoveries.
- Correct Learner TOC version to 5.2.0-TEST.
- Experimental: no in-game multi-client validation; timing aggregates and robust collision-resistant inventory paging remain outstanding. Old clients can still transmit rapidly; local throttle cannot constrain remote addons.

## 5.1.8-TEST — SmartSync anti-spam safety checkpoint
- Route all three DBM-CoA protocol senders (DCOAL31, DCOAR21, DCOAS3) through a single shared hard gate of at most one outgoing message per 1.05 seconds.
- Suppress routine legacy heartbeat and SmartSync v3 HELLO traffic; archive announcements reduced to at most hourly.
- Limit archive outbound pending work to 200 messages and retain existing SmartSync v3 queue bounds.
- Display only DBM protocol packets as hidden chat events on BBLC25C; other addon traffic remains visible.
- Avoid automatic BBLC25C joining when absent, rather than risk changing occupied channel order. Existing-channel-only mode requires another addon or manual safe channel join.
- Add shared send-gate counters to /dbmcoa status.
- Preserve existing SavedVariables, learned discoveries, legacy protocols and experimental SmartSync v3.
- IMPORTANT: This is a partial anti-spam build, not full two-way differential SmartSync. The existing v3 bucket request still transfers bounded records without exact per-record set comparison. No simulated-peer or live-game tests have been run.

## 5.1.8 — Stable release
- Promote the current v5.1.7-TEST main-branch build as stable with corrected version and maintainer branding in the main DBM window.
- Include the existing SmartSync v3 discovery-reconciliation implementation and tracker updates.
- Preserve all existing SavedVariables and learned data.
- SmartSync v3 live client interoperability and research-derived encounter behavior still need in-game validation.

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
