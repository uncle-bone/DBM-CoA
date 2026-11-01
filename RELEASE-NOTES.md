# DBM-CoA v5.1.3-TEST — Performance checkpoint

This experimental release reduces recurring idle tracker and archive-index work, while retaining encounter learning, saved data and shared BBLC25C compatibility.

Changes: event-driven instance refresh, paced archive index, lower bounded network queues, chat initialization/completion messages, corrected learned-record count, /dbmcoa perf diagnostics.

This package is a test build. The recurring five-second BoneProfiler spike is not proven to originate in DBM; no live game regression or CPU test has yet been performed. SmartSync v3 full protocol remains outstanding. Back up SavedVariables before testing.

Maintainer: Uncle Bone
