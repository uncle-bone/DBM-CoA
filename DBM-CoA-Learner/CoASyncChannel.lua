-- Validate WoW 3.3.5a CHAT_MSG_CHANNEL identity for the locally joined CoASync.
local CHANNEL = "CoASync"

local function matches(name)
 if type(name)~="string" then return false end
 name=name:gsub("^%s+",""):gsub("%s+$","")
 name=name:gsub("^%d+%.%s*","")
 return name:lower()==CHANNEL:lower()
end

function DBMCoASyncChannelMatches(displayName, channelIndex, baseName)
 local expected=GetChannelName and GetChannelName(CHANNEL) or 0
 local received=tonumber(channelIndex)
 if type(expected)~="number" or expected<=0 or not received or received~=expected then return false end
 return matches(baseName) or matches(displayName)
end
