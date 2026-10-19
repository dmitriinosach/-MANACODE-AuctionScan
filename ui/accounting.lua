local _, ns = ...
local UI = {all = {}}
UI.__index = UI
ns.AccountingUI = UI
local PERIODS = {{key = "day", days = 1}, {key = "week", days = 7}, {key = "month", days = 30}, {key = "all"}}
local STAGES = {all = true, wait = {sent = true, unsure = true}, mail = {mail = true}, bag = {bag = true}, done = {done = true}}
local TONE = {sent = "secondary", unsure = "accent", mail = "text", bag = "gold", done = "positive", lost = "negative"}
local ROW = 24
local function gold(value)
    return string.format("%.4f", value / 10000)
end
local function tone(value)
    if not value then return "secondary" end
    return value >= 0 and "positive" or "negative"
end
function UI:SetProps(props)
    for key, value in pairs(props) do self.props[key] = value end
    self.scroll.offset = 0; self:Render()
end
function UI:Result(value, err)
    self.message = value and nil or ns.T(err or "acInvalid")
    self:Render()
    return value and true or false
end
function UI:Form(title, fields, submit, tip)
    local K = ns.TradeKit
    if not self.dialog then
        local dialog = K.Window(UIParent, "", 440, 310)
        self.dialog, self.fields = dialog, {}
        for index = 1, 4 do
            local label = K.Label(dialog, "", 16, -44 - (index - 1) * 48, 400)
            local edit = K.Edit(dialog, 400); edit:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -60 - (index - 1) * 48)
            self.fields[index] = {label = label, edit = edit}
        end
        self.formTip = K.Label(dialog, "", 16, -244, 400, "secondary"); self.formTip:SetHeight(32)
        self.formError = K.Label(dialog, "", 16, 0, 400)
        self.formError:ClearAllPoints(); self.formError:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 16, 42)
        self.formError:SetHeight(30)
        self.formError:SetTextColor(unpack(K.theme.negative))
        self.submit = K.Button(dialog, ns.T("acSave"), 110, function()
            local values = {}
            for index, field in ipairs(self.formFields) do values[field.key] = self.fields[index].edit:GetText() end
            local result, err = self.formSubmit(values)
            if result then dialog:Hide(); self:Result(result) else self.formError:SetText(ns.T(err or "acInvalid")) end
        end, "main")
        self.submit:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -16, 12)
        self.frame:HookScript("OnHide", function() dialog:Hide() end)
    end
    self.formFields, self.formSubmit = fields, submit
    self.dialog.heading:SetText(title)
    for index, widgets in ipairs(self.fields) do
        local field = fields[index]
        if field then
            widgets.label:SetText(ns.T(field.label)); widgets.edit:SetText(field.value or "")
            widgets.label:Show(); widgets.edit:Show()
        else widgets.label:Hide(); widgets.edit:Hide() end
    end
    self.dialog:SetHeight(#fields * 48 + 150)
    self.formTip:ClearAllPoints(); self.formTip:SetPoint("TOPLEFT", self.dialog, "TOPLEFT", 16, -48 - #fields * 48)
    self.formTip:SetText(tip or ""); self.formError:SetText("")
    self.dialog:Show()
end
function UI:Purchase()
    self:Form(ns.T("acAddPurchase"), {{key = "item", label = "acItemInput"}, {key = "count", label = "acQuantity", value = "1"},
        {key = "price", label = "acTotalGold"}}, function(values)
        local link = values.item:find("item:", 1, true) and values.item or nil
        local itemID, suffix = ns.Lot.FromLink(link)
        itemID = itemID or tonumber(values.item)
        local model = itemID and ns.Disenchant.Candidate(itemID, link)
        if not model then return nil, "acItemUnknown" end
        local A = ns.Accounting
        local id, err = A.Buy({itemID = itemID, suffix = suffix, link = link, count = tonumber(values.count),
            cost = A.Price(values.price), level = model.level, quality = model.quality, band = model.band}, "manual")
        if id then A.Receive(id, tonumber(values.count), "manual") end
        return id, err
    end, ns.T("acPurchaseTip"))
end
function UI:Output(chain)
    self:Form(ns.T("acManualDE"), {{key = "item", label = "acMaterialInput"}, {key = "count", label = "acQuantity"}}, function(values)
        local itemID = ns.Lot.FromLink(values.item) or tonumber(values.item)
        return ns.Accounting.Disenchant(chain.id, {{itemID = itemID, count = tonumber(values.count)}}, "manual")
    end, ns.T("acManualDETip"))
end
function UI:Sale(material)
    local A, itemID = ns.Accounting, material.itemID
    self:Form(ns.T("acAddSale"), {
        {key = "count", label = "acQuantity", value = tostring(material.remaining)},
        {key = "gross", label = "acTotalGold"},
        {key = "fee", label = "acFeeGold"},
    }, function(values)
        local gross = A.Price(values.gross)
        local fee = values.fee:match("^%s*$") and gross and math.floor(gross * (A.Book().fee or 0.05)) or A.Price(values.fee)
        return A.Sell({itemID = itemID, count = tonumber(values.count), gross = gross, fee = fee}, "manual")
    end, ns.T("acSaleTip"))
end
function UI:SaleCount(sale)
    self:Form(ns.T("acSaleCount"), {{key = "count", label = "acQuantity"}}, function(values)
        return ns.Accounting.SaleCount(sale.id, tonumber(values.count))
    end, ns.T("acSaleCountTip", ns.Markets.Name(sale.itemID), ns.TradeKit.Money(sale.gross)))
end
function UI:Since()
    for _, period in ipairs(PERIODS) do
        if period.key == self.props.period and period.days then return time() - period.days * 86400 end
    end
    return 0
end
function UI:ChainCells(chain, fee)
    local K, D = ns.TradeKit, ns.Disenchant
    local cells = {stage = {ns.T("acStage_" .. chain.stage), TONE[chain.stage]}, cost = {K.Money(chain.cost)},
        when = {date("%d.%m %H:%M", chain.at), "secondary"}}
    if chain.stage == "done" then
        cells.market = {chain.gross and K.Money(chain.gross) or ns.T("tradeNoPrice"), chain.gross and "text" or "secondary"}
        cells.net = {chain.value and K.Money(chain.value) or ns.T("tradeNoPrice"), "secondary"}
        if chain.result then cells.result = {K.Money(chain.result), tone(chain.result)} end
    else
        local band = chain.band and D.Band(chain.band)
        local estimate = band and D.Estimate(band, chain.cost, fee, nil, ns.Accounting.Selling())
        if estimate and estimate.net then
            cells.market = {"~" .. K.Money(estimate.gross), "secondary"}
            cells.net = {"~" .. K.Money(estimate.net), "secondary"}
            cells.result = {"~" .. K.Money(estimate.margin), "secondary"}
        end
    end
    return cells
end
local function outputs(chain)
    if next(chain.outputs) == nil then return nil end
    local list = {}
    for id, count in pairs(chain.outputs) do list[#list + 1] = {id = id, count = count} end
    table.sort(list, function(a, b) return a.count > b.count end)
    return list
end
local function chainTip(chain, fee)
    local K = ns.TradeKit
    local tip = ns.T("acChainTip", chain.level or 0, chain.count, chain.received, chain.processed,
        ns.T("acSource_" .. (chain.source or "manual")))
    if chain.gross then
        local lines = {}
        for id, count in pairs(chain.outputs) do
            local price = ns.Accounting.Market(id)
            lines[#lines + 1] = ns.T("acOutputLine", ns.Markets.Name(id), count, K.Money(price), K.Money(price and price * count))
        end
        tip = tip .. "\n\n" .. table.concat(lines, "\n") .. "\n" .. ns.T("acChainMath", K.Money(chain.gross),
            math.floor(fee * 100 + 0.5), K.Money(chain.gross * fee), K.Money(chain.reserve), K.Money(chain.value),
            K.Money(chain.cost), K.Money(chain.result))
    end
    return tip
end
function UI:ChainActions(chain)
    local A, actions = ns.Accounting, {}
    if chain.stage == "sent" or chain.stage == "unsure" then
        actions[1] = {label = ns.T("acWon"), tip = ns.T("acWonTip"), fn = function() self:Result(A.Resolve(chain.id, true, "manual")) end}
        actions[2] = {label = ns.T("acLost"), tip = ns.T("acLostTip"), fn = function() self:Result(A.Resolve(chain.id, false, "manual")) end}
    elseif chain.stage == "mail" then
        actions[1] = {label = ns.T("acReceive"), tip = ns.T("acReceiveTip"),
            fn = function() self:Result(A.Receive(chain.id, chain.count - chain.received, "manual")) end}
    elseif chain.stage == "bag" then
        actions[1] = {label = ns.T("acOutputButton"), tip = ns.T("acManualDETip"), fn = function() self:Output(chain) end}
    end
    if chain.processed == 0 then
        actions[#actions + 1] = {label = ns.T("acRemove"), tip = ns.T("acRemoveTip"), fn = function() self:Result(A.Reverse(chain.id)) end}
    end
    return actions
end
function UI:Items(p, fee, since)
    local K, allowed = ns.TradeKit, STAGES[self.props.stage] or true
    local groups, order = {}, {}
    for i = #p.chains, 1, -1 do
        local chain = p.chains[i]
        if chain.at >= since and chain.stage ~= "lost" and (allowed == true or allowed[chain.stage]) then
            local key = chain.itemID .. ":" .. chain.suffix
            if not groups[key] then groups[key] = {key = key, chains = {}}; order[#order + 1] = groups[key] end
            local list = groups[key].chains
            list[#list + 1] = chain
        end
    end
    local lines = {}
    for _, group in ipairs(order) do
        local first = group.chains[1]
        local open = not self.closed[group.key]
        if #group.chains > 1 then
            local cost, value, units, known, done = 0, 0, 0, true, 0
            for _, chain in ipairs(group.chains) do
                cost, units = cost + chain.cost, units + chain.count
                if chain.stage == "done" then
                    done = done + 1
                    if chain.value then value = value + chain.value else known = false end
                end
            end
            local result = known and done == #group.chains and value - cost or nil
            lines[#lines + 1] = {group = true, key = group.key, open = open,
                name = ns.Markets.Name(first.itemID),
                detail = ns.T("acGroupDetail", units, K.Money(cost), done, #group.chains),
                tag = result and K.Money(result) or "", tone = tone(result)}
        end
        if open or #group.chains == 1 then
            for _, chain in ipairs(group.chains) do
                lines[#lines + 1] = {key = chain.id, id = chain.itemID, link = chain.link, quality = chain.quality,
                    mode = "items", cells = self:ChainCells(chain, fee), icons = outputs(chain),
                    actions = self:ChainActions(chain), tip = chainTip(chain, fee)}
            end
        end
    end
    return lines
end
function UI:Analysis(p)
    local K, lines = ns.TradeKit, {}
    for _, g in ipairs(ns.Accounting.Analysis(p, self.props.by)) do
        local title
        if self.props.by == "level" then title = ns.T("acByLevelTitle", g.key)
        elseif self.props.by == "band" then
            local band = ns.Disenchant.Band(g.key)
            local kind = band and ns.DisenchantUI and ns.DisenchantUI.BandKind and ns.DisenchantUI.BandKind(band)
            title = band and kind and ns.T("deBandHeader", kind, band.minLevel, band.maxLevel) or tostring(g.key)
        end
        local units = g.main and ns.T("acUnitsValue", (string.format("%.1f", g.units / g.count):gsub("%.", ",")),
            (string.format("%.1f", g.expectedUnits / g.count):gsub("%.", ",")), ns.Markets.Name(g.main)) or ""
        local notes = {}
        if g.count < 5 then notes[#notes + 1] = ns.T("acFewSamples") end
        if g.crafted then notes[#notes + 1] = ns.T("acCrafted") end
        lines[#lines + 1] = {key = "a" .. tostring(g.key), id = self.props.by == "item" and g.itemID or nil, title = title,
            mode = "analysis",
            cells = {count = {tostring(g.count)}, cost = {K.Money(g.cost / g.count), "secondary"},
                units = {units, "secondary"},
                expected = {g.known and K.Money(g.expected / g.count) or ns.T("tradeNoPrice"), "secondary"},
                gross = {K.Money(g.gross / g.count)},
                luck = {g.luck and string.format("%d%%", math.floor(g.luck + 0.5)) or "",
                    g.luck and (g.luck >= 100 and "positive" or "negative") or "secondary"},
                result = {K.Money(g.result), tone(g.result)}},
            tip = ns.T("acAnalysisTip") .. (#notes > 0 and ("\n\n" .. table.concat(notes, "\n")) or "")}
    end
    return lines
end
function UI:Materials(p)
    local K, lines, list = ns.TradeKit, {}, {}
    for _, m in pairs(p.materials) do list[#list + 1] = m end
    table.sort(list, function(a, b)
        if (a.remaining > 0) ~= (b.remaining > 0) then return a.remaining > 0 end
        return a.itemID < b.itemID
    end)
    for _, m in ipairs(list) do
        local unit = m.remaining > 0 and not m.unknownCost and m.cost / m.remaining or nil
        lines[#lines + 1] = {key = "m" .. m.itemID, id = m.itemID, mode = "materials", model = m,
            cells = {stock = {tostring(m.remaining)}, posted = {m.posted > 0 and tostring(m.posted) or "", "gold"},
                unit = {unit and K.Money(unit) or (m.remaining > 0 and "?" or ""), "secondary"},
                market = {m.price and K.Money(m.price) or ns.T("tradeNoPrice"), m.price and "text" or "secondary"},
                value = {m.value and K.Money(m.value) or ""},
                sold = {m.sold > 0 and tostring(m.sold) or "", "secondary"},
                net = {m.net > 0 and K.Money(m.net) or "", m.net > 0 and tone(m.net - m.soldCost) or "secondary"}},
            actions = {
                {label = ns.T("acMarket"), tip = ns.T("acMarketTip"), fn = function() ns.MarketWindow.Open(m.itemID) end},
                m.remaining > 0 and {label = ns.T("acSaleButton"), tip = ns.T("acSaleTip"), fn = function() self:Sale(m) end} or nil,
            },
            tip = ns.T("acMaterialTip", m.received, m.sold, m.remaining, m.posted)}
    end
    return lines
end
function UI:Journal(p, since)
    local K, A, lines = ns.TradeKit, ns.Accounting, {}
    for i = #p.journal, 1, -1 do
        local event = p.journal[i]
        if event.at >= since then
            local target = event.target and p.byEvent[event.target]
            local itemID = event.itemID or (target and (target.itemID or (target.target and p.byEvent[target.target]
                and p.byEvent[target.target].itemID)))
            local amount = event.cost or event.gross
            local actions = {}
            if A.Reversible(p, event) then
                actions[1] = {label = ns.T("acUndo"), tip = ns.T("acUndoTip"), fn = function() self:Result(A.Reverse(event.id)) end}
            end
            local sale = event.kind == "sale" and p.bySale[event.id]
            if sale and not sale.count then
                actions[#actions + 1] = {label = ns.T("acSaleCountButton"), tip = ns.T("acSaleCountButtonTip"),
                    fn = function() self:SaleCount(sale) end}
            end
            local label = ns.T("acEvent_" .. event.kind)
            if event.kind == "sale" or event.kind == "disenchant" or event.kind == "post" then
                local count = event.count or (event.stack and event.stack * event.stacks)
                if event.outputs then
                    count = 0
                    for _, output in ipairs(event.outputs) do count = count + output.count end
                end
                if count then label = label .. " x" .. count elseif sale then label = label .. " x?" end
            end
            lines[#lines + 1] = {key = "e" .. event.id, id = itemID, title = itemID and nil or label, mode = "journal",
                cells = {event = {label, p.reversed[event.id] and "off" or "text"},
                    amount = {amount and K.Money(amount) or "", p.reversed[event.id] and "off" or "text"},
                    source = {ns.T("acSource_" .. (event.source or "manual")), "secondary"},
                    when = {date("%d.%m %H:%M", event.at), "secondary"}},
                actions = actions,
                tip = p.reversed[event.id] and ns.T("acReversed") or nil}
        end
    end
    return lines
end
function UI:Render()
    if not self.frame or not self.frame:IsVisible() then return end
    local A, K = ns.Accounting, ns.TradeKit
    local since = self:Since()
    local p = A.Project(nil, since)
    local fee = A.Book().fee or 0.05
    self.model = p
    local width = self.frame:GetWidth() or 780
    self.periods:Select(self.props.period)
    self.fee:Select(fee == 0.15 and 15 or 5)
    self.views:Select(self.props.mode)
    local tileWidth = (width - 20 - 18) / 4
    local holdingNote = ns.T("acHoldingNote", p.holdingCount, p.stages.mail, p.stages.bag)
    local tiles = {
        {"acHolding", K.Money(p.holding), holdingNote, "secondary"},
        {"acStock", p.unknownStock and p.stockValue == 0 and ns.T("tradeNoPrice") or K.Money(p.stockValue),
            ns.T("acStockNote", K.Money(p.stockCost)), "secondary"},
        {"acSold", K.Money(p.net), ns.T("acSoldNote", K.Money(p.realized)), tone(p.realized)},
        {"acForecast", p.forecast and K.Money(p.forecast) or ns.T("acIncomplete"),
            ns.T(p.forecast and "acForecastNote" or "acForecastMissing"), p.forecast and tone(p.forecast) or "secondary"},
    }
    for index, values in ipairs(tiles) do
        local tile = self.tiles[index]
        tile.frame:ClearAllPoints()
        tile.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + (index - 1) * (tileWidth + 6), -32)
        tile:SetProps({title = ns.T(values[1]), value = values[2], note = values[3], tone = values[4],
            width = tileWidth, tip = ns.T(values[1] .. "Tip")})
    end
    local items = self.props.mode == "items"
    for key, button in pairs(self.stages.buttons) do
        local count = 0
        if key == "all" then
            for stage, n in pairs(p.stages) do if stage ~= "lost" then count = count + n end end
        else for stage in pairs(STAGES[key]) do count = count + p.stages[stage] end end
        button:SetText(ns.T("acStageFilter_" .. key, count))
    end
    self.stages:Select(self.props.stage)
    if items then self.stages.frame:Show() else self.stages.frame:Hide() end
    self.groupBy:Select(self.props.by)
    if self.props.mode == "analysis" then self.groupBy.frame:Show() else self.groupBy.frame:Hide() end
    local inner = width - 20 - 18
    local lines
    if items then lines = self:Items(p, fee, since)
    elseif self.props.mode == "materials" then lines = self:Materials(p)
    elseif self.props.mode == "analysis" then lines = self:Analysis(p)
    else lines = self:Journal(p, since) end
    local hasActions = false
    for _, line in ipairs(lines) do if line.actions and #line.actions > 0 then hasActions = true end end
    local columns = K.LedgerColumns(inner, self.props.mode, hasActions)
    for key, label in pairs(self.headers) do
        local column = columns[key]
        label:ClearAllPoints()
        if column then
            label:SetPoint("LEFT", self.headBand, "LEFT", key == "item" and 32 or column[1], 0)
            label:SetWidth(key == "item" and column[2] - 34 or column[2] - 6)
            label:SetText(ns.T("acCol_" .. self.props.mode .. "_" .. key))
            label:Show()
        else label:Hide() end
    end
    local visible = K.ListCapacity(self.frame, 150, 30, ROW, #self.rows)
    local offset = self.scroll:SetRange(#lines, visible)
    local rowIndex, groupIndex = 0, 0
    for _, row in ipairs(self.rows) do row.frame:Hide() end
    for _, group in ipairs(self.groups) do group.frame:Hide() end
    for index = 1, math.min(visible, #lines - offset) do
        local line = lines[offset + index]
        local y = -150 - (index - 1) * ROW
        local widget
        if line.group then
            groupIndex = groupIndex + 1
            widget = self.groups[groupIndex]
            if widget then
                widget:SetProps({key = line.key, name = line.name, detail = line.detail, tag = line.tag, tone = line.tone,
                    open = line.open, width = inner, height = ROW})
            end
        else
            rowIndex = rowIndex + 1
            widget = self.rows[rowIndex]
            if widget then
                line.width, line.active, line.hasActions = inner, line.key == self.selected, hasActions
                widget:SetProps(line)
            end
        end
        if widget then
            widget.frame:ClearAllPoints(); widget.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, y)
            widget.frame:Show()
        end
    end
    self.empty:SetWidth(width - 40)
    self.empty:SetText(#lines == 0 and ns.T("acEmpty_" .. self.props.mode) or "")
    local hint = self.message
    if not hint and p.unknownSales > 0 then hint = ns.T("acUnknownSales", p.unknownSales) end
    if not hint and p.stages.unsure > 0 then hint = ns.T("acUnsureHint", p.stages.unsure) end
    self.status:SetWidth(width - 20)
    self.status:SetText(hint or ns.T("acHint"))
    if hint and hint == self.message then self.status:SetTextColor(unpack(K.theme.negative))
    else self.status:SetTextColor(unpack(K.theme.secondary)) end
end
function UI:New(parent)
    local K = ns.TradeKit
    local view = setmetatable({props = {mode = "items", period = "all", stage = "all", by = "item"}, rows = {}, groups = {},
        tiles = {}, headers = {}, closed = {}}, self)
    local f = ns.NewFrame("Frame", nil, parent); f:SetAllPoints(parent); view.frame = f
    local periods = {}
    for _, period in ipairs(PERIODS) do periods[#periods + 1] = {key = period.key, label = ns.T("acPeriod_" .. period.key)} end
    view.periods = K.Segment(f, periods, function(key) view:SetProps({period = key}) end)
    view.periods.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -4)
    view.fee = K.Segment(f, {{key = 5, label = ns.T("acFeeRate", 5)}, {key = 15, label = ns.T("acFeeRate", 15)}}, function(key)
        ns.Accounting.SetFee(key / 100)
    end)
    view.fee.frame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -4)
    K.Tooltip(view.fee.frame, ns.T("acFeeTitle"), ns.T("acFeeTip"))
    view.add = K.Button(f, ns.T("acAddPurchase"), 130, function() view:Purchase() end, "quiet")
    view.add:SetHeight(22)
    view.add:SetPoint("RIGHT", view.fee.frame, "LEFT", -8, 0)
    K.Tooltip(view.add, ns.T("acAddPurchase"), ns.T("acAddPurchaseTip"))
    for index = 1, 4 do view.tiles[index] = K.StatTile:New(f) end
    local modes = {}
    for _, mode in ipairs({"items", "materials", "journal", "analysis"}) do modes[#modes + 1] = {key = mode, label = ns.T("acTab_" .. mode)} end
    view.views = K.Segment(f, modes, function(key) view:SetProps({mode = key}) end)
    view.views.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -96)
    local stages = {}
    for _, key in ipairs({"all", "wait", "mail", "bag", "done"}) do
        stages[#stages + 1] = {key = key, label = ns.T("acStageFilter_" .. key, 888)}
    end
    view.stages = K.Segment(f, stages, function(key) view:SetProps({stage = key}) end)
    view.stages.frame:SetPoint("LEFT", view.views.frame, "RIGHT", 12, 0)
    view.groupBy = K.Segment(f, {{key = "item", label = ns.T("acBy_item")}, {key = "level", label = ns.T("acBy_level")},
        {key = "band", label = ns.T("acBy_band")}}, function(key) view:SetProps({by = key}) end)
    view.groupBy.frame:SetPoint("LEFT", view.views.frame, "RIGHT", 12, 0)
    K.Tooltip(view.groupBy.frame, ns.T("acTab_analysis"), ns.T("acAnalysisTip"))
    local head = ns.NewFrame("Frame", nil, f)
    head:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -124)
    head:SetPoint("TOPRIGHT", f, "TOPRIGHT", -28, -124)
    head:SetHeight(22)
    K.HeaderBand(head)
    view.headBand = head
    for _, key in ipairs({"item", "stage", "cost", "output", "value", "result", "when", "stock", "posted", "unit",
        "market", "sold", "net", "event", "amount", "source", "count", "units", "expected", "gross", "luck"}) do
        local label = K.Label(head, "", 0, -5, 80, "secondary")
        label:SetHeight(12)
        if key ~= "item" and key ~= "output" then label:SetJustifyH("RIGHT") end
        view.headers[key] = label
    end
    view.scroll = K.Scroller:New(f, function() view:Render() end, ROW)
    view.scroll.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -150)
    view.scroll.frame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 30)
    for index = 1, 40 do
        local row = K.LedgerRow:New(f, function(key) view.selected = key; view.message = nil; view:Render() end)
        view.scroll:Wheel(row.frame); view.rows[index] = row
        row.frame:Hide()
    end
    for index = 1, 20 do
        local group = K.GroupRow:New(f, function(key) view.closed[key] = not view.closed[key]; view:Render() end)
        view.scroll:Wheel(group.frame); view.groups[index] = group
        group.frame:Hide()
    end
    view.empty = K.Label(f, "", 20, -160, 600, "secondary"); view.empty:SetHeight(60)
    view.status = K.Label(f, "", 10, 0, 700, "secondary")
    view.status:ClearAllPoints(); view.status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 8); view.status:SetHeight(16)
    f:SetScript("OnSizeChanged", function() view:Render() end)
    f:SetScript("OnShow", function() view:Render() end)
    self.all[#self.all + 1] = view
    view:Render(); return view
end
function UI.Open()
    if not UI.window then
        local width = math.min(1040, (UIParent:GetWidth() or 1080) - 40)
        local height = math.min(620, (UIParent:GetHeight() or 700) - 60)
        local window = ns.TradeKit.Window(UIParent, ns.T("acTitle"), width, height)
        UI.window = window
        local content = ns.NewFrame("Frame", nil, window)
        content:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -40)
        content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -10, 10)
        UI.standalone = UI:New(content)
    end
    UI.window:Show(); UI.standalone:Render()
end
ns.Accounting.onChange = function()
    for _, view in ipairs(UI.all) do if view.frame:IsVisible() then view:Render() end end
    if ns.MarketBoardUI then ns.MarketBoardUI.Refresh() end
end
