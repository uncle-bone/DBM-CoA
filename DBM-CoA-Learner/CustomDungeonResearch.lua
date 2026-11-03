-- CoA custom dungeon discovery foundation (Lua 5.1).
-- Names confirmed by maintainer; map IDs, NPC IDs and mechanics require live/source evidence.
-- This file does not register speculative bosses or create timer bars.
local names = {
  ["Manastorm"] = true,
  ["Shadowbone Depths"] = true,
  ["The Temple of Embers"] = true,
  ["The Radiant Spring"] = true,
  ["Road to the Other Side"] = true,
  ["Road to De Other Side"] = true,
  ["Vaults of Inquisition"] = true,
  ["Vaults of the Inquisition"] = true,
  ["Blackrock Caverns"] = true,
}
DBMCoACustomDungeonResearch = DBMCoACustomDungeonResearch or {}
for name in pairs(names) do
  DBMCoACustomDungeonResearch[name] = DBMCoACustomDungeonResearch[name] or { status = "research", verifiedMapId = nil, bossIds = {}, spellIds = {} }
end
-- Source-derived map candidates, not verified live instance identifiers.
-- Never create boss timers or override native DBM modules from these alone.
DBMCoACustomDungeonResearch["Road to the Other Side"].candidateMapId = 937
DBMCoACustomDungeonResearch["Road to De Other Side"].candidateMapId = 937
DBMCoACustomDungeonResearch["Vaults of Inquisition"].candidateMapId = 936
DBMCoACustomDungeonResearch["Vaults of the Inquisition"].candidateMapId = 936
DBMCoACustomDungeonResearch["Manastorm"].modeOrProgression = true
DBMCoACustomDungeonResearch.source = "CoA-Research/research/dbm/v6"
local lastSignature
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:SetScript("OnEvent", function()
  if not GetInstanceInfo then return end
  local zone, kind, difficulty, _, _, _, _, mapId = GetInstanceInfo()
  if not names[zone] or (kind ~= "party" and kind ~= "raid") then return end
  local signature = tostring(zone)..":"..tostring(mapId)..":"..tostring(difficulty)
  if lastSignature == signature then return end
  if type(DBMCoALearnerDB) ~= "table" then return end
  lastSignature = signature
  local db = DBMCoALearnerDB
  db.customDungeonObservations = db.customDungeonObservations or {}
  local entry = db.customDungeonObservations[zone] or { visits = 0, difficultyIds = {} }
  entry.visits = (entry.visits or 0) + 1
  entry.lastMapId = tonumber(mapId)
  entry.lastDifficultyId = tonumber(difficulty)
  if difficulty ~= nil then entry.difficultyIds[tostring(difficulty)] = true end
  db.customDungeonObservations[zone] = entry
end)

-- v6 research visibility, without claiming encounter modules or verified timers.
SLASH_DBMCOADUNGEONS1 = "/coadungeons"
SlashCmdList.DBMCOADUNGEONS = function()
 if not DEFAULT_CHAT_FRAME then return end
 DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffDBM-CoA v6 custom dungeon research|r (passive observation; no unverified boss timers)")
 local ordered = {"Manastorm","Shadowbone Depths","The Temple of Embers","The Radiant Spring",
  "Road to the Other Side","Vaults of Inquisition","Blackrock Caverns"}
 for _,name in ipairs(ordered) do
  local e = DBMCoACustomDungeonResearch[name]
  local obs = DBMCoALearnerDB and DBMCoALearnerDB.customDungeonObservations
  local o = obs and (obs[name] or (name=="Road to the Other Side" and obs["Road to De Other Side"])
   or (name=="Vaults of Inquisition" and obs["Vaults of the Inquisition"]))
  local suffix = o and (" visits="..tostring(o.visits or 0).." observedMap="..tostring(o.lastMapId or "?")) or " not yet observed"
  DEFAULT_CHAT_FRAME:AddMessage(" - "..name..(e.candidateMapId and (" map candidate="..e.candidateMapId) or "")..suffix)
 end
end
