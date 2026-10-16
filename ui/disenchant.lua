local _, ns = ...
local UI = {group = "wrathArmor", fee = 0.05, rows = {}, qualities = {[2] = true},
    selling = {hours = 12, losses = 1}, tail = true, tailPercent = -10, buyPercent = 0}
ns.DisenchantUI = UI
function UI:SelectGroup(key)
    if self.group ~= key then ns.Disenchant.CancelBuy(); ns.Batch.Stop(); self.scroll.offset = 0; self.selected = nil end
    local group = ns.Disenchant.Group(key)
    self.qualities = {}
    for quality = 2, 4 do self.qualities[quality] = ns.Disenchant.HasQuality(group, quality) end
    self.group = key; self:Render()
end
function UI:Controls()
    local phase = ns.Scan.state.phase
    if phase == "idle" and not ns.Buy.Active() then self.scan:Enable() else self.scan:Disable() end
    if phase == "paused" then self.resume:Show() else self.resume:Hide() end
    if phase ~= "idle" or ns.Buy.Active() then self.stop:Show() else self.stop:Hide() end
    local purchase = ns.Disenchant.purchase
    self.buy:SetWidth(purchase and 220 or 160)
    if purchase then
        local count, cost = ns.Buy.Offer()
        self.buy:SetText(ns.Buy.state.phase == "ready" and ns.T("deBuyConfirm", count, ns.TradeKit.Money(cost))
            or ns.T("deBuySearching"))
        if ns.Buy.state.phase == "ready" then self.buy:Enable() else self.buy:Disable() end
    else
        self.buy:SetText(ns.T("deBuyByMargin"))
        if phase == "idle" and not ns.Buy.Active() and self.preview and self.preview.count > 0 then self.buy:Enable() else self.buy:Disable() end
    end
    if phase == "idle" and not ns.Buy.Active() then self.buyEdit:Show(); self.buyLabel:Show()
    else self.buyEdit:Hide(); self.buyLabel:Hide() end
    local ready = phase == "idle" and not ns.Buy.Active()
    for _, control in ipairs({self.tailCheck, self.feeButton, self.duration.frame, self.groupMenu.frame}) do
        if ready then control:Enable() else control:Disable() end
    end
    for _, control in pairs(self.qualityChecks) do if ready then control:Enable() else control:Disable() end end
    for _, edit in ipairs({self.tailEdit, self.lossEdit, self.depositEdit}) do
        edit:EnableMouse(ready); if not ready then edit:ClearFocus() end
    end
end
function UI:ReadSettings()
    local tail, buy = tonumber((self.tailEdit:GetText():gsub(",", "."))), tonumber((self.buyEdit:GetText():gsub(",", ".")))
    if not tail or tail <= -100 or tail > 1000 or not buy or buy <= -100 or buy > 1000 then
        ns.say(ns.T("alchemyInvalidPrice")); return false
    end
    self.tailPercent, self.buyPercent = tail, buy
    return true
end
function UI:NewSettings(parent)
    local K = ns.TradeKit
    self.tailCheck = K.Check(parent, function(value) self.tail = value; self:Render() end)
    self.tailCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -60)
    self.tailCheck:SetChecked(self.tail)
    K.Label(parent, ns.T("deTail"), 28, -64, 102)
    K.Tooltip(self.tailCheck, ns.T("deTail"), ns.T("deTailTip"))
    self.tailEdit = K.Edit(parent, 52); self.tailEdit:SetText(tostring(self.tailPercent))
    self.tailEdit:SetPoint("TOPLEFT", parent, "TOPLEFT", 136, -59)
    self.tailEdit:SetScript("OnEnterPressed", function(edit)
        local value = tonumber((edit:GetText():gsub(",", ".")))
        if value and value > -100 and value <= 1000 then self.tailPercent = value else edit:SetText(tostring(self.tailPercent)) end
        edit:ClearFocus(); self:Render()
    end)
    K.Label(parent, ns.T("dePercent"), 194, -65, 18)
    K.Label(parent, ns.T("deDuration"), 232, -65, 62)
    self.duration = K.Menu(parent, {{key = 12, labelKey = "de12Hours"},
        {key = 24, labelKey = "de24Hours"}, {key = 48, labelKey = "de48Hours"}}, function(hours)
        self.selling.hours = hours; self:Render()
    end)
    self.duration.frame:SetWidth(72); self.duration.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 296, -59)
    K.Label(parent, ns.T("deLosses"), 380, -65, 78)
    self.lossEdit = K.Edit(parent, 36); self.lossEdit:SetText("1")
    self.lossEdit:SetPoint("TOPLEFT", parent, "TOPLEFT", 460, -59)
    self.lossEdit:SetScript("OnEnterPressed", function(edit)
        local value = tonumber(edit:GetText())
        if value and value >= 0 and value <= 100 then self.selling.losses = math.floor(value) end
        edit:SetText(tostring(self.selling.losses)); edit:ClearFocus(); self:Render()
    end)
    K.Tooltip(self.lossEdit, ns.T("deLosses"), ns.T("deDepositTip"))
    K.Label(parent, ns.T("deDepositOverride"), 510, -65, 120)
    self.depositEdit = K.Edit(parent, 70)
    self.depositEdit:SetPoint("TOPLEFT", parent, "TOPLEFT", 634, -59)
    self.depositEdit:SetScript("OnEnterPressed", function(edit)
        local text = edit:GetText():gsub(",", ".")
        local value = tonumber(text)
        if text == "" then self.selling.base = nil
        elseif value and value >= 0 and value <= 10000 then self.selling.base = math.floor(value * 10000 + 0.5) end
        edit:ClearFocus(); self:Render()
    end)
    K.Tooltip(self.depositEdit, ns.T("deDepositOverride"), ns.T("deDepositOverrideTip"))
    self.priceToggle = K.Button(parent, ns.T("dePrices"), 140, function()
        self.pricesExpanded = not self.showPrices; self:Render()
    end, "quiet")
    self.priceToggle:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -90)
    self.priceEditors = {}
    for i = 1, #ns.disenchantMaterials do
        self.priceEditors[i] = K.QuoteEditor:New(parent, ns.Disenchant.SetPrice, function(id)
            ns.Markets.Scan(id); self:Render()
        end)
    end
end
function UI:Prices()
    local ids, K = ns.Disenchant.Materials(self.group), ns.TradeKit
    local width = self.frame:GetWidth() or 996
    local columns = math.max(1, math.floor((width - 20) / 300))
    local cell = math.floor((width - 20) / columns)
    self.showPrices = self.pricesExpanded
    if self.showPrices == nil then self.showPrices = (self.frame:GetHeight() or 510) >= 420 end
    self.priceToggle:SetActive(self.showPrices)
    self.duration.frame:SetText(ns.T("deHours", self.selling.hours))
    for i, editor in ipairs(self.priceEditors) do
        local id = self.showPrices and ids[i]
        if id then
            editor.frame:ClearAllPoints()
            editor.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + ((i - 1) % columns) * cell,
                -118 - math.floor((i - 1) / columns) * 32)
            editor:SetProps({id = id, quote = ns.Disenchant.Quote(id), width = cell - 8,
                disabled = ns.Scan.state.phase ~= "idle" or ns.Buy.Active()})
        else editor.frame:Hide() end
    end
    return (self.showPrices and 118 + math.ceil(#ids / columns) * 32 or 116) + 48
end
function UI:Render()
    if not self.frame then return end
    local K, selected = ns.TradeKit
    local rows = ns.Disenchant.Rows(self.group, self.fee, self.selling)
    local progress = ns.Disenchant.Progress(self.group)
    local progressText
    if progress then
        local pages = progress.pages > 0 and tostring(progress.pages) or "?"
        progressText = progress.stage == "materials"
            and ns.T("deProgressMaterials", progress.index, progress.total, progress.name, progress.page, pages)
            or ns.T("deProgressEquipment", progress.page, pages, progress.lots)
        if progress.paused then progressText = ns.T("deProgressPaused", progressText) end
    end
    local group = ns.Disenchant.Group(self.group)
    self.groupMenu.frame:SetText(ns.T(group.labelKey))
    for quality, box in pairs(self.qualityChecks) do box:SetChecked(ns.Disenchant.HasQuality(group, quality)) end
    local top = self:Prices()
    local width = (self.frame:GetWidth() or 996) - 310
    local columns = K.MarketColumns(width)
    for key, label in pairs(self.headers) do
        label:ClearAllPoints(); label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + columns[key][1], -(top - 20))
        label:SetWidth(columns[key][2])
    end
    self.headerBand:ClearAllPoints()
    self.headerBand:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 8, -(top - 25))
    self.headerBand:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -302, -(top - 25))
    self.progress:ClearAllPoints(); self.progress:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -(top - 43))
    self.progress:SetWidth(width)
    self.progress:SetText(progressText or (#rows > 0 and ns.T("deResultCount", #rows) or ns.T("deStartHint")))
    local visible = K.ListCapacity(self.frame, top, 56, 29, #self.rows)
    self.scroll.frame:ClearAllPoints()
    self.scroll.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -top)
    self.scroll.frame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -280, 56)
    self.inspector:Place(-(top - 43))
    self.empty:ClearAllPoints(); self.empty:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -top - 10)
    local offset = self.scroll:SetRange(#rows, visible)
    for _, entry in ipairs(rows) do if entry.id == self.selected then selected = entry end end
    if not selected then selected = rows[1]; self.selected = selected and selected.id end
    for i, row in ipairs(self.rows) do
        row.frame:ClearAllPoints(); row.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -top - (i - 1) * 29)
        local entry = i <= visible and rows[offset + i]
        if entry then
            row:SetProps({id = entry.id, width = width, quote = {price = entry.cost, units = entry.units},
                margin = entry.estimate.margin, percent = entry.estimate.percent, active = entry.id == self.selected,
                quality = entry.meta.quality or 2,
                detail = ns.T(self.qualityLabels[entry.meta.quality or 2]) .. " | "
                    .. ns.T("deRow", entry.meta.level, entry.meta.skill), extraTip = ns.T("deModelTip")})
            row.refresh:Hide()
        else row.frame:Hide() end
    end
    local scan = ns.Disenchant.Snapshot(self.group)
    local emptyKey = progress and (progress.stage == "materials" and "dePreparingEmpty" or "deSearchingEmpty")
        or (scan and "deFinishedEmpty" or "deEmpty")
    self.empty:SetText(#rows == 0 and ns.T(emptyKey) or "")
    self.status:SetText(progressText or (scan and ns.T("deSnapshot", date("%d.%m %H:%M", scan.t + scan.secs), scan.miss or 0)
        or ns.T("deNotScanned")))
    if scan and scan.deCut and not progress then
        self.status:SetText(ns.T("deCutStatus", scan.deReadPages, scan.dePercent))
    elseif scan and scan.deCutDisabled and not progress then
        self.status:SetText(ns.T("deCutUnavailable"))
    end
    if selected then
        self.inspector:SetProps({id = selected.id}); self.item:Show()
        local estimate, lines = selected.estimate, {}
        for _, output in ipairs(estimate.outputs) do
            lines[#lines + 1] = ns.T("deOutput", output.quantity, ns.Markets.Name(output.id), K.Money(output.price))
        end
        self.summary:SetText(ns.T("deSummary", K.Money(selected.cost), K.Money(estimate.net), K.Money(estimate.margin))
            .. "\n" .. ns.T("deDepositSummary", self.selling.hours, K.Money(estimate.deposit), self.selling.losses, K.Money(estimate.reserve))
            .. "\n\n" .. table.concat(lines, "\n") .. "\n\n" .. ns.T(estimate.fresh and "deFresh" or "deStale"))
    else self.inspector:Clear(); self.summary:SetText(ns.T(progress and "deRunningGuide" or "deIntro")) end
    self.feeButton:SetText(ns.T("tradeFee", math.floor(self.fee * 100 + 0.5)))
    self.preview = ns.Disenchant.PurchasePlan(self.group, {fee = self.fee, selling = self.selling, percent = self.buyPercent})
    self.buyPreview:SetText(ns.T("deBuyPreview", self.preview.count, K.Money(self.preview.cost)))
    if ns.Disenchant.purchase then self.status:SetText(ns.T("deBuyStage", ns.Disenchant.purchase.index,
        #ns.Disenchant.purchase.plan.items, ns.Buy.state.bought, K.Money(ns.Buy.state.spent))) end
    self.summary:SetHeight(math.max(60, (self.inspector.body:GetHeight() or 374) - 94))
    self:Controls()
end
function UI:New(parent)
    local K = ns.TradeKit
    self.frame = ns.NewFrame("Frame", nil, parent)
    local f = self.frame; f:SetAllPoints(parent)
    local entries = {}
    for _, group in ipairs(ns.Disenchant.groups) do
        if group.quality == 2 then entries[#entries + 1] = {key = group.key, labelKey = group.labelKey} end
    end
    self.groupMenu = K.Menu(f, entries, function(key)
        local selection = ns.Disenchant.Selection(key, self.qualities)
        if selection then self:SelectGroup(selection) end
    end)
    self.groupMenu.frame:SetWidth(260); self.groupMenu.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -3)
    self.qualityLabels = {[2] = "deUncommon", [3] = "deRare", [4] = "deEpic"}
    self.qualityChecks = {}
    for quality = 2, 4 do
        local q = quality
        local box = K.Check(f, function(checked)
            self.qualities[q] = checked
            local group = ns.Disenchant.Group(self.group)
            local key = ns.Disenchant.Selection(group.base or group.key, self.qualities)
            if key then self:SelectGroup(key) else self.qualities[q] = true; self:Render() end
        end)
        box:SetPoint("TOPLEFT", f, "TOPLEFT", 8 + (q - 2) * 112, -32)
        K.Label(f, ns.T(self.qualityLabels[q]), 28 + (q - 2) * 112, -36, 88)
        self.qualityChecks[q] = box
    end
    self:NewSettings(f)
    self.scan = K.Button(f, ns.T("scanSelection"), 140, function()
        if not self:ReadSettings() then return end
        ns.Disenchant.Scan(self.group, IsShiftKeyDown(), {fee = self.fee, cut = self.tail,
            percent = self.tailPercent, selling = {hours = self.selling.hours, losses = self.selling.losses, base = self.selling.base}}); self:Render()
    end, "main")
    self.scan:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -5)
    K.Tooltip(self.scan, ns.T("deTitle"), ns.T("deScanTip"))
    self.progress = K.Label(f, "", 10, -34, 400, "heading")
    self.progress:SetHeight(16)
    self.headerBand = K.TableHeader(f, -60)
    self.headers = {}
    for _, entry in ipairs({{"item", "deCandidates"}, {"price", "deBuyPrice"}, {"margin", "deMargin"}, {"units", "tradeUnits"}}) do
        self.headers[entry[1]] = K.Label(f, ns.T(entry[2]), 0, -38, 100)
        if entry[1] ~= "item" then self.headers[entry[1]]:SetJustifyH("RIGHT") end
    end
    self.scroll = K.TableScroll(f, function() self:Render() end, 80, 56, 29)
    for i = 1, 40 do
        local row = K.MarketRow:New(f, function(id) self.selected = id; self:Render() end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -80 - (i - 1) * 29)
        row.frame:SetHeight(28); self.scroll:Wheel(row.frame); self.rows[i] = row
    end
    self.empty = K.Label(f, "", 10, -90, 400); self.empty:SetHeight(80)
    self.status = K.Label(f, "", 0, 0, 400)
    self.status:ClearAllPoints(); self.status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 32)
    self.status:SetHeight(16)
    self.feeButton = K.Button(f, "", 106, function() self.fee = self.fee == 0.05 and 0.15 or 0.05; self:Render() end)
    self.feeButton:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 4)
    self.buy = K.Button(f, ns.T("deBuyByMargin"), 160, function()
        if not self:ReadSettings() then return end
        ns.Disenchant.Purchase(self.group, {fee = self.fee, percent = self.buyPercent,
            selling = {hours = self.selling.hours, losses = self.selling.losses, base = self.selling.base}})
        self:Render()
    end, "main")
    self.buy:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    K.Tooltip(self.buy, ns.T("deBuyByMargin"), ns.T("deBuyTip"))
    self.buyEdit = K.Edit(f, 48); self.buyEdit:SetText(tostring(self.buyPercent))
    self.buyEdit:SetPoint("RIGHT", self.buy, "LEFT", -6, 0)
    self.buyEdit:SetScript("OnEnterPressed", function(edit) self:ReadSettings(); edit:ClearFocus(); self:Render() end)
    self.buyLabel = K.Label(f, ns.T("deBuyThreshold"), 0, 0, 76)
    self.buyLabel:ClearAllPoints(); self.buyLabel:SetPoint("RIGHT", self.buyEdit, "LEFT", -4, 0)
    self.buyPreview = K.Label(f, "", 160, -96, 460)
    self.stop = K.Button(f, ns.T("tradeStop"), 60, function() ns.Disenchant.CancelBuy(); ns.Batch.Stop(); ns.Scan.Stop(); self:Controls() end)
    self.stop:SetPoint("RIGHT", self.buy, "LEFT", -6, 0)
    self.resume = K.Button(f, ns.T("tradeResume"), 92, function() ns.Scan.Start("pages"); self:Controls() end)
    self.resume:SetPoint("RIGHT", self.stop, "LEFT", -6, 0)
    self.inspector = K.Inspector:New(f)
    local panel = self.inspector.body
    self.item = self.inspector.item
    self.summary = K.Label(panel, "", 12, -46, 240)
    self.summary:SetHeight(300); self.summary:SetJustifyV("TOP")
    local info = K.Button(panel, ns.T("tradeInfo"), 24, function() end)
    info:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 12)
    K.Tooltip(info, ns.T("deTitle"), ns.T("deModelTip"))
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render()
    return self
end
