local _, ns = ...
local UI = {props = {key = "planar"}, rows = {}, groups = {}, collapsed = {}}
ns.RecycleUI = UI
local TOP, BOTTOM, ROW = 26, 34, 24
function UI:SetProps(props)
    for key, value in pairs(props) do if key ~= "fee" then self.props[key] = value end end
    self:Render()
end
function UI:Controls()
    if not self.frame then return end
    local phase = ns.Scan.state.phase
    if phase == "idle" and not ns.Buy.Active() then self.scan:Enable() else self.scan:Disable() end
end
function UI:Lines()
    local lines = {}
    for _, group in ipairs(ns.Recycle.Groups()) do
        lines[#lines + 1] = {group = group}
        if not self.collapsed[group.group] then
            for _, pair in ipairs(group.pairs) do lines[#lines + 1] = {pair = pair} end
        end
    end
    return lines
end
function UI:RowTip(pair, estimate)
    local K = ns.TradeKit
    return ns.T("recycleDetail", pair.ratio, ns.Markets.Name(pair.small)) .. "\n"
        .. ns.T("recycleDetailPrices", K.Money(estimate.smallPrice), K.Money(estimate.bigPrice)) .. "\n"
        .. ns.T("recycleHave", estimate.haveBig, estimate.haveSmall) .. "\n"
        .. ns.T("recycleRowTip")
end
function UI:FitPanel()
    local room = (self.inspector.body:GetHeight() or 0) - 44
    local fits = room <= 0 or self.panelHeight <= room
    local width = fits and 258 or 236
    self.scrollBody:ClearAllPoints()
    self.scrollBody:SetPoint("TOPLEFT", self.inspector.body, "TOPLEFT", 0, -40)
    self.scrollBody:SetPoint("BOTTOMRIGHT", self.inspector.body, "BOTTOMRIGHT", fits and -6 or -26, 4)
    ns.TradeKit.PanelScrollBar(self.scrollBody, fits)
    self.panelChild:SetWidth(width); self.panelChild:SetHeight(self.panelHeight)
    local inner = width - 24
    for _, label in ipairs(self.priceLabels) do label:SetWidth(inner - 118) end
    for _, label in ipairs(self.outcomeLabels) do label:SetWidth(inner - 108) end
    self.formula:SetWidth(inner - 22)
    self.advice:SetWidth(inner); self.packNote:SetWidth(inner); self.have:SetWidth(inner)
    self.packsHead:SetWidth(inner)
    for _, label in ipairs(self.packLines) do label:SetWidth(inner) end
end
function UI:Panel(pair, estimate)
    local K = ns.TradeKit
    self.formula:SetText(ns.T("recycleFormula", pair.ratio))
    self.priceValues[1]:SetText(K.Money(estimate.smallPrice))
    self.priceValues[2]:SetText(K.Money(estimate.bigPrice))
    local values = {estimate.asIs, pair.both and estimate.split or nil, estimate.assemble}
    for i, label in ipairs(self.outcomeValues) do
        local value = values[i]
        label:SetText(i == 2 and not pair.both and ns.T("recycleOneWay") or K.Money(value))
        local tone = "text"
        if i == 1 and estimate.best == "asIs" or i == 2 and estimate.best == "split" then tone = "positive"
        elseif i == 3 and value then tone = value > 0 and "positive" or "negative" end
        label:SetTextColor(unpack(K.theme[tone]))
    end
    self.advice:SetText(ns.T(estimate.advice))
    self.have:SetText(ns.T("recycleHave", estimate.haveBig, estimate.haveSmall))
    local stacks, best = ns.Recycle.Stacks(pair.big)
    for i, label in ipairs(self.packLines) do
        local stack = stacks[i]
        if stack then
            label:SetText(ns.T("recyclePackRow", stack.size, K.Money(stack.unit))
                .. (stack.premium and ns.T("recyclePackPremium", stack.premium) or ""))
            label:SetTextColor(unpack(K.theme[stack.premium and stack.premium > 0 and "positive" or "secondary"]))
            label:Show()
        else label:Hide() end
    end
    self.packNote:SetText(#stacks == 0 and ns.T("recyclePackEmpty")
        or (best and ns.T("recyclePackBest", best.size, best.premium) or ns.T("recyclePackNone")))
    self:FitPanel()
end
function UI:Render()
    if not self.frame then return end
    local K, R, p, f = ns.TradeKit, ns.Recycle, self.props, self.frame
    local width = (f:GetWidth() or 996) - 300
    local columns = K.RecycleColumns(width)
    for key, label in pairs(self.headers) do
        local column = columns[key]
        label:ClearAllPoints()
        if column then
            label:SetPoint("TOPLEFT", f, "TOPLEFT", 10 + column[1] + (key == "item" and 6 or 0), -(TOP - 16))
            label:SetWidth(column[2] - 6); label:Show()
        else label:Hide() end
    end
    for key, button in pairs(self.headerTips) do
        if columns[key] then button:Show() else button:Hide() end
    end
    local lines = self:Lines()
    local visible = K.ListCapacity(f, TOP, BOTTOM, ROW, #self.rows + #self.groups)
    local offset = self.scroll:SetRange(#lines, visible)
    local usedRows, usedGroups = 0, 0
    for i = 1, visible do
        local line = lines[offset + i]
        local y = -TOP - (i - 1) * ROW
        if line and line.group then
            usedGroups = usedGroups + 1
            local header, group = self.groups[usedGroups], line.group
            if header then
                local priced = 0
                for _, pair in ipairs(group.pairs) do
                    local e = R.Evaluate(pair, ns.Fee())
                    if e.asIs or e.split then priced = priced + 1 end
                end
                header.frame:ClearAllPoints(); header.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, y)
                header:SetProps({key = group.group, width = width, height = ROW, open = not self.collapsed[group.group],
                    name = ns.T(group.labelKey), detail = ns.T("recycleGroupDetail", #group.pairs, priced),
                    tip = ns.T("recycleGroupTip")})
            end
        elseif line then
            usedRows = usedRows + 1
            local row, pair = self.rows[usedRows], line.pair
            if row then
                local estimate = R.Evaluate(pair, ns.Fee())
                row.frame:ClearAllPoints(); row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, y)
                row:SetProps({key = pair.key, id = pair.big, width = width, estimate = estimate, oneWay = not pair.both,
                    active = pair.key == p.key, tip = self:RowTip(pair, estimate),
                    actions = {{label = ns.T("tradeUpdate"), icon = "refresh", tip = ns.T("recycleScanPairTip"),
                        fn = function(key) R.Complete(R.Pair(key), K.ScanMode()); self:Render() end}}})
            end
        end
    end
    for i = usedRows + 1, #self.rows do self.rows[i].frame:Hide() end
    for i = usedGroups + 1, #self.groups do self.groups[i].frame:Hide() end
    local selected = R.Pair(p.key)
    if selected then
        self.inspector:SetProps({id = selected.big})
        self:Panel(selected, R.Evaluate(selected, ns.Fee()))
    else self.inspector:Clear() end
    self:Controls()
end
function UI:NewTable(f)
    local K = ns.TradeKit
    self.headerBand = K.TableHeader(f, -(TOP - 18))
    self.headerBand:ClearAllPoints()
    self.headerBand:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -3)
    self.headerBand:SetPoint("TOPRIGHT", f, "TOPRIGHT", -290, -3)
    self.headers, self.headerTips = {}, {}
    local tips = {asIs = "recycleAsIsTip", split = "recycleSplitTip", assemble = "recycleAssembleTip", bags = "recycleBagsTip"}
    for _, entry in ipairs({{"item", "recycleColPair"}, {"asIs", "recycleColAsIs"}, {"split", "recycleColSplit"},
        {"assemble", "recycleColAssemble"}, {"bags", "recycleColBags"}}) do
        local label = K.Label(f, ns.T(entry[2]), 0, -(TOP - 16), 100)
        label:SetHeight(12)
        if entry[1] ~= "item" then label:SetJustifyH("RIGHT") end
        self.headers[entry[1]] = label
        if tips[entry[1]] then
            local button = ns.NewFrame("Button", nil, f)
            button:SetAllPoints(label); button:EnableMouse(true)
            K.Tooltip(button, ns.T(entry[2]), ns.T(tips[entry[1]]))
            self.headerTips[entry[1]] = button
        end
    end
    self.scroll = K.Scroller:New(f, function() self:Render() end, ROW)
    self.scroll.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -TOP)
    self.scroll.frame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -272, BOTTOM)
    for i = 1, 40 do
        local row = K.RecycleRow:New(f, function(key) self:SetProps({key = key}) end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -TOP - (i - 1) * ROW)
        row.frame:Hide()
        self.rows[i] = row
        self.scroll:Wheel(row.frame)
    end
    for i = 1, 3 do
        local header = K.GroupRow:New(f, function(key) self.collapsed[key] = not self.collapsed[key] or nil; self:Render() end)
        header.frame:Hide(); self.scroll:Wheel(header.frame); self.groups[i] = header
    end
end
function UI:NewBottom(f)
    local K = ns.TradeKit
    self.buyBig = K.Button(f, ns.T("recycleBuyBig"), 120, function()
        local pair = ns.Recycle.Pair(self.props.key); if pair then ns.Trader.OpenBuy(pair.big) end
    end)
    self.buyBig:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -428, 4)
    self.buySmall = K.Button(f, ns.T("recycleBuySmall"), 120, function()
        local pair = ns.Recycle.Pair(self.props.key); if pair then ns.Trader.OpenBuy(pair.small) end
    end)
    self.buySmall:SetPoint("RIGHT", self.buyBig, "LEFT", -6, 0)
end
function UI:NewPanel()
    local K = ns.TradeKit
    self.inspector = K.Inspector:New(self.frame)
    self.inspector:Place(-30)
    local panel = self.inspector.body
    self.scrollBody = ns.NewFrame("ScrollFrame", "ManaCodeRecyclePanelScroll", panel, "UIPanelScrollFrameTemplate")
    self.scrollBody.scrollBarHideable = 1
    self.scrollBody:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -40)
    self.scrollBody:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6, 4)
    local c = ns.NewFrame("Frame", nil, self.scrollBody)
    c:SetWidth(258); c:SetHeight(296)
    self.panelHeight = 296
    self.scrollBody:SetScrollChild(c)
    c:EnableMouseWheel(true)
    c:SetScript("OnMouseWheel", function(_, delta)
        if ScrollFrameTemplate_OnMouseWheel then ScrollFrameTemplate_OnMouseWheel(self.scrollBody, delta) end
    end)
    self.panelChild = c
    self.formula = K.Label(c, "", 12, -4, 188, "heading"); self.formula:SetHeight(14)
    self.priceValues, self.priceLabels = {}, {}
    for i, key in ipairs({"recyclePriceSmall", "recyclePriceBig"}) do
        local y = -22 - (i - 1) * 14
        local label, value = K.ValueRow(c, ns.T(key), y, 130, 110)
        self.priceLabels[i], self.priceValues[i] = label, value
    end
    K.Rule(c, -54)
    K.Label(c, ns.T("recyclePerUnit"), 12, -62, 234, "heading")
    self.outcomeValues, self.outcomeLabels = {}, {}
    for i, key in ipairs({"recycleAsIs", "recycleSplit", "recycleAssemble"}) do
        local y = -82 - (i - 1) * 14
        local label, value = K.ValueRow(c, ns.T(key), y, 150, 100)
        self.outcomeLabels[i], self.outcomeValues[i] = label, value
    end
    self.advice = K.Label(c, "", 12, -128, 234); self.advice:SetHeight(28); self.advice:SetJustifyV("TOP")
    self.have = K.Label(c, "", 12, -160, 234, "secondary"); self.have:SetHeight(12)
    K.Rule(c, -178)
    self.packsHead = K.Label(c, ns.T("recyclePacks"), 12, -186, 234, "heading"); self.packsHead:SetHeight(14)
    local packsTip = ns.NewFrame("Button", nil, c)
    packsTip:SetAllPoints(self.packsHead); packsTip:EnableMouse(true)
    K.Tooltip(packsTip, ns.T("recyclePacks"), ns.T("recyclePacksTip"))
    self.packLines = {}
    for i = 1, 5 do
        local line = K.Label(c, "", 12, -206 - (i - 1) * 13, 234); line:SetHeight(12)
        self.packLines[i] = line
    end
    self.packNote = K.Label(c, "", 12, -274, 234); self.packNote:SetHeight(28); self.packNote:SetJustifyV("TOP")
    local info = K.Button(panel, ns.T("tradeInfo"), 22, function() end, "quiet")
    info:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -44)
    K.Tooltip(info, ns.T("recycleNav"), ns.T("recycleInfo"))
end
function UI:New(parent)
    local K = ns.TradeKit
    self.frame = ns.NewFrame("Frame", nil, parent)
    local f = self.frame
    f:SetAllPoints(parent)
    self:NewTable(f)
    self:NewBottom(f)
    self.scan = K.Button(f, ns.T("recycleScanAll"), 140, function() ns.Recycle.CompleteAll(K.ScanMode()); self:Render() end, "main")
    self.scan:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    K.Tooltip(self.scan, ns.T("recycleScanAll"), ns.T("recycleScanAllTip"))
    self.scan.tipFn = function() return ns.T("recycleScanAllTip") .. "\n\n" .. ns.Batch.PreviewText(ns.Recycle.Targets(), true) end
    self:NewPanel()
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render()
    return self
end
