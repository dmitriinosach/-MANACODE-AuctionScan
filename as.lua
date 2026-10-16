local ADDON, ns = ...
ns.ADDON = ADDON
ns.VERSION = "0.1.0"
function ns.say(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff3399ff[MANACODE]|r |cffffdb6bAuctionScan|r: " .. tostring(msg))
end
