local _, ns = ...
local UI = {props = {kind = "buyout", fee = 0.05, percent = {buyout = 30, bid = 40}}, pool = {}, list = {}}
ns.BargainUI = UI
local function saved()
    local db = ns.Store.DB()
    if type(db.bargainUI) ~= "table" then db.bargainUI = {} end
    return db.bargainUI
end
function UI:Save()
    local s, p = saved(), self.props
    s.kind, s.fee, s.percent = p.kind, p.fee, {buyout = p.percent.buyout, bid = p.percent.bid}
end
function UI:Restore()
    local s, p = saved(), self.props
    if s.kind == "buyout" or s.kind == "bid" then p.kind = s.kind end
    if s.fee == 0.05 or s.fee == 0.15 then p.fee = s.fee end
    if type(s.percent) == "table" then
        for _, kind in ipairs({"buyout", "bid"}) do
            local value = tonumber(s.percent[kind])
            if value and value >= 1 and value <= 95 then p.percent[kind] = math.floor(value) end
        end
    end
end
function UI:SetProps(props)
    local p = self.props
    if props.kind and props.kind ~= p.kind then
        if ns.Bargain.Active() then ns.Bargain.Cancel() end
        p.kind = props.kind
    end
    if props.fee then p.fee = props.fee end
    if type(props.percent) == "number" then p.percent[p.kind] = props.percent end
    if props.key ~= nil then p.key = props.key end
    if self.frame then self:Save() end
    self:Render()
end
local function age(seconds)
    if seconds < 60 then return ns.T("bargainAgeNow") end
    if seconds < 3600 then return ns.T("bargainAgeMinutes", math.floor(seconds / 60)) end
    if seconds < 86400 then return ns.T("bargainAgeHours", math.floor(seconds / 3600)) end
    return ns.T("bargainAgeDays", math.floor(seconds / 86400))
end
local function left(seconds)
    if seconds < 7200 then return ns.T("bargainAgeMinutes", math.max(1, math.ceil(seconds / 60))) end
    return ns.T("bargainAgeHours", math.ceil(seconds / 3600))
end
function UI:Controls()
    if not self.frame then return end
    local B, K = ns.Bargain, ns.TradeKit
    local phase = ns.Scan.state.phase
    if phase == "idle" and not ns.Buy.Active() then self.scan:Enable() else self.scan:Disable() end
    local row = self.selected
    if B.Active() then
        local count, cost = ns.Buy.Offer()
        if ns.Buy.state.phase == "ready" and count > 0 then
            self.act:SetText(ns.T(self.props.kind == "bid" and "bargainConfirmBid" or "bargainConfirmBuyout", K.Money(cost)))
            self.act:Enable()
        else
            self.act:SetText(ns.T("bargainSearching")); self.act:Disable()
        end
    elseif row then
        self.act:SetText(ns.T(row.kind == "bid" and "bargainDoBid" or "bargainDoBuyout", K.Money(row.cost)))
        if phase == "idle" and ns.Scan.state.open then self.act:Enable() else self.act:Disable() end
    else
        self.act:SetText(ns.T("bargainPick")); self.act:Disable()
    end
    local busy = phase == "idle" and not ns.Buy.Active()
    if busy then self.modes:Enable(); self.fees:Enable() else self.modes:Disable(); self.fees:Disable() end
    self.edit:EnableMouse(busy)
end
function UI:Find(key)
    for _, row in ipairs(self.list) do
        if row.key == key then return row end
    end
    return nil
end
function UI:Cells(row, scanAge)
    local K = ns.TradeKit
    local cells = {count = {tostring(row.count)}, price = {K.Money(row.unit)}, market = {K.Money(row.ref), "secondary"}}
    if row.kind == "bid" then
        cells.gain = {K.Money(row.profit), "positive"}
        cells.left = {ns.T("bargainLeft", left(row.leftMax or 0)), "secondary"}
        cells.buyout = {ns.T(row.hasBuyout and "bargainYes" or "bargainNo"), "secondary"}
    else
        cells.discount = {ns.T("bargainDiscount", math.floor(row.discount + 0.5)), "positive"}
        cells.revenue = {K.Money(row.revenue)}
        cells.age = {age(scanAge), "secondary"}
    end
    return cells
end
function UI:Panel(row)
    local K, r = ns.TradeKit, row.resale
    local bid = row.kind == "bid"
    local labels = {
        ns.T("bargainStepMarket"), ns.T("bargainStepGross", row.count),
        ns.T("bargainStepFee", math.floor(self.props.fee * 100 + 0.5)),
        ns.T(r.depositKnown and "bargainStepDeposit" or "bargainStepDepositMin"),
        ns.T("bargainStepRevenue"), ns.T(bid and "bargainStepBid" or "bargainStepBuyout"),
        ns.T("bargainStepProfit"),
    }
    local values = {K.Money(row.ref), K.Money(r.gross), "-" .. K.Money(r.commission), "-" .. K.Money(r.deposit),
        K.Money(r.revenue), "-" .. K.Money(row.cost), K.Money(row.profit)}
    for i, label in ipairs(self.stepLabels) do label:SetText(labels[i]) end
    for i, value in ipairs(self.stepValues) do
        value:SetText(values[i])
        local tone = (i == 3 or i == 4 or i == 6) and "secondary" or "text"
        if i == 7 then tone = row.profit > 0 and "positive" or "negative" end
        value:SetTextColor(unpack(K.theme[tone]))
    end
    self.discount:SetText(ns.T("bargainDiscount", math.floor(row.discount + 0.5)))
    local levels, summary = ns.Bargain.Depth(row, #self.depthLines)
    self.depthSummary:SetText(ns.T("bargainDepthSummary", summary.units, summary.lots, summary.sellers))
    for i, line in ipairs(self.depthLines) do
        local level = levels[i]
        if level then
            line.price:SetText(K.Money(level.price))
            line.units:SetText(ns.T("bargainDepthRow", level.units, level.cumulative))
            line.price:Show(); line.units:Show()
        else line.price:Hide(); line.units:Hide() end
    end
    self.history:SetText(ns.T(row.history and "bargainHistoryYes" or "bargainHistoryNo"))
end
function UI:Render()
    if not self.frame then return end
    local K, B, p = ns.TradeKit, ns.Bargain, self.props
    local width = (self.frame:GetWidth() or 996) - 310
    local columns = K.BargainColumns(width, p.kind)
    for key, label in pairs(self.headers) do
        local column = columns[key]
        label:ClearAllPoints()
        if column then
            label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + column[1] + (key == "item" and 6 or 0), -40)
            label:SetWidth(column[2] - 6); label:Show()
        else label:Hide() end
    end
    self.headers.price:SetText(ns.T(p.kind == "bid" and "bargainColBid" or "bargainColBuyout"))
    self.cover.price.tipTitle = self.headers.price:GetText()
    self.cover.price.tip = ns.T(p.kind == "bid" and "bargainTipBid" or "bargainTipBuyout")
    local rows, info = B.Rows(p.kind, {percent = p.percent[p.kind], fee = p.fee})
    self.list = rows
    local visible = K.ListCapacity(self.frame, 62, 66, 24, #self.pool)
    local offset = self.scroll:SetRange(#rows, visible)
    local selected = self:Find(p.key) or rows[1]
    self.selected = selected
    local scanAge = info.age or 0
    for i, view in ipairs(self.pool) do
        local row = i <= visible and rows[offset + i]
        if row then
            local copies = row.copies > 1 and ("\n" .. ns.T("bargainRowCopies", row.copies)) or ""
            view.frame:ClearAllPoints(); view.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -62 - (i - 1) * 24)
            view:SetProps({key = row.key, id = row.item, width = width, mode = p.kind, cells = self:Cells(row, scanAge),
                active = selected == row, tip = ns.T("bargainRowTip") .. copies,
                actions = {{label = ns.T(row.kind == "bid" and "bargainActBid" or "bargainActBuyout"),
                    tip = ns.T(row.kind == "bid" and "bargainActBidTip" or "bargainActBuyoutTip"),
                    disabled = not (ns.Scan.state.open and ns.Scan.state.phase == "idle"),
                    fn = function(key) self:Act(key) end}}})
        else view.frame:Hide() end
    end
    if selected then
        self.inspector:SetProps({id = selected.item})
        self:Panel(selected)
        self.steps:Show()
    else
        self.inspector:Clear()
        self.steps:Hide()
    end
    self.modes:Select(p.kind)
    self.fees:Select(p.fee)
    self.edit:SetText(tostring(p.percent[p.kind]))
    local text
    if not info.scan then text = ns.T("bargainNoScan")
    elseif #rows == 0 then text = ns.T("bargainEmpty", p.percent[p.kind])
    else text = ns.T("bargainStatus", age(scanAge), #info.scan.lots, info.groups, info.total) end
    self.status:SetText(text)
    local note = p.kind == "bid" and ns.T("bargainBidNote", info.hidden or 0) or ns.T("bargainBuyoutNote")
    if info.scan and scanAge > 3600 then note = ns.T("bargainStale") .. " " .. note end
    self.note:SetText(note)
    self.status:SetWidth(width - 20); self.note:SetWidth(width - 20)
    self:Controls()
end
function UI:Act(key)
    local row = self:Find(key)
    if not row then return end
    self.props.key = key
    ns.Bargain.Act(row)
    self:Render()
end
function UI:ApplyPercent(value)
    local number = tonumber(value)
    if number and number >= 1 and number <= 95 and number == math.floor(number) then
        self.props.percent[self.props.kind] = number
        self:Save()
    else
        ns.say(ns.T("bargainInvalidPercent"))
    end
    self:Render()
end
function UI:New(parent)
    local K = ns.TradeKit
    self:Restore()
    self.frame = ns.NewFrame("Frame", nil, parent)
    local f = self.frame
    f:SetAllPoints(parent)
    self.title = K.Label(f, ns.T("bargainTitle"), 10, -9, 120, "heading")
    self.title:SetHeight(14)
    self.modes = K.Segment(f, {{key = "buyout", label = ns.T("bargainModeBuyout")}, {key = "bid", label = ns.T("bargainModeBid")}},
        function(kind) self:SetProps({kind = kind}) end)
    self.modes.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 120, -5)
    K.Tooltip(self.modes.frame, ns.T("bargainTitle"), ns.T("bargainModeBuyoutTip") .. "\n\n" .. ns.T("bargainModeBidTip"))
    local info = K.Button(f, ns.T("tradeInfo"), 22, function() end, "quiet")
    info:SetPoint("LEFT", self.modes.frame, "RIGHT", 8, 0)
    K.Tooltip(info, ns.T("bargainNav"), ns.T("bargainInfo"))
    self.scan = K.Button(f, ns.T("bargainRefresh"), 170, function() ns.Scan.Start("pages"); self:Render() end, "main")
    self.scan:SetPoint("TOPRIGHT", f, "TOPRIGHT", -282, -3)
    K.Tooltip(self.scan, ns.T("bargainRefresh"), ns.T("bargainRefreshTip"))
    K.TableHeader(f, -42)
    self.headers, self.cover = {}, {}
    local entries = {{"item", "bargainColItem", nil}, {"count", "bargainColCount", "bargainTipCount"},
        {"price", "bargainColBuyout", "bargainTipBuyout"}, {"market", "bargainColMarket", "bargainTipMarket"},
        {"discount", "bargainColDiscount", "bargainTipDiscount"}, {"revenue", "bargainColRevenue", "bargainTipRevenue"},
        {"age", "bargainColAge", "bargainTipAge"}, {"gain", "bargainColGain", "bargainTipGain"},
        {"left", "bargainColLeft", "bargainTipLeft"}, {"buyout", "bargainColHasBuyout", "bargainTipHasBuyout"}}
    for _, entry in ipairs(entries) do
        local label = K.Label(f, ns.T(entry[2]), 0, -40, 100)
        label:SetHeight(12)
        if entry[1] ~= "item" then label:SetJustifyH("RIGHT") end
        self.headers[entry[1]] = label
        if entry[3] then
            local button = ns.NewFrame("Button", nil, f)
            button:SetAllPoints(label); button:EnableMouse(true)
            K.Tooltip(button, ns.T(entry[2]), ns.T(entry[3]))
            self.cover[entry[1]] = button
        end
    end
    self.scroll = K.TableScroll(f, function() self:Render() end, 62, 66, 24)
    for i = 1, 30 do
        local row = K.BargainRow:New(f, function(key) self:SetProps({key = key}) end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -62 - (i - 1) * 24)
        row.frame:Hide()
        self.pool[i] = row
        self.scroll:Wheel(row.frame)
    end
    self.fees = K.Segment(f, {{key = 0.05, label = ns.T("deFeeOption", 5)}, {key = 0.15, label = ns.T("deFeeOption", 15)}},
        function(fee) self:SetProps({fee = fee}) end)
    self.fees.frame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 4)
    K.Tooltip(self.fees.frame, ns.T("tradeFeeTitle"), ns.T("tradeFeeTip"))
    local label = K.Label(f, ns.T("bargainThreshold"), 0, 0, 70, "secondary")
    label:SetHeight(12)
    label:ClearAllPoints(); label:SetPoint("LEFT", self.fees.frame, "RIGHT", 14, 0)
    self.edit = K.Edit(f, 44)
    self.edit:SetPoint("LEFT", label, "RIGHT", 4, 0)
    K.LiveEdit(self.edit, function(box) self:ApplyPercent(box:GetText()) end, 0.8)
    K.Tooltip(self.edit, ns.T("bargainThreshold"), ns.T("bargainThresholdTip"))
    local unit = K.Label(f, ns.T("bargainPercent"), 0, 0, 16, "secondary")
    unit:SetHeight(12)
    unit:ClearAllPoints(); unit:SetPoint("LEFT", self.edit, "RIGHT", 3, 0)
    self.status = K.Label(f, "", 0, 0, 440, "secondary")
    self.status:ClearAllPoints(); self.status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 34); self.status:SetHeight(12)
    self.note = K.Label(f, "", 0, 0, 440, "secondary")
    self.note:ClearAllPoints(); self.note:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 48); self.note:SetHeight(12)
    self.act = K.Button(f, ns.T("bargainPick"), 210, function() if self.selected then self:Act(self.selected.key) end end, "main")
    self.act:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    self.inspector = K.Inspector:New(f)
    local panel = self.inspector.body
    self.steps = ns.NewFrame("Frame", nil, panel)
    self.steps:SetAllPoints(panel)
    K.Label(self.steps, ns.T("bargainPanelSteps"), 12, -44, 200, "heading")
    local help = K.Button(self.steps, ns.T("tradeInfo"), 22, function() end, "quiet")
    help:SetPoint("TOPRIGHT", self.steps, "TOPRIGHT", -12, -40)
    K.Tooltip(help, ns.T("bargainPanelSteps"), ns.T("bargainStepsTip"))
    self.stepLabels, self.stepValues = {}, {}
    for i = 1, 7 do
        local y = -66 - (i - 1) * 14 - (i == 7 and 4 or 0)
        local name = K.Label(self.steps, "", 12, y, 150, i == 7 and nil or "secondary"); name:SetHeight(12)
        local value = K.Label(self.steps, "", 0, y, 110); value:SetHeight(12); value:SetJustifyH("RIGHT")
        value:ClearAllPoints(); value:SetPoint("TOPRIGHT", self.steps, "TOPRIGHT", -12, y)
        self.stepLabels[i], self.stepValues[i] = name, value
    end
    local discountName = K.Label(self.steps, ns.T("bargainStepDiscount"), 12, -172, 150, "secondary"); discountName:SetHeight(12)
    self.discount = K.Label(self.steps, "", 0, -172, 110); self.discount:SetHeight(12); self.discount:SetJustifyH("RIGHT")
    self.discount:ClearAllPoints(); self.discount:SetPoint("TOPRIGHT", self.steps, "TOPRIGHT", -12, -172)
    K.Rule(self.steps, -190)
    local depthTitle = K.Label(self.steps, ns.T("bargainPanelDepth"), 12, -198, 200, "heading")
    depthTitle:SetHeight(14)
    local depthHelp = K.Button(self.steps, ns.T("tradeInfo"), 22, function() end, "quiet")
    depthHelp:SetPoint("TOPRIGHT", self.steps, "TOPRIGHT", -12, -194)
    K.Tooltip(depthHelp, ns.T("bargainPanelDepth"), ns.T("bargainDepthTip"))
    self.depthSummary = K.Label(self.steps, "", 12, -218, 240, "secondary"); self.depthSummary:SetHeight(12)
    self.depthLines = {}
    for i = 1, 6 do
        local y = -236 - (i - 1) * 14
        local price = K.Label(self.steps, "", 12, y, 110); price:SetHeight(12)
        local units = K.Label(self.steps, "", 0, y, 120, "secondary"); units:SetHeight(12); units:SetJustifyH("RIGHT")
        units:ClearAllPoints(); units:SetPoint("TOPRIGHT", self.steps, "TOPRIGHT", -12, y)
        self.depthLines[i] = {price = price, units = units}
    end
    self.history = K.Label(self.steps, "", 12, -324, 240, "secondary"); self.history:SetHeight(12)
    f:HookScript("OnShow", function() self:Render() end)
    f:SetScript("OnSizeChanged", function() self:Render() end)
    ns.Bargain.onChange = function()
        if self.frame and self.frame:IsVisible() then self:Render() end
    end
    self:Render()
    return self
end
