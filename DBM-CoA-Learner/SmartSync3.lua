-- SmartSync v3: incremental, bounded, discovery-only peer reconciliation.
-- WoW 3.3.5a / Lua 5.1; legacy DCOAL31 and DCOAR21 remain independent.
local PREFIX="DCOAS3"
local CHANNEL="BBLC25C"
local f=CreateFrame("Frame")
local db,ready,paused=nil,false,true
local resumeAt=math.huge
local tick=0
local queue,head={},1
local MAX_PENDING=160
local buckets,keys,dirty={}, {},true
local rebuildKeys,rebuildPos=nil,1
local peers={}
local rx={hello=0,summary=0,request=0,data=0,ack=0,invalid=0,duplicate=0,applied=0,queued=0,throttled=0}
local seq=0
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
 if #queue-head+1>=MAX_PENDING or #msg>235 or not msg:match("^[%w ;%-_%.|]+$") then return false end
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
  for i=0,31 do buckets[i]={count=0,digest=0,records={}} end
 end
 local stop=math.min(#rebuildKeys,rebuildPos+79)
 for i=rebuildPos,stop do
  local key=rebuildKeys[i]
  local b,encoded=record(key,db.knowledge[key])
  if b then
   local v=buckets[b]
   v.count=v.count+1;v.digest=(v.digest+hash(encoded))%2147483647
   v.records[#v.records+1]=encoded
   keys[encoded]=true
  end
 end
 rebuildPos=stop+1
 if rebuildPos>#rebuildKeys then rebuildKeys=nil;dirty=false;ready=true end
end
function DBMCoASmartSync3Dirty()
 dirty=true;ready=false;rebuildKeys=nil
end
local function send(msg)
 local id=channelId()
 if not id or paused or now()<resumeAt or suspended() or not enabled() then return false end
 return pcall(SendChatMessage,PREFIX..";"..msg,"CHANNEL",nil,id)
end
local function receive(msg,sender)
 if not enabled() or suspended() or paused or now()<resumeAt or not ready then return end
 if type(msg)~="string" or #msg>240 or msg:sub(1,#PREFIX+1)~=PREFIX..";" then return end
 if not msg:match("^[%w ;%-_%.|]+$") then rx.invalid=rx.invalid+1;return end
 local p=peers[sender or "?"] or {last=0,window=0,count=0}
 local t=now()
 if t-p.window>10 then p.window=t;p.count=0 end
 p.count=p.count+1
 if p.count>16 then rx.throttled=rx.throttled+1;peers[sender or "?"]=p;return end
 p.last=t;peers[sender or "?"]=p
 local payload=msg:sub(#PREFIX+2)
 if payload=="H;3" then
  rx.hello=rx.hello+1
  for i=0,31 do local b=buckets[i];enqueue("S;"..i..";"..b.count..";"..b.digest) end
 elseif payload:sub(1,2)=="S;" then
  local b,c,h=payload:match("^S;(%d+);(%d+);(%d+)$")
  b=tonumber(b);c=tonumber(c);h=tonumber(h)
  if not b or b>31 or not c or not h then rx.invalid=rx.invalid+1;return end
  rx.summary=rx.summary+1
  local own=buckets[b]
  if own and (own.count~=c or own.digest~=h) and t-(p["request"..b] or -1000)>180 then
   p["request"..b]=t;enqueue("R;"..b)
  end
 elseif payload:sub(1,2)=="R;" then
  local b=tonumber(payload:match("^R;(%d+)$"))
  if not b or b>31 then rx.invalid=rx.invalid+1;return end
  rx.request=rx.request+1
  if t-(p["serve"..b] or -1000)<180 then return end
  p["serve"..b]=t
  local list=buckets[b] and buckets[b].records or {}
  -- Bounded reconciliation window; remaining records are picked up on future rounds.
  local start=(p["offset"..b] or 0)+1
  local stop=math.min(#list,start+39)
  for i=start,stop do enqueue("D;"..list[i]) end
  p["offset"..b]=stop>=#list and 0 or stop
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
  dirty=true
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
 elseif event=="PLAYER_LEAVING_WORLD" then paused=true;resumeAt=math.huge
 elseif event=="PLAYER_ENTERING_WORLD" then paused=false;resumeAt=now()+10
 elseif event=="CHAT_MSG_CHANNEL" then
  local msg,sender,_,displayName,_,_,_,index,baseName=...
  if type(msg)~="string" or msg:sub(1,#PREFIX+1)~=PREFIX..";" then return end
  local id=channelId()
  local function matches(v) return type(v)=="string" and v:gsub("^%d+%.%s*",""):lower()==CHANNEL:lower() end
  if matches(displayName) or matches(baseName) or (id and tonumber(index)==id) then receive(msg,sender) end
 end
end)
f:SetScript("OnUpdate",function(self,dt)
 if not db or paused or now()<resumeAt or suspended() then return end
 tick=tick+dt
 if tick<1.5 then return end
 tick=0
 if dirty then buildStep();return end
 if not enabled() or (InCombatLockdown and InCombatLockdown()) then return end
 if head<=#queue then
  if send(queue[head]) then
   queue[head]=false;head=head+1
   if head>#queue then queue={};head=1 end
  end
 else
  seq=seq+1
  if seq>=40 then seq=0;enqueue("H;3") end
 end
end)
SLASH_COASMART3_1="/coasmart3"
SlashCmdList.COASMART3=function(arg)
 if not db then return end
 arg=(arg or ""):lower():match("^%s*(.-)%s*$")
 if arg=="on" then db.smartSync3Disabled=false
 elseif arg=="off" then db.smartSync3Disabled=true
 elseif arg=="hello" then enqueue("H;3")
 elseif arg=="rebuild" then DBMCoASmartSync3Dirty() end
 local n=0;for _,p in pairs(peers) do if now()-p.last<180 then n=n+1 end end
 log("enabled="..tostring(not db.smartSync3Disabled).." index="..(ready and "ready" or "building").." peers="..n.." queue="..math.max(0,#queue-head+1).." H/S/R/D="..rx.hello.."/"..rx.summary.."/"..rx.request.."/"..rx.applied.." duplicates="..rx.duplicate.." rejected="..rx.invalid.." throttled="..rx.throttled)
end
