-- Lua 5.1 regression test for DBM-CoA's WoW 3.3.5a CoASync channel identity check.
dofile("DBM-CoA-Learner/CoASyncChannel.lua")
GetChannelName=function(name) assert(name=="CoASync");return 6 end
assert(DBMCoASyncChannelMatches("6. CoASync",6,"CoASync"),"decorated display + plain base name rejected")
assert(DBMCoASyncChannelMatches("CoASync",6,"CoASync"),"plain channel name rejected")
assert(DBMCoASyncChannelMatches("6. CoASync",6,nil),"decorated-only channel name rejected")
assert(not DBMCoASyncChannelMatches("6. General",6,"General"),"wrong channel name accepted")
assert(not DBMCoASyncChannelMatches("7. CoASync",7,"CoASync"),"wrong local channel index accepted")
assert(not DBMCoASyncChannelMatches("6. CoASync",nil,"CoASync"),"missing channel index accepted")
print("DBM-CoA CoASync channel validation regression passed.")
