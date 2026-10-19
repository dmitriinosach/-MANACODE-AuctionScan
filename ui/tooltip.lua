local _, ns = ...
local T = {}
ns.AuctionTooltip = T
function T.AuctionatorShows()
    return type(gAtr_ScanDB) == "table" and AUCTIONATOR_A_TIPS ~= 0
end
function T.Add(tip)
    if rawget(tip, "manacodePrice") or T.AuctionatorShows() then return end
    local _, link = tip:GetItem()
    local id = link and ns.Lot.FromLink(link)
    local q = id and ns.Markets.Quote(id)
    if not q or q.vendor or not q.price or q.complete == false or (q.units or 0) == 0 then return end
    tip.manacodePrice = true
    local K = ns.TradeKit
    tip:AddDoubleLine(ns.T("tipAuction"), ns.T("tipAuctionUnit", K.Money(q.price)), 1, 0.82, 0, 1, 1, 1)
    if q.at then
        tip:AddDoubleLine(" ", ns.T("tipAuctionAge", K.Ago(math.max(0, time() - q.at))), 1, 1, 1, 0.6, 0.6, 0.6)
    end
    tip:Show()
end
function T.Install(tip)
    if not tip or rawget(tip, "manacodeHooked") then return end
    tip.manacodeHooked = true
    tip:HookScript("OnTooltipSetItem", T.Add)
    tip:HookScript("OnTooltipCleared", function(self) self.manacodePrice = nil end)
end
T.Install(GameTooltip)
T.Install(ItemRefTooltip)
