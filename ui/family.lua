local _, ns = ...
local UI = {props = {family = 36919, id = 36919, page = 1, days = 7, fee = 0.05}, rows = {}}
ns.FamilyUI = UI
function UI:SetProps(props)
    if props.family and props.family ~= self.props.family then
        if ns.Batch then ns.Batch.Stop() end
        self.props.id = props.family
        if self.scroll then self.scroll.offset = 0 end
    end
    for key, value in pairs(props) do self.props[key] = value end
    self:Render()
end
function UI:Render()
    if not self.frame then return end
    local K, p = ns.TradeKit, self.props
    local width = (self.frame:GetWidth() or 996) - 310
    local columns = K.MarketColumns(width)
    for key, label in pairs(self.headers) do
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + columns[key][1], -38)
        label:SetWidth(columns[key][2])
    end
    self.tableWidth = width
    local family = ns.gemByRaw[p.family]
    local members = ns.Collections.OrderIDs(family.members)
    self.picker:SetProps({families = ns.gemFamilies, raw = family.raw})
    local visible = ns.TradeKit.ListCapacity(self.frame, 56, 56, 24, #self.rows)
    local offset = self.scroll:SetRange(#family.members - 1, math.max(1, visible - 1))
    self.status:SetWidth(width - 170)
    local raw = ns.Markets.Quote(family.raw)
    for i, row in ipairs(self.rows) do
        local id = i <= visible and members[i == 1 and 1 or offset + i]
        if id then
            local q, margin = ns.Markets.Quote(id)
            if id ~= family.raw and raw and raw.price and q and q.price and raw.miss == 0 and q.miss == 0 then
                margin = q.price * (1 - p.fee) - raw.price
            end
            local age = q and ns.T("tradeAge", math.max(0, math.floor((time() - q.at) / 60))) or ns.T("familyNotSeen")
            if q and q.miss > 0 then age = ns.T("tradeIncomplete") end
            row:SetProps({id = id, quote = q, margin = margin, active = id == p.id,
                width = width, detail = age})
        else row.frame:Hide() end
    end
    self.fee:SetText(ns.T("tradeFee", math.floor(p.fee * 100 + 0.5)))
    self.inspector:SetProps({id = p.id})
    local h = ns.Family.History(p.id, p.days)
    self.chart:SetProps(h)
    self.stats:SetText(ns.T("familyStats", h.count, K.Money(h.median),
        h.volatility and string.format("%.1f%%", h.volatility) or ns.T("familyNotEnough")))
    local q = ns.Markets.Quote(p.id)
    local scenario = h.count >= 2 and h.median and q and q.price and q.miss == 0
        and (h.median * (1 - p.fee) - q.price) or nil
    self.scenario:SetText(scenario and ns.T("familyScenario", K.Money(scenario)) or "")
    self.current:SetText(ns.T("familyCurrentPrice", K.Money(q and q.price)))
    local activity = ns.Activity.Recent(p.id)
    self.activity:SetText(activity and ns.T("marketActivity", date("%d.%m %H:%M", activity.from),
        date("%d.%m %H:%M", activity.at), activity.oldUnits, activity.units,
        activity.added, activity.addedUnits, activity.gone, activity.goneUnits,
        activity.beforeExpiry, activity.expiryPossible) or ns.T("marketActivityMissing"))
    if (self.history:GetHeight() or 510) >= 452 then self.activity:Show() else self.activity:Hide() end
    self.recipe:SetText(ns.Family.Recipe(p.id))
    self:Controls()
    for days, button in pairs(self.periods) do
        button:SetActive(days == p.days)
    end
end
function UI:Controls()
    if not self.stop then return end
    local phase = ns.Scan.state.phase
    if phase == "idle" then self.stop:Hide() else self.stop:Show() end
    if phase == "idle" then self.update:Show() else self.update:Hide() end
    if phase == "paused" then self.resume:Show() else self.resume:Hide() end
    if phase == "idle" and not ns.Buy.Active() then self.scan:Enable() else self.scan:Disable() end
end
function UI:New(parent)
    local K = ns.TradeKit
    self.frame = ns.NewFrame("Frame", nil, parent)
    local f = self.frame
    f:SetAllPoints(parent)
    self.mode = K.ProfessionModes(f, function() return "jewelry" end, "craft")
    self.picker = K.FamilyPicker:New(f, function(raw) self:SetProps({family = raw}) end)
    self.familyChoice = self.picker.frame
    self.familyChoice:SetPoint("TOPLEFT", f, "TOPLEFT", 114, -3)
    self.familyChoice:SetWidth(244)
    self.familyChoice.text:SetWidth(212)
    self.scan = K.Button(f, ns.T("scanSelection"), 140, function()
        ns.Family.Complete(self.props.family, IsShiftKeyDown()); self:Render()
    end, "main")
    self.scan:SetPoint("TOPRIGHT", f, "TOPRIGHT", -282, -5)
    K.Tooltip(self.scan, ns.T("familyScan"), ns.T("familyScanTip"))
    K.TableHeader(f, -38)
    self.headers = {}
    for _, entry in ipairs({{"item", "tradeItem"}, {"price", "tradeUnitPrice"},
        {"margin", "familyMargin"}, {"units", "tradeUnits"}}) do
        local label = K.Label(f, ns.T(entry[2]), 0, -38, 100)
        if entry[1] ~= "item" then label:SetJustifyH("RIGHT") end
        self.headers[entry[1]] = label
    end
    self.scroll = K.TableScroll(f, function() self:Render() end, 80, 56, 24)
    for i = 1, 40 do
        local row = K.MarketRow:New(f, function(id) self:SetProps({id = id}) end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -56 - (i - 1) * 24)
        row.frame:SetHeight(24)
        self.rows[i] = row
        self.scroll:Wheel(row.frame)
    end
    self.fee = K.Button(f, "", 106, function() self:SetProps({fee = self.props.fee == 0.05 and 0.15 or 0.05}) end)
    self.fee:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 4)
    K.Tooltip(self.fee, ns.T("tradeFeeTitle"), ns.T("tradeFeeTip"))
    self.status = K.Label(f, ns.T("tradeReadyShort"), 0, 0, 440)
    self.status:ClearAllPoints()
    self.status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 32)
    self.status:SetHeight(14)
    self.buy = K.Button(f, ns.T("tradeBuy"), 84, function() ns.Trader.OpenBuy(self.props.id) end)
    self.buy:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    self.update = K.Button(f, ns.T("tradeUpdate"), 84, function() ns.Markets.Scan(self.props.id) end)
    self.update:SetPoint("RIGHT", self.buy, "LEFT", -6, 0)
    K.Tooltip(self.update, ns.T("cacheRefreshItem"), ns.T("cacheRefreshTip"))
    self.stop = K.Button(f, ns.T("tradeStop"), 60, function() ns.Scan.Stop(); self:Controls() end)
    self.stop:SetPoint("RIGHT", self.buy, "LEFT", -6, 0)
    self.resume = K.Button(f, ns.T("tradeResume"), 92, function()
        if ns.Scan.state.phase == "paused" then ns.Scan.Start("pages") end
        self:Controls()
    end)
    self.resume:SetPoint("RIGHT", self.stop, "LEFT", -6, 0)
    self.inspector = K.Inspector:New(f, function() ns.ItemHistoryUI.Open(self.props.id) end)
    local h = self.inspector.frame
    self.historyItem = self.inspector.item
    self.history = h
    self.periods = {}
    for i, days in ipairs({1, 7, 30}) do
        local b = K.Button(h, ns.T("familyDays", days), 76, function() self:SetProps({days = days}) end)
        b:SetPoint("TOPLEFT", h, "TOPLEFT", 12 + (i - 1) * 82, -42)
        self.periods[days] = b
    end
    self.current = K.Label(h, "", 12, -74, 240)
    self.chart = K.PriceChart:New(h)
    self.chart.frame:SetPoint("TOPLEFT", h, "TOPLEFT", 12, -97)
    self.stats = K.Label(h, "", 12, -238, 240)
    self.stats:SetHeight(44)
    self.stats:SetJustifyV("TOP")
    self.activity = K.Label(h, "", 12, -290, 240)
    self.activity:SetHeight(112); self.activity:SetJustifyV("TOP")
    self.recipe = K.Label(h, "", 40, -28, 212)
    self.recipe:SetHeight(10)
    self.recipe:SetTextColor(unpack(K.theme.secondary))
    self.scenario = K.Label(h, "", 0, 0, 240)
    self.scenario:ClearAllPoints()
    self.scenario:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 12, 10)
    self.scenario:SetHeight(32)
    self.scenario:SetJustifyV("BOTTOM")
    K.Tooltip(h, ns.T("familyHistory"), ns.T("familyHistoryTip") .. "\n\n" .. ns.T("marketActivityTip"))
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render()
    return self
end
