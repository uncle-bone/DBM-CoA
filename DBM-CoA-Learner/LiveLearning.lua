-- v3.6 experimental data-driven warnings; never loads remote Lua.
-- Existing DBM encounter modules remain untouched.
-- DBM-CoA v3.37.1: safe hostile-NPC combat classification and confidence-based learning.
-- 3.3.5 combat log, no retail-only APIs, no separate timer anchor.
local f=CreateFrame("Frame")
local lastCast={} -- per creature GUID and spell; cleared on combat end
local dedupe={}
local lastPrediction={}
local function data() return DBMCoALearnerDB end
local function enabled() local d=data();return d and not d.disabled and not d.experimentalDisabled end
local function npc(g)
 if type(g)~="string" then return nil end
 if g:sub(1,2)=="0x" then return tonumber(g:sub(7,10),16) end
 if g:find("^Creature%-") or g:find("^Vehicle%-") then return tonumber(g:match("%-(%d+)%-[0-9a-fA-F]+$")) end
end
local band=bit and bit.band
-- Hostile NPC flags are mandatory; pet/guardian/player-controlled units fail closed.
local function eligible(guid,flags)
 local id=npc(guid)
 if not id or id<=0 or type(flags)~="number" or not band then return nil end
 if guid:sub(1,6)=="0xF140" then return nil end -- classic player pet GUID, never boss
 if guid:sub(1,6)~="0xF130" and not guid:find("^Creature%-") and not guid:find("^Vehicle%-") then return nil end
 if band(flags,0x800)==0 or band(flags,0x3000)~=0 then return nil end
 if band(flags,0x100)~=0 or band(flags,0x7)~=0 or band(flags,0x40)==0 then return nil end
 -- If the game reports a player as controller or owner, do not generate boss mechanics.
 return id
end
local function instance()
 local n,typ,diff=GetInstanceInfo()
 -- Universal observation: instances and outdoor zones. Never infer an encounter
 -- from a player or pet source; eligible() remains the hostile-NPC gate.
 if typ~="party" and typ~="raid" then typ="world" end
 if type(n)~="string" or n=="" then n=(GetRealZoneText and GetRealZoneText()) or "" end
 if n=="" then return nil end
 return n,typ,diff or 0
end
local function getRecord(typ,inst,diff,id,sid,who,spell)
 local d=data();if not d then return nil end
 d.encounterTimers24=d.encounterTimers24 or {raid={},party={},world={}}
 d.encounterTimers24.world=d.encounterTimers24.world or {}
 local root=d.encounterTimers24[typ];if not root then return nil end
 root[inst]=root[inst] or {}
 local diffkey=tostring(diff);root[inst][diffkey]=root[inst][diffkey] or {}
 local mobs=root[inst][diffkey];local idkey=tostring(id)
 mobs[idkey]=mobs[idkey] or {name=who or ("NPC "..idkey),spells={}}
 local mob=mobs[idkey];if who and who~="" then mob.name=who end
 local skey=tostring(sid)
 mob.spells[skey]=mob.spells[skey] or {name=spell or ("Spell "..skey),samples={},casts=0}
 local rec=mob.spells[skey];if spell and spell~="" then rec.name=spell end
 return rec
end
local function intervalStats(samples)
 local sorted={}
 for _,v in ipairs(samples) do if type(v)=="number" and v>=5 and v<=180 then sorted[#sorted+1]=v end end
 if #sorted<3 then return nil,0 end
 table.sort(sorted)
 local median=sorted[math.floor((#sorted+1)/2)]
 local sum,count,min,max=0,0,999,0
 for _,v in ipairs(sorted) do
  if math.abs(v-median)<=math.max(3,median*0.20) then
   sum=sum+v;count=count+1;if v<min then min=v end;if v>max then max=v end
  end
 end
 if count<3 then return nil,count end
 local mean=sum/count
 if max-min>math.max(4,mean*0.25) then return nil,count end
 return mean,count
end
local function warn(name,who)
 if RaidWarningFrame and RaidNotice_AddMessage and ChatTypeInfo and ChatTypeInfo.RAID_WARNING then
  RaidNotice_AddMessage(RaidWarningFrame,"[Observed] "..who..": "..name,ChatTypeInfo.RAID_WARNING)
 elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[DBM Observed]|r "..who..": "..name) end
end
local function startBar(label,duration)
 if type(duration)~="number" or duration<5 or duration>180 then return end
 -- Native DBM bar renderer, never create a separate anchor.
 if DBM and DBM.Bars and type(DBM.Bars.CreateBar)=="function" then
  DBM.Bars:CreateBar(duration,"[Predicted] "..label,"Interface\\Icons\\INV_Misc_PocketWatch_01")
 end
end
SLASH_COABARS1="/coabars"
SlashCmdList.COABARS=function()
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA: Learned timers use native DBM anchors. /dbm move shows the Main and Enlarged bar groups.") end
end
f:SetScript("OnEvent",function(self,event,...)
 if event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" or event=="PLAYER_REGEN_ENABLED" then
  lastCast={};dedupe={};lastPrediction={};return
 end
 if event~="COMBAT_LOG_EVENT_UNFILTERED" or not enabled() then return end
 local inst,typ,diff=instance();if not inst then return end
 local ev=select(2,...)
 if ev~="SPELL_CAST_START" and ev~="SPELL_CAST_SUCCESS" then return end
 local guid,who,flags=select(3,...),select(4,...),select(5,...)
 local id=eligible(guid,flags);if not id then return end
 local a6,a7=select(6,...),select(7,...)
 local header=(type(a6)=="number" and (type(a7)=="string" or a7==nil)) and 10 or 8
 local sid,name=select(header+1,...),select(header+2,...)
 if type(sid)~="number" or sid<=0 then return end
 local key=tostring(guid)..":"..sid
 local now=GetTime()
 if dedupe[key] and now-dedupe[key]<3 then return end
 dedupe[key]=now
 name=(type(name)=="string" and name~="" and name) or ("Spell "..sid)
 who=(type(who)=="string" and who~="" and who) or ("NPC "..id)
 local rec=getRecord(typ,inst,diff,id,sid,who,name);if not rec then return end
 rec.casts=(rec.casts or 0)+1
 local prev=lastCast[key];lastCast[key]=now
 if prev then
  local delta=now-prev
  if delta>=5 and delta<=180 then
   rec.samples[#rec.samples+1]=math.floor(delta*10+0.5)/10
   if #rec.samples>24 then table.remove(rec.samples,1) end
  end
 end
 -- Prebuilt DBM mechanics take priority. Record observations without duplicate bars.
 local stock=DBMCoAStockTimerIndex and DBMCoAStockTimerIndex[id]
 local durations=stock and stock[sid]
 rec.stockTimer=durations and true or nil
 local mean,count=intervalStats(rec.samples)
 rec.estimate=mean;rec.confidence=count or 0
 rec.status="observed"
 if mean and count>=5 then rec.status="predicted" end
 -- Verified means explicitly validated by an encounter module or maintainer;
 -- observations must never auto-promote to verified.
 if rec.verified==true then rec.status="verified" end
 -- Observation alone is not a warning; only consistent repeated mechanics produce a prediction.
 -- Do not display duplicate predicted bars for an existing stock timer.
 -- Store measured differences for later correction/review; never overwrite stock automatically.
 if mean and count>=5 and durations and (not data().adaptive41 or data().adaptive41.enabled~=false) then
  local nearest=nil
  for _,v in ipairs(durations) do
   local gap=math.abs(mean-v)
   if not nearest or gap<nearest then nearest=gap end
  end
  rec.stockDifference=nearest
  rec.needsReview=(nearest and nearest>math.max(5,mean*0.20)) or false
 end
 if mean and count>=5 and not durations and (not lastPrediction[key] or now-lastPrediction[key]>3) then
  lastPrediction[key]=now
  startBar(who..": "..name,mean)
 end
end)
for _,e in ipairs({"COMBAT_LOG_EVENT_UNFILTERED","PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_ENABLED"}) do f:RegisterEvent(e) end

-- Raid-test inspection: /coatimings opens categorized learned timers, including Zul'Gurub.
local listFrame,listText
local function buildList()
 local db=DBMCoALearnerDB
 local data=db and db.encounterTimers24 or {}
 local lines={"DBM-CoA Encounter Knowledge: local observations + SmartSync imports", "Raid / Dungeon -> Instance -> Difficulty -> NPC -> Spell"}
 local total=0
 for _,typeName in ipairs({"raid","party"}) do
  local root=data[typeName] or {}
  local instances={}
  for k in pairs(root) do instances[#instances+1]=k end
  table.sort(instances)
  for _,inst in ipairs(instances) do
   lines[#lines+1]=(typeName=="raid" and "[RAID] " or "[DUNGEON] ")..inst
   local diffs={}
   for k in pairs(root[inst]) do diffs[#diffs+1]=k end
   table.sort(diffs)
   for _,diff in ipairs(diffs) do
    for id,boss in pairs(root[inst][diff]) do
    if tonumber(id) and tonumber(id)>0 then
     for spellId,rec in pairs(boss.spells or {}) do
      total=total+1
      if #lines<250 then
       lines[#lines+1]="  Diff "..diff.." | "..(boss.name or id).." ("..id..") | "..(rec.name or spellId).." ["..spellId.."] "..(rec.estimate and (string.format("%.1fs",rec.estimate).." / "..(rec.confidence or 0).." intervals") or "learning")
      end
     end
    end
    end
   end
  end
 end
 -- SmartSync v3 reconciles N/S discovery records in db.knowledge, separately
 -- from local interval samples. Show successfully imported discoveries here;
 -- never mislabel a discovery as a measured cooldown.
 local shared,localKnowledge=0,0
 local knowledge=db and db.knowledge or {}
 local items={}
 for key,entry in pairs(knowledge) do
  if type(entry)=="table" and (entry.kind=="N" or entry.kind=="S") and (entry.instance and entry.npc) then
   if entry.remote then shared=shared+1 else localKnowledge=localKnowledge+1 end
   items[#items+1]=entry
  end
 end
 table.sort(items,function(a,b)
  local ak=tostring(a.instance)..":"..tostring(a.npc)..":"..tostring(a.spell)
  local bk=tostring(b.instance)..":"..tostring(b.npc)..":"..tostring(b.spell)
  return ak<bk
 end)
 lines[#lines+1]="[SMARTSYNC DISCOVERIES] Imported: "..shared.." | Local: "..localKnowledge
 for _,entry in ipairs(items) do
  if #lines<490 then
   lines[#lines+1]="  ["..(entry.remote and "SHARED" or "LOCAL").."] "..tostring(entry.instance).." | NPC "..tostring(entry.npc).." | "..(entry.kind=="S" and ("Spell "..tostring(entry.spell)) or "NPC discovery").." | "..tostring(entry.name or "")
  end
 end
 if total==0 and #items==0 then lines[#lines+1]="No saved observations or SmartSync discoveries yet." end
 if total>245 or #items>245 then lines[#lines+1]="(additional records may be hidden; SavedVariables retained)" end
 return table.concat(lines,"\n")
end
SLASH_COATIMINGS1="/coatimings"
SlashCmdList.COATIMINGS=function()
 if not listFrame then
  listFrame=CreateFrame("Frame","DBMCoALearnedTimersWindow",UIParent)
  listFrame:SetWidth(640);listFrame:SetHeight(430)
  listFrame:SetPoint("CENTER")
  listFrame:SetFrameStrata("DIALOG")
  listFrame:SetMovable(true);listFrame:EnableMouse(true)
  listFrame:RegisterForDrag("LeftButton")
  listFrame:SetScript("OnDragStart",function(self) self:StartMoving() end)
  listFrame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
  local bg=listFrame:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(listFrame);bg:SetTexture(0,0,0,0.9)
  local close=CreateFrame("Button",nil,listFrame,"UIPanelCloseButton")
  close:SetPoint("TOPRIGHT",0,0)
  local scroll=CreateFrame("ScrollFrame",nil,listFrame,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",12,-32);scroll:SetPoint("BOTTOMRIGHT",-34,12)
  listText=CreateFrame("EditBox",nil,scroll)
  listText:SetMultiLine(true);listText:SetAutoFocus(false)
  listText:SetFontObject(GameFontHighlightSmall)
  listText:SetWidth(565);listText:SetHeight(12000)
  listText:EnableMouse(true)
  listText:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  scroll:SetScrollChild(listText)
 end
 listText:SetText(buildList())
 listFrame:Show()
end

-- Inspect automatic dungeon and raid learning without changing saved preferences.
-- Read-only, copyable status report. Ctrl+A then Ctrl+C in the field.
local learningWindow,learningText
local function showLearningReport(report)
 if not learningWindow then
  learningWindow=CreateFrame("Frame","DBMCoALearningCopyWindow",UIParent)
  learningWindow:SetWidth(610);learningWindow:SetHeight(205)
  learningWindow:SetPoint("CENTER",UIParent,"CENTER",0,80)
  learningWindow:SetFrameStrata("DIALOG")
  learningWindow:SetMovable(true);learningWindow:EnableMouse(true)
  learningWindow:RegisterForDrag("LeftButton")
  learningWindow:SetScript("OnDragStart",function(self) self:StartMoving() end)
  learningWindow:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
  local bg=learningWindow:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(learningWindow);bg:SetTexture(0,0,0,0.93)
  local close=CreateFrame("Button",nil,learningWindow,"UIPanelCloseButton")
  close:SetPoint("TOPRIGHT",0,0)
  local heading=learningWindow:CreateFontString(nil,"OVERLAY","GameFontNormal")
  heading:SetPoint("TOPLEFT",14,-15)
  heading:SetText("DBM-CoA Learning Status - Ctrl+A / Ctrl+C to copy")
  local scroll=CreateFrame("ScrollFrame",nil,learningWindow,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",14,-43);scroll:SetPoint("BOTTOMRIGHT",-34,14)
  learningText=CreateFrame("EditBox",nil,scroll)
  learningText:SetMultiLine(true);learningText:SetAutoFocus(false)
  learningText:SetFontObject(GameFontHighlightSmall)
  learningText:SetWidth(540);learningText:SetHeight(110)
  learningText:EnableMouse(true)
  learningText:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  scroll:SetScrollChild(learningText)
 end
 learningText:SetText(report)
 learningWindow:Show()
 learningText:SetFocus()
 learningText:HighlightText()
end
SLASH_COALEARNING1="/coalearning"
SlashCmdList.COALEARNING=function()
 local d=DBMCoALearnerDB or {}
 local name,kind,difficulty=GetInstanceInfo()
 local scope=(kind=="party" and "Dungeon") or (kind=="raid" and "Raid") or "Outside instance"
 local state=(d.disabled or d.experimentalDisabled) and "OFF" or "ON"
 local line1="DBM-CoA automatic learning: "..state.." | "..scope.." | "..tostring(name or "Unknown").." | difficulty "..tostring(difficulty or 0)
 local line2="Saved encounter categories: /coatimings | Toggle: /dbmcoa experimental on/off"
 if DEFAULT_CHAT_FRAME then
  DEFAULT_CHAT_FRAME:AddMessage(line1)
  DEFAULT_CHAT_FRAME:AddMessage(line2)
 end
 showLearningReport(line1.."\\n"..line2)
end

-- Test native DBM timer rendering without combat or learned mechanic records.
SLASH_COATEST1="/coatest"
SlashCmdList.COATEST=function()
 if not DBM or not DBM.Bars or not DBM.Bars.CreateBar then
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA: DBM native bar API unavailable") end
  return
 end
 DBM.Bars:CreateBar(15,"[TEST] DBM-CoA native timer","Interface\\Icons\\INV_Misc_PocketWatch_01")
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA: test timer started. Use /dbm move for normal/enlarged anchors.") end
end
SLASH_COASTATUS1="/coastatus"
SlashCmdList.COASTATUS=function()
 local d=DBMCoALearnerDB or {}
 local z,t=GetInstanceInfo()
 local count=0
 for _,scope in pairs(d.encounterTimers24 or {}) do for _,zones in pairs(scope) do for _,diff in pairs(zones) do for _,mob in pairs(diff) do for _ in pairs(mob.spells or {}) do count=count+1 end end end end end
 if DEFAULT_CHAT_FRAME then
  DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA: zone="..tostring(z).." type="..tostring(t).." | learned spell records="..count)
  DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA: research NPCs="..tostring(DBMCoAResearchIndex and 52 or 0).." | /coatest /coaresearch /coatimings")
 end
end


-- Read-only knowledge audit. Counts stored rows separately from unique NPC/spell
-- associations; never treats discoveries as confirmed encounter timers.
SLASH_COAKNOWLEDGE1="/coaknowledge"
SlashCmdList.COAKNOWLEDGE=function()
 local d=DBMCoALearnerDB or {}
 local rows,shared,localRows=0,0,0
 local npcSet,spellSet={},{}
 local uniqueNPC,uniqueSpells=0,0
 for _,e in pairs(d.knowledge or {}) do
  if type(e)=="table" and (e.kind=="N" or e.kind=="S") and e.instance and e.npc then
   rows=rows+1
   if e.remote then shared=shared+1 else localRows=localRows+1 end
   local base=tostring(e.instance)..":"..tostring(e.npc)
   if not npcSet[base] then npcSet[base]=true;uniqueNPC=uniqueNPC+1 end
   if e.kind=="S" and e.spell then
    local k=base..":"..tostring(e.spell)
    if not spellSet[k] then spellSet[k]=true;uniqueSpells=uniqueSpells+1 end
   end
  end
 end
 local observations,measured,predictable,verified,stockCovered=0,0,0,0,0
 local instances={}
 for _,typ in ipairs({"raid","party","world"}) do
  for inst,diffs in pairs((d.encounterTimers24 or {})[typ] or {}) do
   if type(diffs)=="table" then
    for _,mobs in pairs(diffs) do
     if type(mobs)=="table" then
      for npcId,boss in pairs(mobs) do
       if type(boss)=="table" then
        for sid,rec in pairs(boss.spells or {}) do
         if type(rec)=="table" then
          observations=observations+1
          local mean,count=intervalStats(type(rec.samples)=="table" and rec.samples or {})
          if mean then measured=measured+1 end
          local stock=DBMCoAStockTimerIndex and DBMCoAStockTimerIndex[tonumber(npcId)]
          local hasStock=stock and stock[tonumber(sid)]
          if hasStock then stockCovered=stockCovered+1 end
          if mean and count>=5 and not hasStock then predictable=predictable+1 end
          if rec.verified==true then verified=verified+1 end
          instances[typ..":"..tostring(inst)]=true
         end
        end
       end
      end
     end
    end
   end
  end
 end
 local instanceCount=0
 for _ in pairs(instances) do instanceCount=instanceCount+1 end
 local lines={
  "DBM-CoA Encounter Knowledge Summary (read-only)",
  "SmartSync stored discovery rows: "..rows.." (shared "..shared..", local "..localRows..")",
  "Unique discovered instance/NPC pairs: "..uniqueNPC,
  "Unique discovered instance/NPC/spell pairs: "..uniqueSpells,
  "Observed spell records: "..observations.." across "..instanceCount.." observed areas",
  "Measured stable intervals (3+ consistent samples): "..measured,
  "Prediction-eligible (5+ consistent samples, no indexed stock timer): "..predictable,
  "Observed spells with indexed stock timers: "..stockCovered,
  "Explicitly verified observed records: "..verified,
  "Current automatic learning: "..(enabled() and "ON" or "OFF"),
  "Shared discovery rows are NOT automatically timers or active boss warnings.",
  "Prebuilt encounter-module coverage is NOT fully audited by this command.",
  "Details: /coatimings  |  Sync: /dbmcoa smart3 status"
 }
 local report=table.concat(lines,"\n")
 local w=_G.DBMCoAKnowledgeSummaryWindow
 if not w then
  w=CreateFrame("Frame","DBMCoAKnowledgeSummaryWindow",UIParent)
  w:SetWidth(690);w:SetHeight(340);w:SetPoint("CENTER")
  w:SetFrameStrata("DIALOG");w:SetMovable(true);w:EnableMouse(true)
  w:RegisterForDrag("LeftButton");w:SetScript("OnDragStart",w.StartMoving);w:SetScript("OnDragStop",w.StopMovingOrSizing)
  w:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24,insets={left=8,right=8,top=8,bottom=8}})
  local close=CreateFrame("Button",nil,w,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-5,-5)
  local edit=CreateFrame("EditBox",nil,w)
  edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal)
  edit:SetWidth(640);edit:SetHeight(270);edit:SetPoint("TOPLEFT",24,-35)
  edit:SetScript("OnEscapePressed",function(self) self:ClearFocus();w:Hide() end)
  w.copyText=edit
 end
 w.copyText:SetText(report);w:Show();w.copyText:SetFocus();w.copyText:HighlightText()
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("DBM-CoA: /coaknowledge summary open; Ctrl+C copies selected report.") end
end
