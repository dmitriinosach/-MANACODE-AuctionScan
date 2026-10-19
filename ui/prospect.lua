local _, ns = ...
local UI = {mode = "prospect", states = {}, rows = {}, groups = {}, filtersOpen = false}
ns.ProspectUI = UI
local expansionKeys = {"wrath", "bc", "classic"}
local expansionLabels = {wrath = "pmExpWrath", bc = "pmExpBC", classic = "pmExpClassic"}
local function decimal(value)
    return (string.format("%.2f", value):gsub("%.", ","))
end
local function percent(chance)
    return math.floor(chance * 100 + 0.5)
end
local function defaults(mode)
    local P = ns.Prospect
    local target = mode == "mill" and 39343 or 36932
    if not P.IsTarget(mode, target) then target = P.Targets(mode)[1] end
    return {view = "raw", target = target, fee = 0.05, expansions = {wrath = true, bc = true, classic = true},
        skill = 0, buyMode = "margin", buyPercent = 0, buyPrice = 10000, collapsed = {}}
end
function UI:Load(mode)
    local state, P = defaults(mode), ns.Prospect
    local db = ns.Store.DB()
    local saved = type(db.prospectUI) == "table" and db.prospectUI[mode]
    if type(saved) ~= "table" then return state end
    if saved.view == "target" then state.view = "target" end
    if type(saved.target) == "number" and P.IsTarget(mode, saved.target) then state.target = saved.target end
    if saved.fee == 0.15 then state.fee = 0.15 end
    if type(saved.expansions) == "table" then
        local any = false
        for _, key in ipairs(expansionKeys) do any = any or saved.expansions[key] == true end
        if any then
            for _, key in ipairs(expansionKeys) do state.expansions[key] = saved.expansions[key] == true end
        end
    end
    if type(saved.skill) == "number" and saved.skill >= 0 and saved.skill <= 999 then state.skill = math.floor(saved.skill) end
    if saved.buyMode == "price" then state.buyMode = "price" end
    if type(saved.buyPercent) == "number" and saved.buyPercent > -100 and saved.buyPercent <= 1000 then
        state.buyPercent = saved.buyPercent
    end
    if type(saved.buyPrice) == "number" and saved.buyPrice >= 1 and saved.buyPrice <= 1000000000 then
        state.buyPrice = math.floor(saved.buyPrice)
    end
    return state
end
function UI:S()
    local state = self.states[self.mode]
    if not state then
        state = self:Load(self.mode)
        self.states[self.mode] = state
    end
    return state
end
function UI:Save()
    local db, s = ns.Store.DB(), self:S()
    db.prospectUI = type(db.prospectUI) == "table" and db.prospectUI or {}
    db.prospectUI[self.mode] = {view = s.view, target = s.target, fee = s.fee, skill = s.skill,
        expansions = {wrath = s.expansions.wrath, bc = s.expansions.bc, classic = s.expansions.classic},
        buyMode = s.buyMode, buyPercent = s.buyPercent, buyPrice = s.buyPrice}
end
function UI:SetProps(props)
    if props.mode and props.mode ~= self.mode and ns.Prospect.modes[props.mode] then
        ns.Prospect.CancelBuy()
        self.mode = props.mode
        if self.scroll then self.scroll.offset = 0 end
        local mode = self:S()
        if self.buyEdit then
            self.buyEdit:SetText(tostring(mode.buyMode == "price" and mode.buyPrice / 10000 or mode.buyPercent))
        end
    end
    local s = self:S()
    if props.view == "raw" or props.view == "target" then s.view = props.view end
    if props.target and ns.Prospect.IsTarget(self.mode, props.target) then s.target = props.target end
    if props.fee == 0.05 or props.fee == 0.15 then s.fee = props.fee end
    self:Save()
    self:Render()
end
function UI:SelectView(view)
    local s = self:S()
    if s.view == view then return end
    ns.Prospect.CancelBuy()
    s.view, s.selected = view, nil
    self.scroll.offset = 0
    self:Save(); self:Render()
end
function UI:SelectTarget(id)
    local s = self:S()
    ns.Prospect.CancelBuy()
    s.target, s.view, s.selected = id, "target", nil
    self.scroll.offset = 0
    self:Save(); self:Render()
end
function UI:Options()
    local s = self:S()
    return {fee = s.fee, percent = s.buyMode == "margin" and s.buyPercent or 0,
        priceLimit = s.buyMode == "price" and s.buyPrice or nil}
end
function UI:Entries()
    local s = self:S()
    return ns.Prospect.Rows(self.mode, {view = s.view, target = s.target, fee = s.fee,
        expansions = s.expansions, skill = s.skill})
end
function UI:RefreshIDs()
    local ids = {}
    for _, entry in ipairs(self:Entries()) do ids[#ids + 1] = entry.id end
    return ns.Prospect.PriceIDs(self.mode, ids)
end
function UI:Refresh(ids)
    ns.Prospect.Refresh(ids or self:RefreshIDs(), ns.TradeKit.ScanMode())
    self:Render()
end
function UI:Purchase(id)
    local s = self:S()
    id = id or (ns.Prospect.purchase and ns.Prospect.purchase.id) or s.selected
    if not id then return end
    if not ns.Prospect.purchase then s.selected = id end
    ns.Prospect.Purchase(self.mode, id, self:Options())
    self:Render()
end
function UI:Formula(entry)
    local K, e, lines = ns.TradeKit, entry.estimate, {}
    for i, output in ipairs(e.outputs) do
        if i > 6 then lines[#lines + 1] = ns.T("pmFormulaMore", #e.outputs - 6); break end
        lines[#lines + 1] = ns.T("pmFormulaLine", ns.Markets.Name(output.id), percent(output.chance),
            decimal(output.quantity), K.Money(output.price))
    end
    if e.margin then
        lines[#lines + 1] = ns.T("deFormulaGross", K.Money(e.gross))
        lines[#lines + 1] = ns.T("deFormulaFee", math.floor(self:S().fee * 100 + 0.5), K.Money(e.gross * self:S().fee))
        lines[#lines + 1] = ns.T("pmFormulaCost", K.Money(e.cost))
        lines[#lines + 1] = ns.T("deFormulaMargin", K.Money(e.margin), ns.T("deMarginRate", e.percent or 0))
        if not e.exact then lines[#lines + 1] = ns.T("pmFormulaPartial", e.missing) end
    else lines[#lines + 1] = ns.T("deFormulaUnknown") end
    return table.concat(lines, "\n")
end
function UI:Lines(groups)
    local lines, collapsed = {}, self:S().collapsed
    for _, group in ipairs(groups) do
        lines[#lines + 1] = {group = group}
        if not collapsed[group.key] then
            for _, entry in ipairs(group.rows) do lines[#lines + 1] = {entry = entry, group = group} end
        end
    end
    return lines
end
function UI:GroupName(group)
    if self.mode == "prospect" then return ns.T(expansionLabels[group.key]) end
    return ns.Markets.Name(group.key)
end
function UI:GroupDetail(group)
    local skill = group.skillMin == group.skillMax and ns.T("pmSkillOne", group.skillMin)
        or ns.T("pmSkillRange", group.skillMin, group.skillMax)
    local parts = {ns.T("pmGroupCount", #group.rows), skill}
    if self.mode == "mill" then table.insert(parts, 1, ns.T(expansionLabels[group.expansion])) end
    return table.concat(parts, "   ")
end
function UI:NewTop(f)
    local K = ns.TradeKit
    self.viewSegment = K.Segment(f, {{key = "target", label = ns.T("pmViewTarget")},
        {key = "raw", label = ns.T("pmViewRaw")}}, function(view) self:SelectView(view) end)
    self.viewSegment.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -3)
    K.Tooltip(self.viewSegment.frame, ns.T("pmViewTitle"), ns.T("pmViewTip"))
    self.targetPicker = K.FamilyPicker:New(f, function(id) self:SelectTarget(id) end)
    self.targetPicker.frame:SetPoint("LEFT", self.viewSegment.frame, "RIGHT", 8, 0)
    K.Tooltip(self.targetPicker.frame, ns.T("pmViewTitle"), ns.T("pmViewTip"))
    self.rawHint = K.Label(f, "", 0, 0, 300, "secondary")
    self.rawHint:SetHeight(12)
    self.rawHint:ClearAllPoints(); self.rawHint:SetPoint("LEFT", self.viewSegment.frame, "RIGHT", 10, 0)
    self.targetQuote = K.Label(f, "", 0, 0, 260, "secondary")
    self.targetQuote:SetHeight(12)
    self.targetQuote:ClearAllPoints(); self.targetQuote:SetPoint("LEFT", self.targetPicker.frame, "RIGHT", 10, 0)
    self.scan = K.Button(f, ns.T("tradeUpdate"), 84, function() self:Refresh() end, "main")
    self.scan:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -3)
    K.Tooltip(self.scan, ns.T("pmRefresh"), ns.T("pmRefreshTip"))
    self.scan.tipFn = function()
        return ns.T("pmRefreshTip") .. "\n\n" .. ns.Batch.PreviewText(self:RefreshIDs(), true)
    end
    self.filterToggle = K.Button(f, ns.T("deFilters"), 84, function()
        self.filtersOpen = not self.filtersOpen; self:Render()
    end, "quiet")
    self.filterToggle:SetPoint("RIGHT", self.scan, "LEFT", -8, 0)
    K.Tooltip(self.filterToggle, ns.T("deFilters"), ns.T("pmFiltersTip"))
    self.filterToggle.tipFn = function() return ns.T("pmFiltersTip") .. "\n\n" .. self:FilterSummary() end
    self.targetQuote:SetPoint("RIGHT", self.filterToggle, "LEFT", -8, 0)
    self.filters = K.Card(f)
    self.filters:SetHeight(36)
    self:NewFilters(self.filters)
end
function UI:NewFilters(parent)
    local K = ns.TradeKit
    local x = 10
    local function put(frame, width, gap)
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -8)
        if frame.SetWidth and width then frame:SetWidth(width) end
        x = x + (width or frame:GetWidth() or 60) + gap
    end
    local function caption(text, width)
        local label = K.Label(parent, text, 0, 0, width, "secondary")
        label:SetHeight(12)
        label:ClearAllPoints(); label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -13)
        x = x + width + 4
    end
    caption(ns.T("pmFilterExpansion"), 76)
    self.expansionChecks = {}
    for _, key in ipairs(expansionKeys) do
        local expansion = key
        local chip = K.Chip(parent, ns.T(expansionLabels[expansion]), function(checked)
            local s = self:S()
            s.expansions[expansion] = checked
            local any = false
            for _, other in ipairs(expansionKeys) do any = any or s.expansions[other] end
            if not any then s.expansions[expansion] = true end
            self:Save(); self:Render()
        end)
        put(chip, nil, 4)
        K.Tooltip(chip, ns.T("pmFilterExpansion"), ns.T("pmFilterExpansionTip"))
        self.expansionChecks[expansion] = chip
    end
    x = x + 14
    caption(ns.T("pmFilterSkill"), 76)
    self.skillEdit = K.Edit(parent, 46)
    put(self.skillEdit, 46, 14)
    K.Tooltip(self.skillEdit, ns.T("pmFilterSkill"), ns.T("pmFilterSkillTip"))
    K.LiveEdit(self.skillEdit, function(box)
        local text = box:GetText()
        local value = text == "" and 0 or tonumber(text)
        if value and value >= 0 and value <= 999 and value == math.floor(value) then
            self:S().skill = value; self:Save()
        end
        self:Render()
    end)
    caption(ns.T("deFilterFee"), 58)
    self.feeSegment = K.Segment(parent, {{key = 0.05, label = ns.T("deFeeOption", 5)},
        {key = 0.15, label = ns.T("deFeeOption", 15)}}, function(fee)
        self:S().fee = fee; self:Save(); self:Render()
    end)
    put(self.feeSegment.frame, nil, 12)
    K.Tooltip(self.feeSegment.frame, ns.T("tradeFeeTitle"), ns.T("tradeFeeTip"))
end
function UI:FilterSummary()
    local s, parts = self:S(), {}
    local names = {}
    for _, key in ipairs(expansionKeys) do
        if s.expansions[key] then names[#names + 1] = ns.T(expansionLabels[key]) end
    end
    parts[#parts + 1] = table.concat(names, ", ")
    if s.skill > 0 then parts[#parts + 1] = ns.T("pmSummarySkill", s.skill) end
    parts[#parts + 1] = ns.T("tradeFee", math.floor(s.fee * 100 + 0.5))
    return table.concat(parts, " | ")
end
function UI:Layout()
    local K, P = ns.TradeKit, ns.Prospect
    local f, s = self.frame, self:S()
    local width = f:GetWidth() or 996
    self.viewSegment:Select(s.view)
    local target = s.view == "target"
    local pickerWidth = math.max(150, math.min(230, width - 700))
    self.targetPicker.frame:SetWidth(pickerWidth); self.targetPicker.frame.text:SetWidth(pickerWidth - 34)
    if target then
        self.targetPicker.frame:Show(); self.rawHint:Hide()
        self.targetPicker:SetProps({families = P.TargetItems(self.mode), raw = s.target,
            headingKey = self.mode == "mill" and "pmPickPigment" or "pmPickGem"})
        local quote = ns.Markets.Quote(s.target)
        if quote and quote.price then
            local age = quote.at and (time() - quote.at >= 3600 and ns.T("deHours", math.floor((time() - quote.at) / 3600))
                or ns.T("tradeAge", math.floor((time() - quote.at) / 60))) or ""
            self.targetQuote:SetText(ns.T("deTargetQuote", K.Money(quote.price), age))
        else self.targetQuote:SetText(ns.T("deTargetQuoteNone")) end
        self.targetQuote:Show()
    else
        self.targetPicker.frame:Hide(); self.targetPicker.cover:Hide()
        self.rawHint:SetText(ns.T(self.mode == "mill" and "pmRawHintMill" or "pmRawHintProspect"))
        self.rawHint:Show(); self.targetQuote:Hide()
    end
    local open = self.filtersOpen
    self.filterToggle:SetActive(open)
    self.filterToggle:SetText(ns.T(open and "deFiltersOpen" or "deFilters"))
    for key, chip in pairs(self.expansionChecks) do chip:SetChecked(s.expansions[key]) end
    self.feeSegment:Select(s.fee)
    if not self.skillEdit:HasFocus() then self.skillEdit:SetText(s.skill > 0 and tostring(s.skill) or "") end
    self.filters:ClearAllPoints()
    self.filters:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -30)
    self.filters:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -30)
    if open then self.filters:Show() else self.filters:Hide() end
    return 56 + (open and 42 or 0)
end
function UI:Controls()
    local phase = ns.Scan.state.phase
    local P = ns.Prospect
    local busy = phase ~= "idle" or ns.Buy.Active()
    if busy then self.scan:Disable() else self.scan:Enable() end
    local job = P.purchase
    self.buy:SetWidth(job and 220 or 170)
    if job then
        local count, cost = ns.Buy.Offer()
        self.buy:SetText(ns.Buy.state.phase == "ready" and ns.T("deBuyConfirm", count, ns.TradeKit.Money(cost))
            or ns.T("deBuySearching"))
        if ns.Buy.state.phase == "ready" then self.buy:Enable() else self.buy:Disable() end
    else
        self.buy:SetText(ns.T(self:S().buyMode == "price" and "deBuyByPrice" or "deBuyByMargin"))
        if self.preview and self.preview.count > 0 and ns.Scan.state.open and not busy then self.buy:Enable()
        else self.buy:Disable() end
    end
    local ready = not busy
    local price = self:S().buyMode == "price"
    if ready then self.buyEdit:Show(); self.buyLabel:Show(); self.buyUnit:Show()
    else self.buyEdit:Hide(); self.buyLabel:Hide(); self.buyUnit:Hide() end
    self.buyLabel:SetText(ns.T(price and "buyPriceLimit" or "deBuyThreshold"))
    self.buyUnit:SetText(ns.T(price and "deGold" or "dePercent"))
    self.buyModes:Select(self:S().buyMode)
    for _, control in ipairs({self.buyModes, self.viewSegment, self.feeSegment}) do
        if ready then control:Enable() else control:Disable() end
    end
    if not ready then self.targetPicker.cover:Hide() end
    self.skillEdit:EnableMouse(ready)
end
function UI:Panel(selected)
    local K, P, s = ns.TradeKit, ns.Prospect, self:S()
    local parts = {self.note, self.calcTitle, self.outcomes.frame, self.profitLabel, self.profitValue,
        self.viaLabel, self.viaValue, self.netLabel, self.netValue}
    for _, label in ipairs(self.calcKeys) do parts[#parts + 1] = label end
    for _, label in ipairs(self.calcValues) do parts[#parts + 1] = label end
    for _, tile in ipairs(self.scenarios) do parts[#parts + 1] = tile.frame end
    if not selected then
        for _, part in ipairs(parts) do part:Hide() end
        self.outcomes:SetProps({outputs = {}})
        self.summary:Show()
        self.summary:SetText(ns.T(self.mode == "mill" and "pmIntroMill" or "pmIntroProspect") .. "\n\n" .. ns.T("pmSelectHint"))
        self:FitPanel(false)
        return
    end
    for _, part in ipairs(parts) do part:Show() end
    self.summary:Hide()
    local e = selected.estimate
    local note = ns.T(self.mode == "mill" and "pmNeedSkillMill" or "pmNeedSkillProspect", selected.source.skill)
    if not e.exact then note = note .. "\n" .. ns.T("pmMissing", e.missing) end
    self.note:SetText(note)
    self:FitPanel(true)
    local target = s.view == "target" and s.target or nil
    local outputs = {}
    for _, output in ipairs(e.outputs) do
        if output.id == target then table.insert(outputs, 1, output) else outputs[#outputs + 1] = output end
    end
    self.outcomes:SetProps({source = selected.id, target = target, outputs = outputs})
    self.calcKeys[1]:SetText(ns.T("pmCalcGross"))
    self.calcKeys[2]:SetText(ns.T("deCalcFee", math.floor(s.fee * 100 + 0.5)))
    self.calcKeys[3]:SetText(ns.T("pmCalcCost", P.OPERATION))
    local values = {e.gross and K.Money(e.gross) or K.Money(nil),
        e.gross and ("-" .. K.Money(e.gross * s.fee)) or K.Money(nil),
        e.cost and ("-" .. K.Money(e.cost)) or K.Money(nil),
        K.Money(e.margin) .. (e.percent and (" " .. ns.T("deMarginRate", e.percent)) or "")}
    for i, label in ipairs(self.calcValues) do label:SetText(values[i]) end
    self.calcValues[4]:SetTextColor(unpack(K.theme[e.margin and (e.margin > 0 and "positive" or "negative") or "text"]))
    local scenarios = {e.low, e.margin, e.high}
    for i, tile in ipairs(self.scenarios) do
        local value = scenarios[i]
        tile.value:SetText(K.MoneyShort(value))
        tile.value:SetTextColor(unpack(K.theme[value and (value > 0 and "positive" or "negative") or "text"]))
    end
    local verdict
    if e.percent == nil then verdict = ns.T("deProfitUnknown")
    elseif e.margin <= 0 and not e.exact then verdict = ns.T("deProfitUnknown")
    elseif s.buyMode == "price" then verdict = ns.T(e.margin > 0 and "deProfitLow" or "deProfitNo")
    elseif e.percent > s.buyPercent then verdict = ns.T("deProfitYes", s.buyPercent)
    elseif e.margin > 0 then verdict = ns.T("deProfitLow")
    else verdict = ns.T("deProfitNo") end
    self.profitValue:SetText(verdict)
    self.profitValue:SetTextColor(unpack(K.theme[e.margin and (e.margin > 0 and "positive" or "negative") or "secondary"]))
    if target and selected.via then
        self.viaLabel:SetText(ns.T("pmViaLabel", ns.Markets.Name(target)))
        self.viaValue:SetText(K.Money(selected.via) .. (selected.viaRate and (" " .. ns.T("deViaRate", selected.viaRate)) or ""))
        self.viaValue:SetTextColor(unpack(K.theme[selected.viaRate and (selected.viaRate < 0 and "positive" or "negative") or "text"]))
        self.netLabel:SetText(ns.T("pmViaNetLabel"))
        self.netValue:SetText(K.Money(selected.viaNet))
    else
        self.viaLabel:Hide(); self.viaValue:Hide(); self.netLabel:Hide(); self.netValue:Hide()
    end
end
function UI:FitPanel(withNote)
    local height = 30 + self.calcHeight
    if withNote then self.note:Show() else self.note:Hide() end
    self.calc:ClearAllPoints(); self.calc:SetPoint("TOPLEFT", self.panelChild, "TOPLEFT", 0, -30)
    local room = (self.inspector.body:GetHeight() or 0) - 44
    local fits = room <= 0 or height <= room
    local width = fits and 258 or 236
    self.scrollBody:ClearAllPoints()
    self.scrollBody:SetPoint("TOPLEFT", self.inspector.body, "TOPLEFT", 0, -40)
    self.scrollBody:SetPoint("BOTTOMRIGHT", self.inspector.body, "BOTTOMRIGHT", fits and -6 or -26, 4)
    self.panelChild:SetWidth(width); self.panelChild:SetHeight(height)
    self.calc:SetWidth(width)
    self.note:SetWidth(width - 24)
    local tile = math.floor((width - 16 - 8) / 3)
    for i, card in ipairs(self.scenarios) do
        card.frame:SetWidth(tile); card.frame:ClearAllPoints()
        card.frame:SetPoint("TOPLEFT", self.calc, "TOPLEFT", 12 + (i - 1) * (tile + 4), -234)
        card.title:SetWidth(tile - 8); card.value:SetWidth(tile - 8)
    end
    self.outcomes.frame:SetWidth(width - 16)
end
function UI:PreviewText(selected)
    local K, P, s = ns.TradeKit, ns.Prospect, self:S()
    local preview = self.preview
    if not selected then return ns.T("pmBuyPick") end
    local text
    if preview.count > 0 then
        text = ns.T("pmBuyPreview", preview.count, preview.units, math.floor(preview.units / P.OPERATION), K.Money(preview.cost))
    elseif not ns.Scan.state.open then text = ns.T("deBuyClosed")
    elseif preview.rejected == "refresh" then text = ns.T("pmBuyRefresh")
    elseif preview.rejected == "money" then text = ns.T("deBuyNoMoney")
    elseif preview.rejected == "threshold" then
        text = s.buyMode == "price" and ns.T("deBuyBelowPrice", K.Money(s.buyPrice)) or ns.T("pmBuyBelow", s.buyPercent)
    else text = ns.T("pmBuyUnknown") end
    if preview.stale and preview.count > 0 then text = ns.T("deBuyStale") .. " | " .. text end
    return text
end
function UI:Render()
    if not self.frame then return end
    local K, P, s = ns.TradeKit, ns.Prospect, self:S()
    local target = s.view == "target"
    local rows = self.sorter:Apply(self:Entries(), {
        item = function(entry) return ns.Markets.Name(entry.id) end,
        skill = function(entry) return entry.source.skill end,
        price = function(entry) return entry.cost end,
        margin = function(entry) return entry.estimate.margin end,
        rate = function(entry) return entry.estimate.percent end,
        via = function(entry) return entry.via and -entry.via or nil end,
        viaRate = function(entry) return entry.viaRate and -entry.viaRate or nil end,
    })
    local groups = P.Groups(self.mode, rows)
    local top = self:Layout()
    local f = self.frame
    local width = (f:GetWidth() or 996) - 300
    local columns = K.DisenchantColumns(width, target, true)
    self.headers.skill:SetText(ns.T("pmColSkill"))
    self.headers.price:SetText(ns.T("pmColCost", P.OPERATION))
    self.headers.via:SetText(ns.T("pmColVia"))
    for key, label in pairs(self.headers) do
        local column = columns[key]
        label:ClearAllPoints()
        if column then
            label:SetPoint("TOPLEFT", f, "TOPLEFT", 10 + column[1] + (key == "item" and 6 or 0), -(top - 18))
            label:SetWidth(column[2] - 6); label:Show()
        else label:Hide() end
    end
    self.sorter:Mark()
    self.headerBand:ClearAllPoints()
    self.headerBand:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -(top - 20))
    self.headerBand:SetPoint("TOPRIGHT", f, "TOPRIGHT", -290, -(top - 20))
    local lines = self:Lines(groups)
    local visible = K.ListCapacity(f, top, 88, 24, #self.rows + #self.groups)
    self.scroll.frame:ClearAllPoints()
    self.scroll.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -top)
    self.scroll.frame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -272, 88)
    self.inspector:Place(-(top - 25))
    self.empty:ClearAllPoints(); self.empty:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -top - 10)
    self.empty:SetWidth(math.max(100, width - 20))
    local offset = self.scroll:SetRange(#lines, visible)
    local selected
    for _, entry in ipairs(rows) do if entry.id == s.selected then selected = entry end end
    if not selected then selected = rows[1]; s.selected = selected and selected.id end
    local options = self:Options()
    local usedRows, usedGroups = 0, 0
    local busy = ns.Buy.Active() or ns.Scan.state.phase ~= "idle"
    for i = 1, visible do
        local line = lines[offset + i]
        if line and line.entry then
            usedRows = usedRows + 1
            local row, entry = self.rows[usedRows], line.entry
            if row then
                row.frame:ClearAllPoints(); row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -top - (i - 1) * 24)
                row:SetProps({id = entry.id, width = width, target = target, level = entry.source.skill,
                    cost = entry.cost, margin = entry.estimate.margin, percent = entry.estimate.percent,
                    via = entry.via, viaRate = entry.viaRate, active = entry.id == s.selected,
                    match = s.buyMode == "price" and entry.unit ~= nil and entry.unit < s.buyPrice
                        or s.buyMode == "margin" and entry.estimate.percent ~= nil and entry.estimate.percent > s.buyPercent,
                    tip = ns.T("pmRowTip", entry.source.skill) .. "\n" .. self:Formula(entry),
                    actionDisabled = busy or not ns.Scan.state.open or entry.unit == nil,
                    refreshDisabled = busy or not ns.Scan.state.open})
            end
        elseif line then
            usedGroups = usedGroups + 1
            local header, group = self.groups[usedGroups], line.group
            if header then
                header.frame:ClearAllPoints(); header.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -top - (i - 1) * 24)
                local ids = {}
                for _, entry in ipairs(group.rows) do ids[#ids + 1] = entry.id end
                header:SetProps({key = group.key, width = width, open = not s.collapsed[group.key], height = 24,
                    name = self:GroupName(group), detail = self:GroupDetail(group), actionWidth = 70,
                    tip = ns.T("pmGroupTip"),
                    actions = {{label = ns.T("tradeUpdate"), width = 62, tip = ns.T("pmGroupRefreshTip"),
                        disabled = busy,
                        fn = function() self:Refresh(P.PriceIDs(self.mode, ids)) end}}})
            end
        end
    end
    for i = usedRows + 1, #self.rows do self.rows[i].frame:Hide() end
    for i = usedGroups + 1, #self.groups do self.groups[i].frame:Hide() end
    self.empty:SetText(#rows == 0 and ns.T(target and "pmEmptyTarget" or "pmEmpty") or "")
    local ids = {}
    for _, entry in ipairs(rows) do ids[#ids + 1] = entry.id end
    local priced, fresh = P.PriceIDs(self.mode, ids), 0
    for _, id in ipairs(priced) do if P.Fresh(id) then fresh = fresh + 1 end end
    self.progress:SetText(#rows > 0 and ns.T("pmResultCount", #rows) or ns.T("pmStartHint"))
    self.status:ClearAllPoints()
    self.status:SetPoint("BOTTOMLEFT", self.progress, "BOTTOMRIGHT", 10, 0)
    self.status:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -276, 64)
    self.status:SetText(ns.T("pmFresh", fresh, #priced))
    if selected then self.inspector:SetProps({id = selected.id}); self.item:Show() else self.inspector:Clear() end
    self:Panel(selected)
    self.preview = selected and P.PurchasePlan(self.mode, selected.id, options)
        or {count = 0, units = 0, cost = 0}
    self.buyPreview:SetText(self:PreviewText(selected))
    K.Tooltip(self.buy, ns.T(s.buyMode == "price" and "deBuyByPrice" or "deBuyByMargin"),
        ns.T("pmBuyContext", selected and ns.Markets.Name(selected.id) or "") .. "\n\n" .. ns.T("pmBuyTip"))
    self:Controls()
end
function UI:NewTable(f)
    local K = ns.TradeKit
    self.headerBand = K.TableHeader(f, -60)
    self.headers = {}
    for _, entry in ipairs({{"item", "pmColItem"}, {"skill", "pmColSkill"}, {"price", "pmColCost"},
        {"margin", "deColMargin"}, {"rate", "deColRate"}, {"via", "pmColVia"}, {"viaRate", "deColViaRate"}}) do
        local label = K.Label(f, ns.T(entry[2], 5), 0, -38, 100)
        label:SetHeight(12)
        if entry[1] ~= "item" then label:SetJustifyH("RIGHT") end
        self.headers[entry[1]] = label
    end
    self.sorter = K.Sorter(f, self.headers, function() self.scroll.offset = 0; self:Render() end)
    for key, tipKey in pairs({skill = "pmColSkillTip", price = "pmColCostTip", margin = "pmColMarginTip",
        rate = "deColRateTip", via = "pmColViaTip", viaRate = "deColViaRateTip"}) do
        local button = self.sorter.buttons[key]
        K.Tooltip(button, ns.T("sortTitle"), ns.T(tipKey) .. "\n\n" .. ns.T("sortTip"))
    end
    self.scroll = K.Scroller:New(f, function() self:Render() end, 24)
    for i = 1, 40 do
        local row = K.DisenchantRow:New(f, function(id) self:S().selected = id; self:Render() end, self.buyRow,
            function(id) self:Refresh(ns.Prospect.PriceIDs(self.mode, {id})) end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -80 - (i - 1) * 24)
        K.Tooltip(row.buy, ns.T("pmBuyRow"), ns.T("pmBuyRowTip"))
        row.frame:Hide(); self.scroll:Wheel(row.frame); self.rows[i] = row
    end
    for i = 1, 12 do
        local header = K.GroupRow:New(f, function(key)
            local collapsed = self:S().collapsed
            collapsed[key] = not collapsed[key] or nil
            self:Render()
        end)
        header.frame:Hide(); self.scroll:Wheel(header.frame); self.groups[i] = header
    end
    self.empty = K.Label(f, "", 10, -90, 400, "secondary"); self.empty:SetHeight(80)
end
function UI:NewBottom(f)
    local K = ns.TradeKit
    self.progress = K.Label(f, "", 10, -34, 230, "secondary")
    self.progress:SetHeight(12)
    self.progress:ClearAllPoints(); self.progress:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 64)
    self.status = K.Label(f, "", 250, -34, 400, "secondary")
    self.status:SetHeight(12)
    self.buyModes = K.Segment(f, {{key = "margin", label = ns.T("buyModeMargin")},
        {key = "price", label = ns.T("buyModePrice")}}, function(mode)
        local s = self:S()
        if s.buyMode == mode then return end
        ns.Prospect.CancelBuy()
        s.buyMode = mode
        self.buyEdit:SetText(mode == "price" and tostring(s.buyPrice / 10000) or tostring(s.buyPercent))
        self:Save(); self:Render()
    end)
    self.buyModes.frame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 6)
    K.Tooltip(self.buyModes.frame, ns.T("buyModePrice"), ns.T("pmBuyTip"))
    self.buyLabel = K.Label(f, ns.T("deBuyThreshold"), 0, 0, 90, "secondary")
    self.buyLabel:SetHeight(12)
    self.buyLabel:ClearAllPoints(); self.buyLabel:SetPoint("LEFT", self.buyModes.frame, "RIGHT", 12, 0)
    self.buyEdit = K.Edit(f, 60)
    self.buyEdit:SetText(tostring(self:S().buyMode == "price" and self:S().buyPrice / 10000 or self:S().buyPercent))
    self.buyEdit:SetPoint("LEFT", self.buyLabel, "RIGHT", 4, 0)
    K.Tooltip(self.buyEdit, ns.T("buyPriceLimit"), ns.T("pmBuyTip"))
    K.LiveEdit(self.buyEdit, function(box)
        local s, value = self:S(), tonumber((box:GetText():gsub(",", ".")))
        if s.buyMode == "price" then
            if value and value >= 0.0001 and value <= 100000 then s.buyPrice = math.floor(value * 10000 + 0.5) end
        elseif value and value > -100 and value <= 1000 then s.buyPercent = value end
        self:Save(); self:Render()
    end)
    self.buyEdit:SetScript("OnEditFocusLost", function(box)
        local s = self:S()
        box:SetText(tostring(s.buyMode == "price" and s.buyPrice / 10000 or s.buyPercent))
    end)
    self.buyUnit = K.Label(f, ns.T("dePercent"), 0, 0, 16, "secondary")
    self.buyUnit:SetHeight(12)
    self.buyUnit:ClearAllPoints(); self.buyUnit:SetPoint("LEFT", self.buyEdit, "RIGHT", 3, 0)
    self.buy = K.Button(f, ns.T("deBuyByMargin"), 170, function() self:Purchase() end, "main")
    self.buy:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    self.buyPreview = K.Label(f, "", 0, 0, 300, "secondary")
    self.buyPreview:SetHeight(12)
    self.buyPreview:ClearAllPoints()
    self.buyPreview:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 40)
    self.buyPreview:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 40)
end
function UI:NewPanel()
    local K = ns.TradeKit
    self.inspector = K.Inspector:New(self.frame)
    local panel = self.inspector.body
    self.item = self.inspector.item
    self.scrollBody = ns.NewFrame("ScrollFrame", "ManaCodeProspectPanelScroll", panel, "UIPanelScrollFrameTemplate")
    self.scrollBody.scrollBarHideable = 1
    self.scrollBody:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -40)
    self.scrollBody:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 4)
    local c = ns.NewFrame("Frame", nil, self.scrollBody)
    c:SetWidth(258); c:SetHeight(360)
    self.scrollBody:SetScrollChild(c)
    c:EnableMouseWheel(true)
    c:SetScript("OnMouseWheel", function(_, delta)
        if ScrollFrameTemplate_OnMouseWheel then ScrollFrameTemplate_OnMouseWheel(self.scrollBody, delta) end
    end)
    self.panelChild = c
    self.note = K.Label(c, "", 12, -4, 234, "secondary")
    self.note:SetHeight(26); self.note:SetJustifyV("TOP")
    local k = ns.NewFrame("Frame", nil, c)
    k:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -30); k:SetWidth(258)
    self.calc, self.calcHeight = k, 330
    k:SetHeight(self.calcHeight)
    self.calcTitle = K.Label(k, ns.T("pmCalcTitle", ns.Prospect.OPERATION), 12, -4, 236, "heading")
    self.outcomes = K.OutcomeList:New(k)
    self.outcomes.frame:ClearAllPoints()
    self.outcomes.frame:SetPoint("TOPLEFT", k, "TOPLEFT", 12, -22)
    self.outcomes.frame:SetWidth(242); self.outcomes.frame:SetHeight(3 * 46)
    self.calcKeys, self.calcValues = {}, {}
    local keys = {"pmCalcGross", "deCalcFee", "pmCalcCost", "deCalcMargin"}
    for i, key in ipairs(keys) do
        local y = -166 - (i - 1) * 13 - (i == 4 and 4 or 0)
        local label = K.Label(k, ns.T(key, 5), 12, y, 120, i == 4 and nil or "secondary")
        label:SetHeight(12)
        local value = K.Label(k, "", 0, 0, 130)
        value:SetHeight(12); value:SetJustifyH("RIGHT")
        value:ClearAllPoints(); value:SetPoint("TOPRIGHT", k, "TOPRIGHT", -4, y)
        if i < 4 then value:SetTextColor(unpack(K.theme.secondary)) end
        self.calcKeys[i], self.calcValues[i] = label, value
    end
    K.Rule(k, -226)
    self.scenarios = {}
    for i, key in ipairs({"deScenarioLow", "deScenarioAverage", "deScenarioHigh"}) do
        local tile = {frame = K.Card(k)}
        tile.frame:SetHeight(40); tile.frame:EnableMouse(true)
        tile.frame:SetPoint("TOPLEFT", k, "TOPLEFT", 12 + (i - 1) * 80, -234)
        tile.frame:SetWidth(76)
        tile.title = K.Label(tile.frame, ns.T(key), 4, -6, 68, "secondary")
        tile.title:SetHeight(12); tile.title:SetJustifyH("CENTER")
        tile.value = K.Label(tile.frame, "", 4, -21, 68)
        tile.value:SetHeight(12); tile.value:SetJustifyH("CENTER")
        K.Tooltip(tile.frame, ns.T("pmScenarios"), ns.T("pmScenarioTip"))
        self.scenarios[i] = tile
    end
    self.profitLabel = K.Label(k, ns.T("deProfitable"), 12, -284, 80, "secondary")
    self.profitLabel:SetHeight(12)
    self.profitValue = K.Label(k, "", 0, 0, 170)
    self.profitValue:SetHeight(12); self.profitValue:SetJustifyH("RIGHT"); self.profitValue:ClearAllPoints()
    self.profitValue:SetPoint("TOPRIGHT", k, "TOPRIGHT", -4, -284)
    self.viaLabel = K.Label(k, "", 12, -298, 110, "secondary")
    self.viaLabel:SetHeight(12)
    self.viaValue = K.Label(k, "", 0, 0, 140)
    self.viaValue:SetHeight(12); self.viaValue:SetJustifyH("RIGHT"); self.viaValue:ClearAllPoints()
    self.viaValue:SetPoint("TOPRIGHT", k, "TOPRIGHT", -4, -298)
    self.netLabel = K.Label(k, "", 12, -312, 130, "secondary")
    self.netLabel:SetHeight(12)
    self.netValue = K.Label(k, "", 0, 0, 110)
    self.netValue:SetHeight(12); self.netValue:SetJustifyH("RIGHT"); self.netValue:ClearAllPoints()
    self.netValue:SetPoint("TOPRIGHT", k, "TOPRIGHT", -4, -312)
    self.summary = K.Label(c, "", 12, -4, 222, "secondary")
    self.summary:SetHeight(300); self.summary:SetJustifyV("TOP")
    local info = K.Button(panel, ns.T("tradeInfo"), 22, function() end, "quiet")
    info:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -44)
    K.Tooltip(info, ns.T("pmModelTitle"), ns.T("pmModelTip"))
end
function UI:New(parent)
    self.buyRow = function(id) self:Purchase(id) end
    self.frame = ns.NewFrame("Frame", nil, parent)
    local f = self.frame; f:SetAllPoints(parent)
    self:NewTop(f)
    self:NewTable(f)
    self:NewBottom(f)
    self:NewPanel()
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render()
    return self
end
