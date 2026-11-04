-- WoW 3.3.5a / Lua 5.1. Non-invasive encounter observation for nine custom targets.
-- No speculative boss IDs, spell IDs, or timers are registered.
DBMCoACustomDungeons = DBMCoACustomDungeons or { targets = {}, aliases = {} }
local C = DBMCoACustomDungeons
local function norm(s) return type(s)=="string" and s:lower():gsub("[^%w]", "") or "" end
function C:RegisterTarget(name, aliases, mode)
 local target={name=name, mode=mode and true or false, status="awaiting verified boss mechanics"}
 self.targets[name]=target
 self.aliases[norm(name)]=name
 for _,alias in ipairs(aliases or {}) do self.aliases[norm(alias)]=name end
end
local frame=CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
local current,signature=nil,nil
local function store()
 if type(DBMCoACustomDungeonsDB)~="table" then DBMCoACustomDungeonsDB={} end
 local db=DBMCoACustomDungeonsDB
 if type(db.observations)~="table" then db.observations={} end
 return db
end
local function observeZone()
 if not GetInstanceInfo then return end
 local zone,kind,difficulty,_,_,_,_,mapId=GetInstanceInfo()
 local target=C.aliases[norm(zone)]
 if not target or (kind~="party" and kind~="raid") then current=nil;signature=nil;return end
 current=target
 local sig=tostring(target)..":"..tostring(mapId)..":"..tostring(difficulty)
 if sig==signature then return end
 signature=sig
 local db=store()
 local entry=db.observations[target] or {visits=0,events={},npcIds={},spellIds={}}
 entry.visits=entry.visits+1
 entry.lastMapId=tonumber(mapId)
 entry.lastDifficulty=tonumber(difficulty)
 db.observations[target]=entry
end
frame:SetScript("OnEvent",function(_,event,...)
 if event=="ADDON_LOADED" then
  if ...=="DBM-Party-Vanilla" then store() end
 elseif event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then observeZone()
 elseif event=="COMBAT_LOG_EVENT_UNFILTERED" and current then
  local _,subevent,_,sourceGUID,_,_,_,destGUID,_,_,spellId=...
  if type(subevent)~="string" then return end
  -- Observe only significant combat events, with strict caps to avoid unbounded SavedVariables.
  if subevent~="SPELL_CAST_START" and subevent~="SPELL_CAST_SUCCESS" and subevent~="UNIT_DIED" then return end
  local db=store();local e=db.observations[current]
  if not e then return end
  e.events=e.events or {};e.npcIds=e.npcIds or {};e.spellIds=e.spellIds or {}
  local function npc(guid)
   if type(guid)~="string" then return end
   local hex=guid:match("^0x[0-9A-Fa-f]+$")
   if not hex then return end
   local id=tonumber(guid:sub(7,10),16)
   if id and id>0 then e.npcIds[id]=true end
  end
  if subevent=="UNIT_DIED" then npc(destGUID) else npc(sourceGUID) end
  if type(spellId)=="number" and spellId>0 and spellId<100000000 then e.spellIds[spellId]=true end
  local count=0;for _ in pairs(e.events) do count=count+1 end
  if count<100 or e.events[subevent] then e.events[subevent]=(e.events[subevent] or 0)+1 end
 end
end)
SLASH_DBMCOACUSTOM1="/coacustom"
SlashCmdList.DBMCOACUSTOM=function()
 if not DEFAULT_CHAT_FRAME then return end
 DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA Custom Dungeons: nine targets registered; encounter mechanics awaiting verification")
 local db=store()
 for name,target in pairs(C.targets) do
  local o=db.observations[name]
  DEFAULT_CHAT_FRAME:AddMessage(" - "..name..(target.mode and " [procedural]" or "").." visits="..(o and o.visits or 0).." map="..(o and tostring(o.lastMapId or "?") or "?"))
 end
end
