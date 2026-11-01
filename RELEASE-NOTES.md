# DBM-CoA v5.1.1 — Legacy Network Safety TEST

Experimental checkpoint, **not** full SmartSync v3.

- Keep existing `DCOAL31` discovery/timing and `DCOAR21` archive reception formats.
- Suspend outbound transmissions on loading-screen exit and resume no sooner than 10 seconds after entering the world.
- Avoid full saved-data broadcast on login/upgrade.
- Stop network sends during combat and preserve normal boss timers and learning.
- Prevent automatic relay of imported discovery messages.
- Add legacy receiving checkbox and Low / Normal / Fast sharing intensity selector.

**Not yet implemented:** full SmartSync v3 HELLO/SUMMARY/DIFF/REQUEST/DATA/ACK handshake, record fingerprints, peer-specific retransmission, chunking, and cross-version integration tests.

Preserve existing SavedVariables and extract all 26 DBM folders into `Interface/AddOns`. Live gameplay compatibility is not yet validated.

Maintainer: Uncle Bone — https://github.com/uncle-bone/
