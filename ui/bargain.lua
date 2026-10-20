local _, ns = ...
local UI = {props = {kind = "buyout", percent = {buyout = 30, bid = 40}}, pool = {}, list = {}}
ns.BargainUI = UI
local function saved()
    local db = ns.Store.DB()
    if type(db.bargainUI) ~= "table" then db.bargainUI = {} end
    return db.bargainUI
end
function UI:Save()
    local s, p = saved(), self.props
    s.fee = nil
    s.kind, s.percent = p.kind, {buyout = p.percent.buyout, bid = p.percent.bid}
end
function UI:Restore()
    local s, p = saved(), self.props
    if s.kind == "buyout" or s.kind == "bid" or s.kind == "vendor" then p.kind = s.kind end
    s.fee = nil
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
    if type(props.percent) == "number" and p.percent[p.kind] then p.percent[p.kind] = props.percent end
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
            self.act:SetText(ns.T(B.job.row.kind == "bid" and "bargainConfirmBid" or "bargainConfirmBuyout", K.Money(cost)))
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
    local ready = phase == "idle" and not ns.Buy.Active()
    if ready then self.modes:Enable() else self.modes:Disable() end
    self.edit:EnableMouse(ready)
end
function UI.VendorTag(row)
    local deal = row.vendor
    local gain = deal and deal[row.kind]
    if row.mode == "vendor" or not gain then return nil end
    return ns.T("vendorTag", ns.TradeKit.MoneyShort(gain))
end
function UI.VendorTip(row)
    local K, deal = ns.TradeKit, row.vendor
    if not deal then return nil end
    local lines = {ns.T("vendorTipPrice", K.Money(deal.unit), row.count, K.Money(deal.total))}
    if deal.buyout then lines[#lines + 1] = ns.T("vendorTipBuyout", K.Money(row.buyout), K.Money(deal.buyout)) end
    if deal.bid then lines[#lines + 1] = ns.T("vendorTipBid", K.Money(deal.nextBid), K.Money(deal.bid)) end
    return table.concat(lines, "\n")
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
    if row.mode == "vendor" then
        cells.price = {K.Money(row.cost)}
        cells.vendor = {K.Money(row.vendor.total), "secondary"}
        cells.gain = {K.Money(row.profit), "positive"}
        cells.deal = {row.kind == "bid" and ns.T("bargainDealBid", left(row.leftMax or 0)) or ns.T("bargainDealBuyout"),
            "secondary"}
        cells.age = {age(scanAge), "secondary"}
    elseif row.kind == "bid" then
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
function UI:Steps(entries)
    local K = ns.TradeKit
    for i, label in ipairs(self.stepLabels) do
        local entry, value = entries[i], self.stepValues[i]
        if entry then
            local last = i == #entries
            local y = -26 - (i - 1) * 14 - (last and 4 or 0)
            label:ClearAllPoints(); label:SetPoint("TOPLEFT", self.steps, "TOPLEFT", 12, y)
            value:ClearAllPoints(); value:SetPoint("TOPRIGHT", self.steps, "TOPRIGHT", -12, y)
            label:SetText(entry[1]); value:SetText(entry[2])
            label:SetTextColor(unpack(K.theme[last and "text" or "secondary"]))
            value:SetTextColor(unpack(K.theme[entry[3] or "text"]))
            label:Show(); value:Show()
        else label:Hide(); value:Hide() end
    end
end
function UI:Panel(row)
    local K, r = ns.TradeKit, row.resale
    local bid = row.kind == "bid"
    local result = row.profit > 0 and "positive" or "negative"
    if row.mode == "vendor" then
        self:Steps({
            {ns.T("vendorStepUnit"), K.Money(row.vendor.unit)},
            {ns.T("vendorStepTotal", row.count), K.Money(row.vendor.total)},
            {ns.T(bid and "bargainStepBid" or "bargainStepBuyout"), "-" .. K.Money(row.cost), "secondary"},
            {ns.T("bargainStepProfit"), K.Money(row.profit), result},
        })
        self.discountLabel:SetText(ns.T("bargainStepMarket"))
        self.discount:SetText(K.Money(row.ref))
    else
        self:Steps({
            {ns.T("bargainStepMarket"), K.Money(row.ref)},
            {ns.T("bargainStepGross", row.count), K.Money(r.gross)},
            {ns.T("bargainStepFee", math.floor(ns.Fee() * 100 + 0.5)), "-" .. K.Money(r.commission), "secondary"},
            {ns.T(r.depositKnown and "bargainStepDeposit" or "bargainStepDepositMin"), "-" .. K.Money(r.deposit),
                "secondary"},
            {ns.T("bargainStepRevenue"), K.Money(r.revenue)},
            {ns.T(bid and "bargainStepBid" or "bargainStepBuyout"), "-" .. K.Money(row.cost), "secondary"},
            {ns.T("bargainStepProfit"), K.Money(row.profit), result},
        })
        self.discountLabel:SetText(ns.T("bargainStepDiscount"))
        self.discount:SetText(ns.T("bargainDiscount", math.floor(row.discount + 0.5)))
    end
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
    if row.mode == "vendor" then self.history:SetText("")
    else self.history:SetText(ns.T(row.history and "bargainHistoryYes" or "bargainHistoryNo")) end
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
    local vendor = p.kind == "vendor"
    self.headers.price:SetText(ns.T(vendor and "bargainColLot" or (p.kind == "bid" and "bargainColBid" or "bargainColBuyout")))
    self.cover.price.tipTitle = self.headers.price:GetText()
    self.cover.price.tip = ns.T(vendor and "bargainTipLot" or (p.kind == "bid" and "bargainTipBid" or "bargainTipBuyout"))
    self.cover.gain.tip = ns.T(vendor and "bargainTipVendorGain" or "bargainTipGain")
    for _, part in ipairs({self.thresholdLabel, self.edit, self.thresholdUnit}) do
        if vendor then part:Hide() else part:Show() end
    end
    local rows, info = B.Rows(p.kind, {percent = p.percent[p.kind], fee = ns.Fee()})
    self.list = rows
    local visible = K.ListCapacity(self.frame, 62, 40, 24, #self.pool)
    local offset = self.scroll:SetRange(#rows, visible)
    local selected = self:Find(p.key) or rows[1]
    self.selected = selected
    local scanAge = info.age or 0
    for i, view in ipairs(self.pool) do
        local row = i <= visible and rows[offset + i]
        if row then
            local copies = row.copies > 1 and ("\n" .. ns.T("bargainRowCopies", row.copies)) or ""
            local vendorTip = UI.VendorTip(row)
            if vendorTip then copies = copies .. "\n\n" .. vendorTip end
            view.frame:ClearAllPoints(); view.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -62 - (i - 1) * 24)
            view:SetProps({key = row.key, id = row.item, width = width, mode = p.kind, cells = self:Cells(row, scanAge),
                tag = UI.VendorTag(row), active = selected == row, tip = ns.T("bargainRowTip") .. copies,
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
    self.edit:SetText(tostring(p.percent[p.kind] or ""))
    local text
    if not info.scan then text = ns.T("bargainNoScan")
    elseif #rows == 0 then text = vendor and ns.T("bargainVendorEmpty") or ns.T("bargainEmpty", p.percent[p.kind])
    else text = ns.T("bargainStatus", age(scanAge), #info.scan.lots, info.groups, info.total) end
    local note = vendor and ns.T("bargainVendorNote", info.hidden or 0)
        or (p.kind == "bid" and ns.T("bargainBidNote", info.hidden or 0) or ns.T("bargainBuyoutNote"))
    if info.scan and scanAge > 3600 then note = ns.T("bargainStale") .. " " .. note end
    self.statusText = text
    if info.scan and scanAge > 3600 then self.statusText = self.statusText .. " | " .. ns.T("bargainStale") end
    K.Tooltip(self.modes.frame, ns.T("bargainTitle"), note)
    ns.Trader.RenderStatus()
    self:FitPanel()
    self:Controls()
end
function UI:FitPanel()
    local room = (self.inspector.body:GetHeight() or 0) - 44
    local fits = room <= 0 or self.panelHeight <= room
    self.scrollBody:ClearAllPoints()
    self.scrollBody:SetPoint("TOPLEFT", self.inspector.body, "TOPLEFT", 0, -40)
    self.scrollBody:SetPoint("BOTTOMRIGHT", self.inspector.body, "BOTTOMRIGHT", fits and -6 or -26, 4)
    ns.TradeKit.PanelScrollBar(self.scrollBody, fits)
    local width = fits and 258 or 236
    self.panelChild:SetWidth(width)
    for _, label in ipairs(self.stepLabels) do label:SetWidth(width - 130) end
    self.discountLabel:SetWidth(width - 130)
    self.depthSummary:SetWidth(width - 24); self.history:SetWidth(width - 24)
    self.panelChild:SetHeight(self.panelHeight)
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
    self.modes = K.Segment(f, {{key = "buyout", label = ns.T("bargainModeBuyout")}, {key = "bid", label = ns.T("bargainModeBid")},
        {key = "vendor", label = ns.T("bargainModeVendor")}}, function(kind) self:SetProps({kind = kind}) end)
    self.modes.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 120, -5)
    K.Tooltip(self.modes.frame, ns.T("bargainTitle"), ns.T("bargainModeBuyoutTip") .. "\n\n" .. ns.T("bargainModeBidTip")
        .. "\n\n" .. ns.T("bargainModeVendorTip"))
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
        {"left", "bargainColLeft", "bargainTipLeft"}, {"buyout", "bargainColHasBuyout", "bargainTipHasBuyout"},
        {"vendor", "bargainColVendor", "bargainTipVendor"}, {"deal", "bargainColDeal", "bargainTipDeal"}}
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
    self.scroll = K.TableScroll(f, function() self:Render() end, 62, 40, 24)
    for i = 1, 30 do
        local row = K.BargainRow:New(f, function(key) self:SetProps({key = key}) end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -62 - (i - 1) * 24)
        row.frame:Hide()
        self.pool[i] = row
        self.scroll:Wheel(row.frame)
    end
    local label = K.Label(f, ns.T("bargainThreshold"), 0, 0, 70, "secondary")
    label:SetHeight(12)
    self.thresholdLabel = label
    label:ClearAllPoints(); label:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
    self.edit = K.Edit(f, 44)
    self.edit:SetPoint("LEFT", label, "RIGHT", 4, 0)
    K.LiveEdit(self.edit, function(box) self:ApplyPercent(box:GetText()) end, 0.8)
    K.Tooltip(self.edit, ns.T("bargainThreshold"), ns.T("bargainThresholdTip"))
    local unit = K.Label(f, ns.T("bargainPercent"), 0, 0, 16, "secondary")
    unit:SetHeight(12)
    unit:ClearAllPoints(); unit:SetPoint("LEFT", self.edit, "RIGHT", 3, 0)
    self.thresholdUnit = unit
    self.act = K.Button(f, ns.T("bargainPick"), 210, function() if self.selected then self:Act(self.selected.key) end end, "main")
    self.act:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    self.inspector = K.Inspector:New(f)
    local panel = self.inspector.body
    self.scrollBody = ns.NewFrame("ScrollFrame", "ManaCodeBargainPanelScroll", panel, "UIPanelScrollFrameTemplate")
    self.scrollBody.scrollBarHideable = 1
    self.panelChild = ns.NewFrame("Frame", nil, self.scrollBody)
    self.panelHeight = 304
    self.panelChild:SetWidth(258); self.panelChild:SetHeight(self.panelHeight)
    self.scrollBody:SetScrollChild(self.panelChild)
    self.panelChild:EnableMouseWheel(true)
    self.panelChild:SetScript("OnMouseWheel", function(_, delta)
        if ScrollFrameTemplate_OnMouseWheel then ScrollFrameTemplate_OnMouseWheel(self.scrollBody, delta) end
    end)
    panel = self.panelChild
    self.steps = ns.NewFrame("Frame", nil, panel)
    self.steps:SetAllPoints(panel)
    K.Label(self.steps, ns.T("bargainPanelSteps"), 12, -4, 200, "heading")
    local help = K.Button(self.steps, ns.T("tradeInfo"), 22, function() end, "quiet")
    help:SetPoint("TOPRIGHT", self.steps, "TOPRIGHT", -12, 0)
    K.Tooltip(help, ns.T("bargainPanelSteps"), ns.T("bargainStepsTip"))
    self.stepLabels, self.stepValues = {}, {}
    for i = 1, 7 do
        local y = -26 - (i - 1) * 14 - (i == 7 and 4 or 0)
        local name, value = K.ValueRow(self.steps, "", y, 130, 100)
        self.stepLabels[i], self.stepValues[i] = name, value
    end
    self.discountLabel, self.discount = K.ValueRow(self.steps, ns.T("bargainStepDiscount"), -132, 130, 100)
    K.Rule(self.steps, -150)
    local depthTitle = K.Label(self.steps, ns.T("bargainPanelDepth"), 12, -158, 200, "heading")
    depthTitle:SetHeight(14)
    local depthHelp = K.Button(self.steps, ns.T("tradeInfo"), 22, function() end, "quiet")
    depthHelp:SetPoint("TOPRIGHT", self.steps, "TOPRIGHT", -12, -154)
    K.Tooltip(depthHelp, ns.T("bargainPanelDepth"), ns.T("bargainDepthTip"))
    self.depthSummary = K.Label(self.steps, "", 12, -178, 240, "secondary"); self.depthSummary:SetHeight(12)
    self.depthLines = {}
    for i = 1, 6 do
        local y = -196 - (i - 1) * 14
        local price = K.Label(self.steps, "", 12, y, 110); price:SetHeight(12)
        local units = K.Label(self.steps, "", 0, y, 120, "secondary"); units:SetHeight(12); units:SetJustifyH("RIGHT")
        units:ClearAllPoints(); units:SetPoint("TOPRIGHT", self.steps, "TOPRIGHT", -12, y)
        self.depthLines[i] = {price = price, units = units}
    end
    self.history = K.Label(self.steps, "", 12, -284, 240, "secondary"); self.history:SetHeight(12)
    f:HookScript("OnShow", function() self:Render() end)
    f:SetScript("OnSizeChanged", function() self:Render() end)
    ns.Bargain.onChange = function()
        if self.frame and self.frame:IsVisible() then self:Render() end
    end
    self:Render()
    return self
end
