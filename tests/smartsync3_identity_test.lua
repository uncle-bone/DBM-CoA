-- Lua 5.1 regression for SmartSync v3's collision-safe K2/R2 record identity.
local now=100
local frames={}
local sent={}
local function makeFrame()
 local f={scripts={}}
 function f:RegisterEvent() end
 function f:SetScript(n,fn) self.scripts[n]=fn end
 function f:CreateFontString() return setmetatable({}, {__index=function() return function() end end}) end
 function f:SetPoint() end;function f:SetText() end;function f:SetChecked() end
 function f:GetChecked() return false end
 return f
end
CreateFrame=function() local f=makeFrame();frames[#frames+1]=f;return f end
UIParent={}
SlashCmdList={}
InterfaceOptions_AddCategory=function() end
GetTime=function() return now end
GetChannelName=function() return 6 end
GetInstanceInfo=function() return nil,"none" end
DBMCoASyncChannelMatches=function() return true end
DBMCoAChannelSend=function(message,channel) assert(channel==6);sent[#sent+1]=message;return true end
DBMCoALearnerDB={knowledge={
 ["N;Dungeon Alpha;0;101;201"]={kind="N",instance="Dungeon Alpha",difficulty=0,npc=101,spell=201,name="Alpha"},
 ["S;Dungeon Beta;0;102;202"]={kind="S",instance="Dungeon Beta",difficulty=0,npc=102,spell=202,name="Beta"},
}}
dofile("DBM-CoA-Learner/SmartSync3.lua")
local sync=frames[1]
sync.scripts.OnEvent(sync,"ADDON_LOADED","DBM-CoA-Learner")
sync.scripts.OnEvent(sync,"PLAYER_ENTERING_WORLD")
now=111
sync.scripts.OnUpdate(sync,1.5) -- finish initial index
assert(DBMCoASmartSync3Snapshot().ready,"initial SmartSync index did not become ready")

-- Ask for one bucket and capture its extended inventory fingerprint.
local h=5381
local bucketSource="N;Dungeon Alpha;0;101;201"
for i=1,#bucketSource do h=(h*33+bucketSource:byte(i))%2147483647 end
local bucket=h%32
sync.scripts.OnEvent(sync,"CHAT_MSG_CHANNEL","DCOAS3;I;"..bucket,"Peer-Realm",nil,"6. CoASync",nil,nil,nil,6,"CoASync")
-- A second peer asking for the same inventory before drain must reuse pending packets.
local queuedBefore=DBMCoASmartSync3Snapshot().queue
sync.scripts.OnEvent(sync,"CHAT_MSG_CHANNEL","DCOAS3;I;"..bucket,"SecondPeer-Realm",nil,"6. CoASync",nil,nil,nil,6,"CoASync")
local coalesced=DBMCoASmartSync3Snapshot()
assert(coalesced.queue==queuedBefore,"duplicate inventory request grew the pending queue")
assert(coalesced.queueDuplicates>=2,"legacy K and K2 packets were not coalesced")
local foundBucket,foundHash,foundHash2
for _=1,4 do
 now=now+2;sync.scripts.OnUpdate(sync,1.5)
 for _,wire in ipairs(sent) do
  local b,h,h2=wire:match("DCOAS3;K2;(%d+);(%d+);(%d+)")
  if b then foundBucket,foundHash,foundHash2=b,h,h2;break end
 end
 if foundHash then break end
end
assert(foundHash,"inventory response did not contain the collision-safe K2 fingerprint")

-- A matching R2 request must return the exact source record in D format.
local before=#sent
sync.scripts.OnEvent(sync,"CHAT_MSG_CHANNEL","DCOAS3;R2;"..foundBucket..";"..foundHash..";"..foundHash2,"Peer-Realm",nil,"6. CoASync",nil,nil,nil,6,"CoASync")
for _=1,3 do now=now+2;sync.scripts.OnUpdate(sync,1.5) end
local dataSent=false
for i=before+1,#sent do if sent[i]:match("^DCOAS3;D;") then dataSent=true end end
assert(dataSent,"R2 did not return the exact matching record")
local snap=DBMCoASmartSync3Snapshot()
assert(snap.inventoryRequests>=1 and snap.recordRequests>=1,"request diagnostics did not distinguish inventory and record requests")
assert(snap.dataSent>=1,"sent-data diagnostic did not increment")
print("DBM-CoA SmartSync v3 K2/R2 identity and diagnostics regression passed.")

-- v6 isolated simulator: real receive path, no network and no persistent mutation.
local liveDB=DBMCoALearnerDB
local originalCount=0
for _ in pairs(liveDB.knowledge) do originalCount=originalCount+1 end
local beforeSim=DBMCoASmartSync3Snapshot()
local sentBefore=#sent
local success,details=DBMCoASmartSync3Simulate()
assert(success,details or "isolated simulator failed")
assert(DBMCoALearnerDB==liveDB,"simulator replaced persistent database")
local afterCount=0
for _ in pairs(liveDB.knowledge) do afterCount=afterCount+1 end
assert(afterCount==originalCount,"simulator mutated SavedVariables")
assert(#sent==sentBefore,"simulator transmitted CoASync packets")
local afterSim=DBMCoASmartSync3Snapshot()
for k,v in pairs(beforeSim) do assert(afterSim[k]==v,"simulator changed live state: "..k) end
print("DBM-CoA SmartSync v3 isolated simulator regression passed; no CoASync packets sent.")
