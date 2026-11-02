# Priority instance encounter source candidates (research only)

Current upstream snapshot: [CoA-Research release coa-priority-encounters-41510655077](https://github.com/uncle-bone/CoA-Research/releases/tag/coa-priority-encounters-41510655077).

- [Structured encounter candidates](https://github.com/uncle-bone/CoA-Research/releases/download/coa-priority-encounters-41510655077/dbm-priority-encounters.json)
- [Coverage report](https://github.com/uncle-bone/CoA-Research/releases/download/coa-priority-encounters-41510655077/coverage-report.json)
- [Full seven-repository source archive](https://github.com/uncle-bone/CoA-Research/releases/download/coa-priority-encounters-41510655077/CoA-All-Instance-Scripts.zip)
- [Successful collection workflow](https://github.com/uncle-bone/CoA-Research/actions/runs/41510655077)

## Provenance and verification policy

These are **public-source candidates, not confirmed live Conquest Reborn behavior**. The upstream database covers 22 instances and includes 128 complete global CoA boss-kit SQL candidate rows from two revisions. Retain source revision, NPC/spell IDs, event/difficulty, initial/repeat timers, health threshold, target type, cast flags, base-point overrides, and comment/boss-name candidate; do not merge alternate revisions into a single asserted runtime configuration.

Historical ScriptDev2 references include Mutanus (Wailing Caverns) and Jammal'an/Ogom (Sunken Temple), with timer assignments parsed from older script styles. These are **not live-verified timings**.

The coverage report identifies **Razorfen Kraul** as the remaining boss-AI source gap. An unvalidated Charlga-like fork must not be counted as confirmed evidence. No explicitly attributed trash mechanics may be inferred merely from generic creature, pet, escort, quest, or shared AI files. All timer, phase, and trash behavior needs independent live combat-log verification.

## Integration safety

Keep these records in research-only space. Do not enable automated timers, warnings, encounter IDs, or CoASync propagation based solely on this snapshot. Any promotion to runtime DBM mechanics requires per-record source provenance plus matching live-server evidence. Record unknowns and conflicting IDs without deleting learned player data.
