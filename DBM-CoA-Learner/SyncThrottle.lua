-- Shared per-client CoASync send gate for DCOAL31, DCOAR21, DCOAS3.
-- All DBM-CoA channel senders MUST call this function; WoW 3.3.5a Lua 5.1.
local last=-1000
local sent=0
local deferred=0
local failed=0
function DBMCoAChannelSend(message,id)
 local t=GetTime()
 if t-last<1.05 then deferred=deferred+1;return false,"rate-limited" end
 if type(id)~="number" or id<1 or type(message)~="string" or #message>235 then return false,"invalid" end
 if InCombatLockdown and InCombatLockdown() then return false,"combat" end
 local _,instanceType=GetInstanceInfo()
 if instanceType and instanceType~="none" then return false,"instance" end
 if type(GetFramerate)=="function" and GetFramerate()<25 then return false,"low-fps" end
 last=t -- reserve the slot before dispatch to prevent nested sends
 local ok,err=pcall(SendChatMessage,message,"CHANNEL",nil,id)
 if ok then sent=sent+1 else failed=failed+1 end
 return ok,err
end
function DBMCoAChannelStats()
 return sent,deferred,failed
end
