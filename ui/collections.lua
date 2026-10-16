local _, ns = ...
local UI = {props = {mode = "favorites", fee = 0.05}, rows = {}}
ns.CollectionsUI = UI
function UI:SetProps(props)
    ns.Batch.Stop()
    for key, value in pairs(props) do self.props[key] = value end
    self.selected = nil; self.scroll.offset = 0; self:Render()
end
function UI:Render()
    if not self.frame then return end
    local K, C, p = ns.TradeKit, ns.Collections, self.props
    local events = ns.seasonalEvents or {}
    if not p.event then p.event = events[1] and events[1].key end
    local entries = C.Items(p.mode, p.event)
    self.mode.frame:SetText(ns.T(p.mode == "favorites" and "collectionFavorites" or
        (p.mode == "seasonal" and "collectionSeasonal" or "collectionTracked")))
    local event
    for _, candidate in ipairs(events) do if candidate.key == p.event then event = candidate end end
    if p.mode == "seasonal" then
        self.eventMenu.frame:Show(); self.input:Hide(); self.add:Hide()
        self.eventMenu.frame:SetText(event and ns.T(event.labelKey) or "")
        self.hint:SetText(event and ns.T(event.timingKey) or "")
    elseif p.mode == "tracked" then
        self.eventMenu.frame:Hide(); self.input:Show(); self.add:Show(); self.hint:SetText("")
    else
        self.eventMenu.frame:Hide(); self.input:Hide(); self.add:Hide(); self.hint:SetText(ns.T("collectionFavoriteHint"))
    end
    local width = (self.frame:GetWidth() or 996) - 310
    local columns = K.MarketColumns(width)
    for key, label in pairs(self.headers) do
        label:ClearAllPoints(); label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + columns[key][1], -74)
        label:SetWidth(columns[key][2])
    end
    local offset = self.scroll:SetRange(#entries, K.ListCapacity(self.frame, 94, 56, 29, #self.rows))
    local selected
    for _, entry in ipairs(entries) do if entry.raw == self.selected then selected = entry end end
    if not selected then selected = entries[1]; self.selected = selected and selected.raw end
    for i, row in ipairs(self.rows) do
        local entry = entries[offset + i]
        if i > self.scroll.visible then entry = nil end
        if entry then
            local q, margin = ns.Markets.Quote(entry.raw)
            local recipe, family = ns.Crafting.byItem[entry.raw], ns.gemByItem[entry.raw]
            local detail = entry.noteKey and ns.T(entry.noteKey) or ""
            if recipe then
                margin = ns.CraftPlan.Build(recipe, {fee = p.fee}).margin
                detail = ns.T(ns.craftCatalogs[recipe.profession].labelKey)
            elseif family and family.raw ~= entry.raw then
                local raw = ns.Markets.Quote(family.raw)
                if q and q.price and raw and raw.price and q.miss == 0 and raw.miss == 0 then margin = q.price * (1 - p.fee) - raw.price end
                detail = ns.T("jewelrySection")
            end
            if q and not q.vendor then detail = detail .. ns.T("cacheAge", math.max(0, math.floor((time() - q.at) / 60))) end
            row:SetProps({id = entry.raw, quote = q, margin = margin, width = width,
                active = entry.raw == self.selected, detail = detail, extraTip = entry.noteKey and ns.T(entry.noteKey)})
        else row.frame:Hide() end
    end
    self.empty:SetText(#entries == 0 and ns.T(p.mode == "seasonal" and "seasonNoAuctionItems" or "collectionEmpty") or "")
    if selected then
        self.inspector:SetProps({id = selected.raw}); self.inspector.item:Show(); self.inspector.offers:Show()
        self.inspector.actions.frame:Show()
        local q = ns.Markets.Quote(selected.raw)
        self.summary:SetText(ns.T("familyCurrentPrice", K.Money(q and q.price)) .. "\n\n"
            .. (q and not q.vendor and ns.T("cacheObserved", date("%d.%m %H:%M", q.at)) or "")
            .. "\n\n" .. (selected.noteKey and ns.T(selected.noteKey) or ns.T("collectionHistoryHint")))
        if C.CanFavorite(selected.raw) then self.open:Show() else self.open:Hide() end
        self.history:Enable(); self.buy:Enable()
    else
        self.inspector.item:Hide(); self.inspector.offers:Hide(); self.inspector.actions.frame:Hide()
        self.summary:SetText(ns.T("collectionActionsTip")); self.open:Hide(); self.history:Disable(); self.buy:Disable()
    end
    if ns.Scan.state.phase == "idle" and not ns.Buy.Active() then self.scan:Enable() else self.scan:Disable() end
    if ns.Scan.state.phase == "paused" then self.resume:Show() else self.resume:Hide() end
    if ns.Scan.state.phase ~= "idle" then self.stop:Show() else self.stop:Hide() end
end
function UI:New(parent)
    local K = ns.TradeKit
    local f = ns.NewFrame("Frame", nil, parent); f:SetAllPoints(parent); self.frame = f
    self.mode = K.Menu(f, {{key = "favorites", labelKey = "collectionFavorites"},
        {key = "tracked", labelKey = "collectionTracked"}, {key = "seasonal", labelKey = "collectionSeasonal"}},
        function(mode) self:SetProps({mode = mode}) end)
    self.mode.frame:SetWidth(120); self.mode.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -3)
    local eventEntries = {}
    for _, event in ipairs(ns.seasonalEvents or {}) do eventEntries[#eventEntries + 1] = {key = event.key, labelKey = event.labelKey} end
    self.eventMenu = K.Menu(f, eventEntries, function(key) self:SetProps({event = key}) end)
    self.eventMenu.frame:SetWidth(190); self.eventMenu.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 134, -3)
    self.input = K.Edit(f, 220); self.input:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -36)
    K.Tooltip(self.input, ns.T("collectionTracked"), ns.T("collectionInputTip"))
    local function add()
        if not ns.Collections.Add(self.input:GetText()) then ns.say(ns.T("collectionInvalid")); return end
        self.input:SetText(""); self.input:ClearFocus(); self:Render()
    end
    self.input:SetScript("OnEnterPressed", add)
    self.add = K.Button(f, ns.T("collectionAdd"), 84, add)
    self.add:SetPoint("LEFT", self.input, "RIGHT", 6, 0)
    self.hint = K.Label(f, "", 10, -38, 460); self.hint:SetHeight(32); self.hint:SetJustifyV("TOP")
    self.scan = K.Button(f, ns.T("collectionScan"), 140, function()
        ns.Collections.Scan(self.props.mode, self.props.event); self:Render()
    end, "main")
    self.scan:SetPoint("TOPRIGHT", f, "TOPRIGHT", -282, -5)
    K.Tooltip(self.scan, ns.T("collectionScan"), ns.T("collectionScanTip"))
    K.TableHeader(f, -74)
    self.headers = {}
    for _, entry in ipairs({{"item", "tradeItem"}, {"price", "tradeUnitPrice"},
        {"margin", "familyMargin"}, {"units", "tradeUnits"}}) do
        self.headers[entry[1]] = K.Label(f, ns.T(entry[2]), 0, -74, 100)
        if entry[1] ~= "item" then self.headers[entry[1]]:SetJustifyH("RIGHT") end
    end
    self.scroll = K.TableScroll(f, function() self:Render() end, 94, 56, 29)
    for i = 1, 40 do
        local row = K.MarketRow:New(f, function(id) self.selected = id; self:Render() end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -94 - (i - 1) * 29)
        row.frame:SetHeight(28); self.rows[i] = row; self.scroll:Wheel(row.frame)
    end
    self.empty = K.Label(f, "", 10, -104, 440); self.empty:SetHeight(64)
    self.status = K.Label(f, "", 0, 0, 440)
    self.status:ClearAllPoints(); self.status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 32)
    self.buy = K.Button(f, ns.T("tradeBuy"), 84, function() if self.selected then ns.Trader.OpenBuy(self.selected) end end)
    self.buy:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    self.stop = K.Button(f, ns.T("tradeStop"), 60, function() ns.Batch.Stop(); ns.Scan.Stop(); self:Render() end)
    self.stop:SetPoint("RIGHT", self.buy, "LEFT", -6, 0)
    self.resume = K.Button(f, ns.T("tradeResume"), 92, function() ns.Scan.Start("pages"); self:Render() end)
    self.resume:SetPoint("RIGHT", self.stop, "LEFT", -6, 0)
    self.inspector = K.Inspector:New(f, function() if self.selected then ns.ItemHistoryUI.Open(self.selected) end end)
    local panel = self.inspector.frame
    self.summary = K.Label(panel, "", 12, -48, 240); self.summary:SetHeight(200); self.summary:SetJustifyV("TOP")
    self.history = K.Button(panel, ns.T("itemHistory"), 114, function() if self.selected then ns.ItemHistoryUI.Open(self.selected) end end)
    self.history:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 40)
    self.open = K.Button(panel, ns.T("collectionOpenRecipe"), 150, function() if self.selected then ns.Collections.OpenRecipe(self.selected) end end)
    self.open:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 8)
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render(); return self
end
