# DBM-CoA v5.2.0-TEST — Database-based SmartSync v3

Separate shipped archive baseline from persistent learned encounter discoveries. The DCOAS3 protocol now exchanges compact per-record inventory hashes and requests missing records individually instead of transferring entire mismatched buckets. Incremental index building, rate limiting, strict validation and additive merges are retained.

The v5.1.9 shared outgoing DBM throttle remains: at most one outgoing message per 1.05 seconds across all three DBM protocols on BBLC25C. It cannot control traffic from other players' older addons.

Run /coasmart3 for diagnostics and /coasmart3 hello to start a handshake. Legacy discovery and archive protocols remain available.

TEST limitations: no live multi-client test or simulated peer harness run; timing aggregates not reconciled through v3, hash collisions and paging remain edge cases, and the addon will not automatically join BBLC25C if absent. Back up SavedVariables before installation.

Maintainer: Uncle Bone
