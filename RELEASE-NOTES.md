# DBM-CoA v5.1.2 — Stable

This release packages the current DBM-CoA main branch, including the latest learner tracker optimization.

## Included
- Maintains a running learner discovery count to avoid repeatedly recounting the full table during tracker refreshes.
- Preserves the learner tracker position when it is recreated.
- Includes all 26 DBM addon folders for WoW 3.3.5a / Conquest Reborn.
- Keeps existing SavedVariables and learned data.

## Known limitations
- Full SmartSync v3 handshake and record synchronization are not implemented.
- Research-derived timers and custom Conquest Reborn encounter mechanics still need in-game validation.
- The tracker optimization has not had a fresh in-game regression pass.

Maintainer: Uncle Bone
