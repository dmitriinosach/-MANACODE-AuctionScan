local ADDON, ns = ...
local UI = {}
ns.UI = UI
local built = false
function UI.SetEmbedded(active)
end
local function build()
    if built or not AuctionFrame then return end
    built = true
    AuctionFrame:HookScript("OnHide", function()
        if ns.Scan.state.phase ~= "idle" then ns.Scan.Trace("AuctionFrame hidden") end
    end)
end
function UI.Status(text)
    if ns.Trader then ns.Trader.Status(text) end
end
ns.Scan.onStatus = UI.Status
local events = ns.NewFrame("Frame")
ns.Listen(events, "ADDON_LOADED")
ns.Listen(events, "PLAYER_LOGOUT")
ns.Listen(events, "AUCTION_HOUSE_SHOW")
ns.Listen(events, "AUCTION_HOUSE_CLOSED")
ns.Listen(events, "AUCTION_ITEM_LIST_UPDATE")
ns.Listen(events, "PLAYER_FLAGS_CHANGED")
ns.Listen(events, "UI_ERROR_MESSAGE")
ns.Listen(events, "CHAT_MSG_SYSTEM")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON then
            ns.Store.DB()
            ns.Scan.Restore()
        elseif arg1 == "Blizzard_AuctionUI" then
            build()
        end
    elseif event == "PLAYER_LOGOUT" then
        ns.Scan.Save()
    elseif event == "AUCTION_HOUSE_SHOW" then
        build()
        ns.Scan.OnShow()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        ns.Scan.OnClose()
        if ns.Buy then ns.Buy.OnClose() end
    elseif event == "AUCTION_ITEM_LIST_UPDATE" then
        ns.Scan.OnListUpdate()
        if ns.Buy then ns.Buy.OnListUpdate() end
    elseif event == "PLAYER_FLAGS_CHANGED" then
        if arg1 == "player" then ns.Scan.OnAfk() end
    elseif event == "UI_ERROR_MESSAGE" or event == "CHAT_MSG_SYSTEM" then
        ns.Scan.OnMessage(event, arg1)
        if event == "UI_ERROR_MESSAGE" and ns.Buy then ns.Buy.OnError(arg1) end
    end
end)
events:SetScript("OnUpdate", function(_, elapsed)
    ns.Scan.OnUpdate(elapsed)
    if ns.Buy then ns.Buy.OnUpdate() end
end)
SLASH_MCAUCSCAN1 = "/aucscan"
SlashCmdList.MCAUCSCAN = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)")
    if cmd == "all" then
        ns.Scan.Start("all")
    elseif cmd == "stop" then
        if not ns.Scan.Stop() then ns.say(ns.T("sayNotRunning")) end
    elseif cmd == "status" then
        local db = ns.Store.DB()
        local last = db.scans[#db.scans]
        ns.say(ns.T("sayStatus", #db.scans, last and last.total or 0, ns.Store.Usage() / 1024 / 1024))
    elseif cmd == "pace" then
        if (msg or ""):lower():match("^%s*pace%s+reset%s*$") then ns.Scan.ResetPace()
        else ns.say(ns.T("sayPace", ns.Query.Gap())) end
    elseif cmd == "ledger" then
        if ns.AccountingUI then ns.AccountingUI.Open() else ns.say(ns.T("tradeRestartRequired")) end
    else
        ns.Scan.Start("pages")
    end
end
