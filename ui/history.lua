local _, ns = ...
local H = {days = 7}
ns.ItemHistoryUI = H
function H:Render()
    if not self.frame or not self.id then return end
    local K = ns.TradeKit
    K.SetItemChoice(self.item, self.id, true)
    self.priceChart:SetProps(ns.Activity.History(self.id, self.days))
    self.volumeChart:SetProps(ns.Activity.History(self.id, self.days, true))
    local activity = ns.Activity.Recent(self.id)
    self.activity:SetText(activity and ns.T("marketActivity", date("%d.%m %H:%M", activity.from),
        date("%d.%m %H:%M", activity.at), activity.oldUnits, activity.units,
        activity.added, activity.addedUnits, activity.gone, activity.goneUnits,
        activity.beforeExpiry, activity.expiryPossible) or ns.T("marketActivityMissing"))
    for days, button in pairs(self.periods) do button:SetActive(days == self.days) end
end
function H.Open(id)
    H.id = id; H.frame:Show(); H:Render()
end
function H.New(parent)
    local K = ns.TradeKit
    local f = ns.NewFrame("Frame", nil, parent)
    H.frame = f; f:SetWidth(280); f:SetHeight(570)
    f:SetPoint("TOPLEFT", parent, "TOPRIGHT", 8, 0)
    f:SetFrameLevel(parent:GetFrameLevel() + 35); f:SetClampedToScreen(true)
    f:EnableMouse(true); K.Panel(f)
    H.item = K.ItemChoice(f, function() end)
    H.item:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -10); H.item:SetWidth(250); H.item.text:SetWidth(218)
    H.periods = {}
    for i, days in ipairs({1, 7, 30}) do
        local button = K.Button(f, ns.T("familyDays", days), 76, function() H.days = days; H:Render() end)
        button:SetPoint("TOPLEFT", f, "TOPLEFT", 12 + (i - 1) * 82, -42)
        H.periods[days] = button
    end
    K.Label(f, ns.T("historyPrice"), 12, -72, 240, "heading")
    H.priceChart = K.PriceChart:New(f); H.priceChart.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -90)
    K.Label(f, ns.T("historyVolume"), 12, -228, 240, "heading")
    H.volumeChart = K.PriceChart:New(f); H.volumeChart.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -248)
    H.activity = K.Label(f, "", 12, -388, 250); H.activity:SetHeight(120); H.activity:SetJustifyV("TOP")
    local update = K.Button(f, ns.T("tradeUpdate"), 100, function() ns.Markets.Scan(H.id) end)
    update:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 14)
    local close = K.Button(f, ns.T("historyClose"), 100, function() f:Hide() end)
    close:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 14)
    K.Tooltip(f, ns.T("itemHistory"), ns.T("marketActivityTip"))
    f:Hide()
end
local P = {rows = {}, sellers = {}}
ns.OfferPreview = P
function P.Open(id)
    if P.id ~= id then
        P.level, P.scanID, P.followLatest = nil, nil, true
        P.scroll.offset = 0; P.sellerScroll.offset = 0
    end
    P.id = id; P.frame:Show(); P:Render()
end
function P:Render()
    if not self.id then return end
    local K, selected = ns.TradeKit
    self.sources = ns.Markets.Sources(self.id)
    if self.followLatest or not self.scanID then self.scanID = self.sources[1] and self.sources[1].id end
    for i, button in ipairs(self.scanMenu.buttons) do
        local source = self.sources[i]
        if source then button.text:SetText(ns.T("offersSource", date("%d.%m %H:%M", source.at))); button:Show()
        else button:Hide() end
    end
    local depth = ns.Markets.Depth(self.id, self.scanID)
    self.depth = depth
    self.scanMenu.frame:SetText(ns.T("offersSource", depth.quote and depth.quote.at and date("%d.%m %H:%M", depth.quote.at) or ""))
    K.SetItemChoice(self.item, self.id, false)
    for _, level in ipairs(depth.levels) do if level.price == self.level then selected = level end end
    if not selected then selected = depth.levels[1]; self.level = selected and selected.price end
    local offset = self.scroll:SetRange(#depth.levels, #self.rows)
    for i, row in ipairs(self.rows) do
        local level = depth.levels[offset + i]
        if level then
            row.level = level.price
            row.text:SetText(K.Money(level.price)); row.units:SetText(tostring(level.units))
            row.lots:SetText(tostring(level.lots)); row.total:SetText(tostring(level.cumulative))
            if level.price == self.level then row.selected:Show() else row.selected:Hide() end
            row:Show()
        else row:Hide() end
    end
    local sellers = selected and selected.sellers or {}
    local sellerOffset = self.sellerScroll:SetRange(#sellers, #self.sellers)
    for i, row in ipairs(self.sellers) do
        local seller = sellers[sellerOffset + i]
        if seller then
            row.text:SetText(seller.owner ~= "" and seller.owner or ns.T("cacheUnknownSeller"))
            row.amount:SetText(ns.T("offersStack", seller.stack, seller.lots)); row:Show()
        else row:Hide() end
    end
    self.sellerTitle:SetText(selected and ns.T("offersSellersAt", K.Money(selected.price), selected.sellerCount)
        or ns.T("offersSellers"))
    local q, low = depth.quote, depth.levels[1]
    self.summary:SetText(low and ns.T("offersSummary", low.units, low.lots, q and q.units or depth.units,
        q and date("%d.%m %H:%M", q.at) or "") or ns.T("offersEmpty"))
    self.notice:SetText(ns.T(depth.partial and "offersPartial" or "offersSnapshot", depth.lots, q and q.lots or depth.lots))
    if ns.Scan.state.phase == "idle" and not ns.Buy.Active() then self.refresh:Enable() else self.refresh:Disable() end
end
function P.New(parent)
    local K = ns.TradeKit
    local f = ns.NewFrame("Frame", nil, parent)
    P.frame = f; f:SetWidth(630); f:SetHeight(420)
    f:SetPoint("CENTER", parent, "CENTER", 0, 0)
    f:SetFrameLevel(parent:GetFrameLevel() + 45); f:SetClampedToScreen(true); f:EnableMouse(true); K.Panel(f)
    P.item = K.ItemChoice(f, function() ns.ItemHistoryUI.Open(P.id) end)
    P.item:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -8); P.item:SetWidth(470); P.item.text:SetWidth(438)
    local close = K.Button(f, ns.T("historyClose"), 84, function() f:Hide() end, "quiet")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -10)
    P.summary = K.Label(f, "", 12, -44, 410); P.summary:SetHeight(34); P.summary:SetJustifyV("TOP")
    local sourceEntries = {}
    for i = 1, 5 do sourceEntries[i] = {key = i, labelKey = "offersSourceLabel"} end
    P.scanMenu = K.Menu(f, sourceEntries, function(index)
        if not P.sources[index] then return end
        P.scanID, P.followLatest = P.sources[index].id, false
        P.level = nil; P.scroll.offset = 0; P.sellerScroll.offset = 0; P:Render()
    end)
    P.scanMenu.frame:SetWidth(178); P.scanMenu.frame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -44)
    K.Rule(f, -82)
    for _, entry in ipairs({{"tradeUnitPrice", 12, 110}, {"tradeUnits", 130, 50},
        {"offersLots", 184, 50}, {"offersCumulative", 238, 72}}) do
        K.Label(f, ns.T(entry[1]), entry[2], -92, entry[3])
    end
    P.sellerTitle = K.Label(f, "", 338, -90, 278); P.sellerTitle:SetHeight(28)
    P.scroll = K.Scroller:New(f, function() P:Render() end, 24)
    P.scroll.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -120)
    P.scroll.frame:SetPoint("BOTTOMRIGHT", f, "TOPLEFT", 328, -360)
    P.sellerScroll = K.Scroller:New(f, function() P:Render() end, 24)
    P.sellerScroll.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 338, -120)
    P.sellerScroll.frame:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -10, -360)
    for i = 1, 10 do
        local row = K.Navigation(f, "", function(button)
            P.level = button.level; P.sellerScroll.offset = 0; P:Render()
        end)
        row:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -120 - (i - 1) * 24)
        row:SetWidth(298); row:SetHeight(24); row.text:SetWidth(112)
        row.units = K.Label(row, "", 118, -7, 48)
        row.lots = K.Label(row, "", 172, -7, 48)
        row.total = K.Label(row, "", 226, -7, 68)
        P.rows[i] = row; P.scroll:Wheel(row)
        local seller = K.Navigation(f, "", function() end)
        seller:SetPoint("TOPLEFT", f, "TOPLEFT", 338, -120 - (i - 1) * 24)
        seller:SetWidth(260); seller:SetHeight(24); seller.text:SetWidth(154)
        seller.amount = K.Label(seller, "", 166, -7, 90)
        P.sellers[i] = seller; P.sellerScroll:Wheel(seller)
    end
    P.notice = K.Label(f, "", 12, -370, 606); P.notice:SetHeight(18)
    P.refresh = K.Button(f, ns.T("tradeUpdate"), 100, function()
        P.followLatest = true; ns.Markets.Scan(P.id); P:Render()
    end)
    P.refresh:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 8)
    local buy = K.Button(f, ns.T("offersBuy"), 116, function() f:Hide(); ns.Trader.OpenBuy(P.id) end, "main")
    buy:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 8)
    f:Hide()
end
