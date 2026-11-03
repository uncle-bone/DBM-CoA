-- SmartSync v3: incremental, bounded, discovery-only peer reconciliation.
-- WoW 3.3.5a / Lua 5.1; legacy DCOAL31 and DCOAR21 remain independent.
local PREFIX="DCOAS3"
local CHANNEL="CoASync"
local f=CreateFrame("Frame")
local db,ready,paused=nil,false,true
local resumeAt=math.huge
local tick=0
local queue,head={},1
local MAX_PENDING=160
local buckets,keys,dirty={}, {},true
local rebuildKeys,rebuildPos=nil,1
local pendingDirty=false
local peers={}
local rx={hello=0,summary=0,request=0,data=0,ack=0,invalid=0,duplicate=0,applied=0,queued=0,throttled=0}
local seq=0
local initialHello=false
local BASELINE_ID="CoAArchive-N-S-Q-I-v1"
local function now() return GetTime() end
local function log(msg) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffDBM-CoA SmartSync v3|r "..msg) end end
local function hash(s)
 local h=5381
 for i=1,#s do h=(h*33+s:byte(i))%2147483647 end
 return h
end
local function channelId()
 local id=GetChannelName and GetChannelName(CHANNEL) or 0
 if type(id)=="number" and id>0 then return id end
end
local function suspended()
 local _,typ=GetInstanceInfo()
 return typ and typ~="none"
end
local function enabled()
 return db and db.smartSync3Disabled~=true and db.sharingDisabled~=true and db.channelDisabled~=true and db.channelUnsafe~=true
end
local function enqueue(msg)
 if #queue-head+1>=MAX_PENDING or #msg>231 or not msg:match("^[%w ;%-_%.|]+$") then return false end
 queue[#queue+1]=msg;rx.queued=rx.queued+1;return true
end
local function record(key,e)
 if type(e)~="table" or (e.kind~="N" and e.kind~="S") then return end
 local inst=e.instance
 local diff,nid,sid=tonumber(e.difficulty),tonumber(e.npc),tonumber(e.spell)
 if type(inst)~="string" or #inst<2 or #inst>55 or not inst:match("%a") or not diff or diff<0 or diff>100 or not nid or nid<1 or nid>100000000 or not sid or sid<0 or sid>100000000 then return end
 local name=type(e.name)=="string" and e.name or ""
 if #name>55 then return end
 if not inst:match("^[%w %-_%.]+$") or not name:match("^[%w %-_%.]+$") then return end
 local canonical=table.concat({e.kind,inst,diff,nid,sid,name},";")
 if #canonical>190 then return end
 local bucket=hash(table.concat({e.kind,inst,diff,nid,sid},";"))%32
 return bucket,canonical
end
local function buildStep()
 if not dirty then return end
 if not rebuildKeys then
  rebuildKeys={}
  for k in pairs(db.knowledge or {}) do rebuildKeys[#rebuildKeys+1]=k end
  rebuildPos=1;buckets={};keys={}
  for i=0,31 do buckets[i]={count=0,digest=0,records={},hashes={}} end
 end
 local stop=math.min(#rebuildKeys,rebuildPos+79)
 for i=rebuildPos,stop do
  local key=rebuildKeys[i]
  local b,encoded=record(key,db.knowledge[key])
  if b then
   local v=buckets[b]
   v.count=v.count+1;v.digest=(v.digest+hash(encoded))%2147483647
   v.records[#v.records+1]=encoded
   v.hashes[hash(encoded)]=encoded
   keys[encoded]=true
  end
 end
 rebuildPos=stop+1
 if rebuildPos>#rebuildKeys then rebuildKeys=nil;dirty=pendingDirty;pendingDirty=false;ready=not dirty end
end
function DBMCoASmartSync3Dirty()
 if rebuildKeys then pendingDirty=true else dirty=true;ready=false end
end
local function send(msg)
 local id=channelId()
 if not id or paused or now()<resumeAt or suspended() or not enabled() then return false end
 return DBMCoAChannelSend(PREFIX..";"..msg,id)
end
local function isSelfSender(sender)
 if type(sender)~="string" then return false end
 local player=type(UnitName)=="function" and UnitName("player") or nil
 if type(player)~="string" or player=="" then return false end
 local short=sender:match("^([^%-]+)")
 if not short or short:lower()~=player:lower() then return false end
 local realm=sender:match("%-(.+)$")
 if not realm then return true end
 local ownRealm=type(GetRealmName)=="function" and GetRealmName() or nil
 if type(ownRealm)~="string" or ownRealm=="" then return false end
 local function norm(v) return v:lower():gsub("%s+","") end
 return norm(realm)==norm(ownRealm)
end
local function receive(msg,sender)
 if isSelfSender(sender) then return end
 if not enabled() or suspended() or paused or now()<resumeAt then return end
 if type(msg)~="string" or #msg>240 or msg:sub(1,#PREFIX+1)~=PREFIX..";" then return end
 if not msg:match("^[%w ;%-_%.|]+$") then rx.invalid=rx.invalid+1;return end
 local p=peers[sender or "?"] or {last=0,window=0,count=0}
 local t=now()
 if t-p.window>10 then p.window=t;p.count=0 end
 p.count=p.count+1
 if p.count>12 then rx.throttled=rx.throttled+1;peers[sender or "?"]=p;return end
 p.last=t;peers[sender or "?"]=p
 local payload=msg:sub(#PREFIX+2)
 if payload=="H;3" then
  if not ready then return end
  rx.hello=rx.hello+1
  for i=0,31 do local b=buckets[i];if b.count>0 then enqueue("S;"..i..";"..b.count..";"..b.digest) end end
 elseif payload:sub(1,2)=="S;" then
  if not ready then return end
  local b,c,h=payload:match("^S;(%d+);(%d+);(%d+)$")
  b=tonumber(b);c=tonumber(c);h=tonumber(h)
  if not b or b>31 or not c or not h then rx.invalid=rx.invalid+1;return end
  rx.summary=rx.summary+1
  local own=buckets[b]
  if own and (own.count~=c or own.digest~=h) and t-(p["request"..b] or -1000)>180 then
   p["request"..b]=t;enqueue("I;"..b)
  end
 elseif payload:sub(1,2)=="I;" then
  if not ready then return end
  local b=tonumber(payload:match("^I;(%d+)$"))
  if not b or b>31 then rx.invalid=rx.invalid+1;return end
  rx.request=rx.request+1
  if t-(p["inventory"..b] or -1000)<120 then return end
  p["inventory"..b]=t
  local list=buckets[b].records
  local start=(p["invOffset"..b] or 0)+1
  local stop=math.min(#list,start+19)
  for i=start,stop do enqueue("K;"..b..";"..hash(list[i])) end
  p["invOffset"..b]=stop>=#list and 0 or stop
 elseif payload:sub(1,2)=="K;" then
  if not ready then return end
  local b,h=payload:match("^K;(%d+);(%d+)$")
  b=tonumber(b);h=tonumber(h)
  if not b or b>31 or not h or h>2147483646 then rx.invalid=rx.invalid+1;return end
  local found=buckets[b].hashes[h]~=nil
  if not found and t-(p["want"..h] or -1000)>180 then
   p["want"..h]=t;enqueue("R;"..b..";"..h)
  end
 elseif payload:sub(1,2)=="R;" then
  if not ready then return end
  local b,h=payload:match("^R;(%d+);(%d+)$")
  b=tonumber(b);h=tonumber(h)
  if not b or b>31 or not h then rx.invalid=rx.invalid+1;return end
  rx.request=rx.request+1
  if t-(p["serve"..h] or -1000)<180 then return end
  p["serve"..h]=t
  local entry=buckets[b].hashes[h]
  if entry then enqueue("D;"..entry) end
 elseif payload:sub(1,2)=="D;" then
  local kind,inst,diff,nid,sid,name=payload:match("^D;([NS]);([^;]+);(%d+);(%d+);(%d+);([^;]*)$")
  if not kind then rx.invalid=rx.invalid+1;return end
  local b,canonical=record("",{kind=kind,instance=inst,difficulty=diff,npc=nid,spell=sid,name=name})
  if not b or canonical~=payload:sub(3) then rx.invalid=rx.invalid+1;return end
  if keys[canonical] then rx.duplicate=rx.duplicate+1;return end
  local key=table.concat({kind,inst,diff,nid,sid},";")
  if db.knowledge[key] then rx.duplicate=rx.duplicate+1;return end
  db.knowledge[key]={kind=kind,instance=inst,difficulty=tonumber(diff),npc=tonumber(nid),spell=tonumber(sid),name=name,seen=date("%Y-%m-%d %H:%M"),remote=true}
  keys[canonical]=true;rx.applied=rx.applied+1
  if type(DBMCoALearnerNoteRemote)=="function" then DBMCoALearnerNoteRemote(key) end
  -- Do not relay received records automatically; next digest reconciliation handles them.
  DBMCoASmartSync3Dirty()
  if rx.applied%10==0 then enqueue("A;"..rx.applied) end
 elseif payload:sub(1,2)=="A;" then rx.ack=rx.ack+1
 else rx.invalid=rx.invalid+1 end
end
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LEAVING_WORLD")
f:RegisterEvent("CHAT_MSG_CHANNEL")
f:SetScript("OnEvent",function(self,event,...)
 if event=="ADDON_LOADED" then
  if ...~="DBM-CoA-Learner" then return end
  db=DBMCoALearnerDB
  if db and db.smartSync3Disabled==nil then db.smartSync3Disabled=false end
  if db then db.smartSync3=db.smartSync3 or {};db.smartSync3.schema=3;db.smartSync3.baseline=BASELINE_ID end
 elseif event=="PLAYER_LEAVING_WORLD" then paused=true;resumeAt=math.huge
 elseif event=="PLAYER_ENTERING_WORLD" then paused=false;resumeAt=now()+10
 elseif event=="CHAT_MSG_CHANNEL" then
  local msg,sender,_,displayName,_,_,_,index,baseName=...
  if type(msg)~="string" or msg:sub(1,#PREFIX+1)~=PREFIX..";" then return end
  local id=channelId()
  if DBMCoASyncChannelMatches(displayName,index,baseName) then receive(msg,sender) end
 end
end)
f:SetScript("OnUpdate",function(self,dt)
 if not db or paused or now()<resumeAt or suspended() then return end
 tick=tick+dt
 if tick<1.5 then return end
 tick=0
 if dirty then buildStep();return end
 if not initialHello then initialHello=true;enqueue("H;3") end
 if not enabled() or (InCombatLockdown and InCombatLockdown()) then return end
 if head<=#queue then
  if send(queue[head]) then
   queue[head]=false;head=head+1
   if head>#queue then queue={};head=1 end
  end
 else
  seq=seq+1
  if seq>=2400 then seq=0;enqueue("H;3") end
 end
end)
function DBMCoASmartSync3Snapshot()
 local n=0
 for _,p in pairs(peers) do if now()-p.last<180 then n=n+1 end end
 return {ready=ready,peers=n,queue=math.max(0,#queue-head+1),hello=rx.hello,summaries=rx.summary,requests=rx.request,applied=rx.applied,duplicates=rx.duplicate,rejected=rx.invalid,throttled=rx.throttled}
end
SLASH_COASMART3_1="/coasmart3"
function DBMCoASmartSync3Command(arg)
 if not db then return end
 arg=(arg or ""):lower():match("^%s*(.-)%s*$")
 if arg=="on" then db.smartSync3Disabled=false
 elseif arg=="off" then db.smartSync3Disabled=true
 elseif arg=="hello" then enqueue("H;3")
 elseif arg=="rebuild" then DBMCoASmartSync3Dirty() end
 local n=0;for _,p in pairs(peers) do if now()-p.last<180 then n=n+1 end end
 log("baseline="..BASELINE_ID.." learned="..tostring(db.knowledge and "persistent" or "none").." enabled="..tostring(not db.smartSync3Disabled).." index="..(ready and "ready" or "building").." peers="..n.." queue="..math.max(0,#queue-head+1).." H/S/R/D="..rx.hello.."/"..rx.summary.."/"..rx.request.."/"..rx.applied.." duplicates="..rx.duplicate.." rejected="..rx.invalid.." throttled="..rx.throttled)
end
SlashCmdList.COASMART3=DBMCoASmartSync3Command

-- Separate settings category avoids clipping the existing 3.3.5 interface panel.
local panel=CreateFrame("Frame","DBMCoASmartSync3Panel",UIParent)
panel.name="DBM-CoA SmartSync v3"
local title=panel:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
title:SetPoint("TOPLEFT",16,-16)
local version=(GetAddOnMetadata and GetAddOnMetadata("DBM-CoA-Learner","Version")) or "unknown"
title:SetText("DBM-CoA | SmartSync v3 | "..version)
local help=panel:CreateFontString(nil,"ARTWORK","GameFontHighlight")
help:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-16)
help:SetText("Incremental discovery reconciliation on CoASync. Legacy receive stays available.")
local check=CreateFrame("CheckButton",nil,panel,"InterfaceOptionsCheckButtonTemplate")
check:SetPoint("TOPLEFT",16,-100)
local label=check:CreateFontString(nil,"ARTWORK","GameFontNormal")
label:SetPoint("LEFT",check,"RIGHT",5,0);label:SetText("Enable SmartSync v3 (recommended)")
check:SetScript("OnShow",function(self) self:SetChecked(db and not db.smartSync3Disabled) end)
check:SetScript("OnClick",function(self) if db then db.smartSync3Disabled=not self:GetChecked() end end)
local status=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
status:SetPoint("TOPLEFT",16,-155)
status:SetText("Use /dbmcoa smart3 for peer, queue and reconciliation diagnostics.")
if type(InterfaceOptions_AddCategory)=="function" then InterfaceOptions_AddCategory(panel) end
