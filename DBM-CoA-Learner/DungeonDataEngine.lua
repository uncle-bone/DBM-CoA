-- Centralized source-backed dungeon coverage. No DBM modules or menus are registered.
-- Candidate IDs are not proof of live CoA encounters. Only observed casts produce alerts.
-- Existing LiveLearning owns learned intervals and native DBM prediction bars.
local roster = {
 ["Blackrock Caverns"] = { bosses = {"Rom'ogg Bonecrusher", "Corla, Herald of Twilight", "Karsh Steelbender", "Beauty", "Ascendant Lord Obsidius"}, spells = {[76512]=true,[76325]=true,[75590]=true,[76478]=true,[76572]=true,[76502]=true} },
 ["Road to the Other Side"] = { npcs = {[162716]="Chimeric Embryo",[162715]="Drak'math",[162711]="Muzah"} },
 ["Road to De Other Side"] = { alias = "Road to the Other Side" },
 ["Vaults of Inquisition"] = { npcs = {[162700]="Merciless Echo",[162703]="Darkandle",[162704]="Deceiver"} },
 ["Vaults of the Inquisition"] = { alias = "Vaults of Inquisition" },
}
local listed = {"Shadowbone Depths","Temple of Embers","The Temple of Embers","The Radiant Spring","Karazhan Crypts","Tor'Watha","Manastorm Endless"}
for _,name in ipairs(listed) do roster[name] = { bosses = {}, npcs = {} } end
DBMCoADungeonDataEngine = { roster = roster, source = "v6 research candidates; not live verified" }
local frame = CreateFrame("Frame")
local active, last = nil, {}
local function zone()
 local name,kind = GetInstanceInfo()
 if kind ~= "party" then active=nil;last={};return end
 local entry=roster[name]
 if entry and entry.alias then entry=roster[entry.alias] end
 active=entry;last={}
end
local function npcId(guid)
 if type(guid)~="string" then return nil end
 if guid:sub(1,6)=="0xF130" then return tonumber(guid:sub(7,10),16) end
 if guid:find("^Creature%-") then return tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")) end
 return nil
end
local band=bit and bit.band
local function combat(...)
 if not active or not band then return end
 local db=DBMCoALearnerDB
 if db and (db.disabled or db.experimentalDisabled or db.coaDungeonResearchWarnings==false) then return end
 local event=select(2,...)
 if event~="SPELL_CAST_START" and event~="SPELL_CAST_SUCCESS" then return end
 local offset=type(select(3,...))=="boolean" and 1 or 0
 local guid,flags=select(3+offset,...),select(5+offset,...)
 if type(flags)~="number" or band(flags,0x800)==0 or band(flags,0x3000)~=0 or band(flags,0x100)~=0 then return end
 local id=npcId(guid)
 local sid=select(9+offset,...)
 if type(sid)~="number" then return end
 -- Never alert on arbitrary trash casts. A spell whitelist or named source boss is required.
 local knownBoss=id and active.npcs and active.npcs[id]
 if not knownBoss and not (active.spells and active.spells[sid]) then return end
 if DBMCoAStockTimerIndex and id and DBMCoAStockTimerIndex[id] and DBMCoAStockTimerIndex[id][sid] then return end
 local key=tostring(id or 0)..":"..sid
 local now=GetTime()
 if last[key] and now-last[key]<8 then return end
 last[key]=now
 local spell=GetSpellInfo(sid) or ("Spell "..sid)
 local msg="[CoA source candidate / observed cast] "..(knownBoss or "Dungeon enemy")..": "..spell
 if DBM and DBM.AddMsg then DBM:AddMsg(msg) elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end
end
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent",function(_,event,...) if event=="COMBAT_LOG_EVENT_UNFILTERED" then combat(...) else zone() end end)
SLASH_COADUNGEONDATA1="/coadungeondata"
SlashCmdList.COADUNGEONDATA=function()
 local name,kind=GetInstanceInfo()
 local e=roster[name]
 if e and e.alias then e=roster[e.alias] end
 local msg="DBM-CoA centralized dungeon data: "..tostring(name).." ("..tostring(kind)..") | "..(e and "source candidates available; live casts only" or "no custom roster").." | learned timers: /coatimings"
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end
end
