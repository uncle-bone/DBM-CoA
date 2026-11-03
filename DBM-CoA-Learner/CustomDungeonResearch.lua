-- CoA custom dungeon discovery foundation (Lua 5.1).
-- Names confirmed by maintainer; map IDs, NPC IDs and mechanics require live/source evidence.
-- This file does not register speculative bosses or create timer bars.
local names = {
  ["Manastorm"] = true,
  ["Shadowbone Depths"] = true,
  ["The Temple of Embers"] = true,
  ["The Radiant Spring"] = true,
  ["Road to the Other Side"] = true,
  ["Vaults of Inquisition"] = true,
  ["Blackrock Caverns"] = true,
}
DBMCoACustomDungeonResearch = DBMCoACustomDungeonResearch or {}
for name in pairs(names) do
  DBMCoACustomDungeonResearch[name] = DBMCoACustomDungeonResearch[name] or { status = "research", verifiedMapId = nil, bossIds = {}, spellIds = {} }
end
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:SetScript("OnEvent", function()
  if not GetInstanceInfo then return end
  local zone, kind, difficulty, _, _, _, _, mapId = GetInstanceInfo()
  if not names[zone] or (kind ~= "party" and kind ~= "raid") then return end
  if type(DBMCoALearnerDB) ~= "table" then return end
  local db = DBMCoALearnerDB
  db.customDungeonObservations = db.customDungeonObservations or {}
  local entry = db.customDungeonObservations[zone] or { visits = 0, difficultyIds = {} }
  entry.visits = (entry.visits or 0) + 1
  entry.lastMapId = tonumber(mapId)
  entry.lastDifficultyId = tonumber(difficulty)
  if difficulty ~= nil then entry.difficultyIds[tostring(difficulty)] = true end
  db.customDungeonObservations[zone] = entry
end)
