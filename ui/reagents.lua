local _, ns = ...
local UI = {props = {id = 36905, page = 1}, rows = {}, bagRows = {}, scope = "all", drafts = {}}
ns.ReagentsUI = UI
local BAG_ROW = 26
local function gold(copper)
    if not copper then return "" end
    local text = string.format("%.4f", copper / 10000):gsub("0+$", ""):gsub("%.$", "")
    return text
end
function UI:SetProps(props)
    if props.id and props.id ~= self.props.id and self.scope == "all" then
        if self.scroll then self.scroll.offset = 0 end
    end
    for key, value in pairs(props) do if key ~= "fee" then self.props[key] = value end end
    self:Render()
end
function UI:Draft(id)
    local draft = self.drafts[id]
    if not draft then
        draft = {mode = "under", hours = 24}
        self.drafts[id] = draft
    end
    return draft
end
function UI:State()
    local d = self:Draft(self.props.id)
    return {fee = ns.Fee(), mode = d.mode, price = d.price, size = d.size, lots = d.lots, hours = d.hours}
end
function UI:Controls()
    if not self.frame then return end
    local phase = ns.Scan.state.phase
    if phase == "idle" and not ns.Buy.Active() then self.scan:Enable() else self.scan:Disable() end
    if ns.vendorPrices[self.props.id] then self.buy:Disable() else self.buy:Enable() end
    if ns.Crafting.byItem[self.props.id] then self.obtain:Show() else self.obtain:Hide() end
end
function UI:SetScope(scope)
    self.scope = scope
    if self.scroll then self.scroll.offset = 0 end
    if scope == "bags" then
        local rows = ns.Reagents.BagItems(ns.Fee())
        local present = false
        for _, row in ipairs(rows) do if row.id == self.props.id then present = true end end
        if not present and rows[1] then self.props.id = rows[1].id end
    end
    self:Render()
end
function UI:RenderUses()
    local K, p = ns.TradeKit, self.props
    local packs = self.mode == "packs"
    local uses, items = packs and ns.Reagents.Packs(p.id, ns.Fee()) or ns.Reagents.Uses(p.id, ns.Fee()), ns.Reagents.Items()
    local function quote(id) return ns.Markets.Quote(id) end
    uses = self.sorter:Apply(uses, {
        item = function(use) return ns.Markets.Name(packs and use.raw or use.recipe.raw) end,
        price = function(use)
            if packs then return use.price end
            local q = quote(use.recipe.raw); return q and q.price
        end,
        margin = function(use) if packs then return use.premium end return use.gain end,
        units = function(use)
            if packs then return use.lots end
            local q = quote(use.recipe.raw); return q and q.units
        end,
    })
    self.sorter:Mark()
    self.viewMenu.frame:SetText(ns.T(packs and "reagentPacks" or "professionCrafts"))
    self.headers.item:SetText(ns.T(packs and "packRecipe" or "reagentRecipes"))
    self.headers.price:SetText(ns.T(packs and "packPrice" or "tradeUnitPrice"))
    self.headers.margin:SetText(ns.T(packs and "packPremium" or "reagentGain"))
    self.headers.units:SetText(ns.T(packs and "packLots" or "tradeUnits"))
    local width = (self.frame:GetWidth() or 996) - 310
    local columns = K.MarketColumns(width)
    self.picker:SetProps({families = items, raw = p.id, headingKey = "reagentsSection"})
    for key, label in pairs(self.headers) do
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + columns[key][1], -38)
        label:SetWidth(columns[key][2])
    end
    local visible = K.ListCapacity(self.frame, 56, 56, 29, #self.rows)
    local offset = self.scroll:SetRange(#uses, visible)
    for i, row in ipairs(self.rows) do
        local use = i <= visible and uses[offset + i]
        if use then
            if packs then
                row:SetProps({id = use.raw, quote = {price = use.price, units = use.lots}, width = width,
                    margin = use.premium, detail = ns.T("packDetail", use.count, use.needed, K.Money(use.net)),
                    extraTip = ns.T("packTip", ns.Markets.Name(p.id), use.count)})
            else
                local recipe = use.recipe
                local detail = ns.T("reagentUse", use.count, ns.T(ns.craftCatalogs[recipe.profession].labelKey))
                row:SetProps({id = recipe.raw, quote = ns.Markets.Quote(recipe.raw), width = width,
                    margin = use.gain, detail = detail})
            end
        else row.frame:Hide() end
    end
    self.empty:SetText(#uses == 0 and ns.T("reagentNoUses") or "")
    return uses
end
function UI:RenderBags()
    local K, p = ns.TradeKit, self.props
    local rows = ns.Reagents.BagItems(ns.Fee())
    rows = self.bagSorter:Apply(rows, {
        item = function(row) return ns.Markets.Name(row.id) end,
        count = function(row) return row.count end,
        cost = function(row) return row.cost end,
        market = function(row) return row.market end,
        value = function(row) return row.value end,
        posted = function(row) return row.posted end,
    })
    self.bagSorter:Mark()
    local width = (self.frame:GetWidth() or 996) - 310
    local columns = K.BagColumns(width)
    for key, label in pairs(self.bagHeaders) do
        local column = columns[key]
        label:ClearAllPoints()
        if column then
            label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + column[1] + (key == "item" and 6 or 0), -38)
            label:SetWidth(column[2] - 6); label:Show()
        else label:Hide() end
    end
    local visible = K.ListCapacity(self.frame, 56, 56, BAG_ROW, #self.bagRows)
    local offset = self.scroll:SetRange(#rows, visible)
    for i, widget in ipairs(self.bagRows) do
        local row = i <= visible and rows[offset + i]
        if row then
            local cells = {count = {tostring(row.count)},
                cost = {row.cost and K.Money(row.cost) or ns.T("tradeNoPrice"), row.cost and "text" or "secondary"},
                market = {K.Money(row.market), row.market and "text" or "secondary"},
                value = {K.Money(row.value), row.value and "text" or "secondary"},
                posted = {row.posted > 0 and tostring(row.posted) or "", "gold"}}
            widget.frame:ClearAllPoints()
            widget.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -56 - (i - 1) * BAG_ROW)
            widget:SetProps({id = row.id, width = width, cells = cells, active = row.id == p.id,
                tip = ns.T("matBagTip")})
        else widget.frame:Hide() end
    end
    self.empty:SetText(#rows == 0 and ns.T("matBagsEmpty") or "")
    return rows
end
function UI:Options()
    local K, p = ns.TradeKit, self.props
    local options = ns.Reagents.Options(p.id, ns.Fee())
    local q = ns.Markets.Quote(p.id)
    local names = {}
    local sell, craft, recycle = options[1], options[2], options[3]
    names[1] = {ns.T("matSell"), sell.value and ns.T("matSellDetail", K.Money(q and q.price)) or ns.T("reagentNoPrice")}
    names[2] = {ns.T("matCraft"), craft.recipe and ns.T("matCraftDetail", ns.Markets.Name(craft.recipe.raw), craft.count)
        or ns.T("matNoCraft")}
    local pair = recycle.pair
    local detail = ns.T("matNoRecycle")
    if pair then
        if p.id == pair.big then
            detail = pair.both and ns.T("matSplitDetail", pair.ratio, ns.Markets.Name(pair.small)) or ns.T("matOneWay")
        else detail = ns.T("matAssembleDetail", pair.ratio, ns.Markets.Name(pair.big)) end
    end
    names[3] = {ns.T("matRecycle"), detail}
    for i, option in ipairs(options) do
        local row = self.optionRows[i]
        row.label:SetText(names[i][1] .. (option.best and ns.T("matBestMark") or ""))
        row.detail:SetText(names[i][2])
        row.value:SetText(option.value and K.Money(option.value) or ns.T("tradeNoPrice"))
        row.value:SetTextColor(unpack(K.theme[option.best and "positive" or (option.value and "text" or "secondary")]))
    end
end
function UI:Posting()
    local K, p, P = ns.TradeKit, self.props, ns.Posting
    local d = self:Draft(p.id)
    local state = self:State()
    state.have = P.Have(p.id)
    local plan = P.Evaluate(p.id, state)
    self.plan = plan
    local wall = plan.wall
    self.stock:SetText(ns.T("postHave", plan.have))
    if wall.lowest then
        self.wall1:SetText(ns.T("postWall", wall.lots, wall.units, K.Money(wall.lowest)))
        self.wall2:SetText(plan.unit and ns.T("postAhead", plan.ahead[1], plan.ahead[2]) or "")
    else
        self.wall1:SetText(ns.T("postWallEmpty")); self.wall2:SetText("")
    end
    if not self.priceEdit:HasFocus() then self.priceEdit:SetText(gold(plan.unit)) end
    self.priceNote:SetText(d.price and ns.T("postOwnPrice") or ns.T("postSuggested"))
    self.modeSegment:Select(d.mode)
    self.hoursSegment:Select(d.hours)
    local floorText = plan.floor and ns.T("postFloor", K.Money(plan.floor)) or ns.T("postNoCost")
    if plan.floor and plan.raised then floorText = floorText .. ns.T("postRaised") end
    self.floor:SetText(floorText)
    self.floor:SetTextColor(unpack(K.theme[plan.below and "negative" or "secondary"]))
    if not self.sizeEdit:HasFocus() then self.sizeEdit:SetText(tostring(plan.size)) end
    if not self.lotsEdit:HasFocus() then self.lotsEdit:SetText(tostring(plan.lots)) end
    local hint = ns.T("postSize_" .. plan.reason, P.StackLimit(p.id))
    self.sizeHint:SetText(hint)
    self.buyout:SetText(K.Money(plan.buyout))
    self.net:SetText(K.Money(plan.net))
    self.profit:SetText(plan.profit and K.Money(plan.profit) or ns.T("postNoCostShort"))
    self.profit:SetTextColor(unpack(K.theme[plan.profit and (plan.profit >= 0 and "positive" or "negative") or "secondary"]))
    self.total:SetText(plan.total and ns.T("postTotal", plan.lots, K.Money(plan.total)) or "")
    local open = P.Open()
    if open and not plan.err then self.post:Enable() else self.post:Disable() end
    local note = ""
    if not open then note = ns.T("postNoAuction")
    elseif plan.err then note = ns.T(plan.err)
    elseif P.pending and P.pending.id == p.id then note = ns.T("postSent", P.pending.size, K.Money(P.pending.buyout))
    elseif P.last and P.last.id == p.id then note = ns.T("postDone", P.last.size, K.Money(P.last.buyout)) end
    self.note:SetText(note)
end
function UI:Post()
    local P = ns.Posting
    local state = self:State()
    state.have = P.Have(self.props.id)
    local plan = P.Evaluate(self.props.id, state)
    local ok, err = P.Post(plan)
    if not ok then
        self.note:SetText(ns.T(err))
        return
    end
    local d = self:Draft(self.props.id)
    if d.lots then d.lots = math.max(1, d.lots - 1) end
    P.last = nil
    self:Render()
end
function UI:Render()
    if not self.frame then return end
    local K, p = ns.TradeKit, self.props
    local bags = self.scope == "bags"
    local packs = self.mode == "packs"
    self.scopeSegment:Select(self.scope)
    for _, widget in ipairs({self.viewMenu.frame, self.picker.frame}) do
        if bags then widget:Hide() else widget:Show() end
    end
    for _, label in pairs(self.headers) do if bags then label:Hide() else label:Show() end end
    for _, label in pairs(self.bagHeaders) do if not bags then label:Hide() end end
    for _, row in ipairs(bags and self.rows or self.bagRows) do row.frame:Hide() end
    local count
    if bags then
        count = #self:RenderBags()
        self.sorter:Mark()
        self.scan:SetText(ns.T("matScanBags"))
    else
        local uses = self:RenderUses()
        count = #uses
        self.bagSorter:Mark()
        self.scan:SetText(ns.T("matScanUses"))
    end
    self.inspector:SetProps({id = p.id})
    local q = ns.Markets.Quote(p.id)
    local age = q and (q.vendor and ns.T("cacheVendorPrice", K.Money(q.price))
        or ns.T("cacheObserved", date("%d.%m %H:%M", q.at))) or ns.T("reagentNoPrice")
    if q and (q.miss or 0) > 0 then age = age .. ns.T("cacheIncomplete") end
    self.age:SetText(age)
    self:Options()
    self:Posting()
    local activity = ns.Activity.Recent(p.id)
    local guide = bags and "" or ("\n\n" .. ns.T(packs and "packSummary" or "reagentComparisonShort") .. "\n\n"
        .. ns.T(packs and "packGuide" or (count == 0 and "reagentNoUses" or "reagentGuide")))
    K.Tooltip(self.help, ns.T("matPanelTitle"), ns.T("matPanelTip") .. guide
        .. "\n\n" .. (activity and ns.T("marketActivityShort", activity.added, activity.gone, activity.beforeExpiry) or "")
        .. "\n\n" .. ns.T("marketActivityTip"))
    self.count = count
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
    self.panelChild:SetWidth(fits and 258 or 236)
    self.panelChild:SetHeight(self.panelHeight)
    local width = fits and 258 or 236
    self.lotsEdit:ClearAllPoints(); self.lotsEdit:SetPoint("TOPLEFT", self.panelChild, "TOPLEFT", width - 58, -266)
    self.priceEdit:SetWidth(width - 174)
    self.priceNote:SetWidth(44)
    local inner = (fits and 258 or 236) - 24
    for _, row in ipairs(self.optionRows) do row.detail:SetWidth(inner) end
    for _, label in ipairs({self.age, self.wall1, self.wall2, self.floor, self.sizeHint, self.total}) do label:SetWidth(inner) end
end
function UI:Field(parent, x, y, width, apply)
    local K = ns.TradeKit
    local edit = K.Edit(parent, width)
    edit:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    K.LiveEdit(edit, function(box) apply(box:GetText() or ""); self:Render() end)
    return edit
end
function UI:New(parent)
    local K = ns.TradeKit
    self.frame = ns.NewFrame("Frame", nil, parent)
    local f = self.frame
    f:SetAllPoints(parent)
    self.scopeSegment = K.Segment(f, {{key = "all", label = ns.T("matScopeAll")}, {key = "bags", label = ns.T("matScopeBags")}},
        function(scope) self:SetScope(scope) end)
    self.scopeSegment.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -3)
    K.Tooltip(self.scopeSegment.frame, ns.T("matScopeTitle"), ns.T("matScopeTip"))
    self.viewMenu = K.Menu(f, {{key = "craft", labelKey = "professionCrafts"}, {key = "packs", labelKey = "reagentPacks"}}, function(mode)
        self.mode = mode; self.scroll.offset = 0; self:Render()
    end)
    self.viewMenu.frame:SetWidth(100); self.viewMenu.frame:SetPoint("LEFT", self.scopeSegment.frame, "RIGHT", 6, 0)
    self.picker = K.FamilyPicker:New(f, function(id) self:SetProps({id = id}) end)
    self.picker.frame:SetPoint("LEFT", self.viewMenu.frame, "RIGHT", 6, 0)
    self.picker.frame:SetWidth(224); self.picker.frame.text:SetWidth(192)
    self.scan = K.Button(f, ns.T("scanSelection"), 140, function()
        if self.scope == "bags" then
            local ids = {}
            for _, row in ipairs(ns.Reagents.BagItems(ns.Fee())) do ids[#ids + 1] = row.id end
            ns.Batch.Complete(ids, K.ScanMode(), true)
        else ns.Reagents.Complete(self.props.id, K.ScanMode()) end
        self:Render()
    end, "main")
    self.scan:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    self.scan.tipFn = function()
        if self.scope ~= "bags" then return ns.T("scanReagentSelectionTip") end
        local ids = {}
        for _, row in ipairs(ns.Reagents.BagItems(ns.Fee())) do ids[#ids + 1] = row.id end
        return ns.T("matScanBagsTip") .. "\n\n" .. ns.Batch.PreviewText(ids, true)
    end
    K.Tooltip(self.scan, ns.T("scanSelection"), ns.T("scanReagentSelectionTip"))
    K.TableHeader(f, -38)
    self.headers, self.bagHeaders = {}, {}
    for _, entry in ipairs({{"item", "reagentRecipes"}, {"price", "tradeUnitPrice"},
        {"margin", "reagentGain"}, {"units", "tradeUnits"}}) do
        local label = K.Label(f, ns.T(entry[2]), 0, -38, 100)
        if entry[1] ~= "item" then label:SetJustifyH("RIGHT") end
        self.headers[entry[1]] = label
    end
    for _, entry in ipairs({{"item", "matColItem"}, {"count", "matColCount"}, {"cost", "matColCost"},
        {"market", "matColMarket"}, {"value", "matColValue"}, {"posted", "matColPosted"}}) do
        local label = K.Label(f, ns.T(entry[2]), 0, -38, 100)
        label:SetHeight(12)
        if entry[1] ~= "item" then label:SetJustifyH("RIGHT") end
        label:Hide()
        self.bagHeaders[entry[1]] = label
    end
    self.sorter = K.Sorter(f, self.headers, function() self.scroll.offset = 0; self:Render() end)
    self.bagSorter = K.Sorter(f, self.bagHeaders, function() self.scroll.offset = 0; self:Render() end)
    self.scroll = K.TableScroll(f, function() self:Render() end, 56, 56, 29)
    for i = 1, 40 do
        local row = K.MarketRow:New(f, function(id)
            local recipe = ns.Crafting.byItem[id]
            if recipe then ns.Trader.OpenRecipe(recipe.profession, id) end
        end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -56 - (i - 1) * 29)
        row.frame:SetHeight(28)
        self.rows[i] = row
        self.scroll:Wheel(row.frame)
        local bagRow = K.BagRow:New(f, function(id) self:SetProps({id = id}) end)
        bagRow.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -56 - (i - 1) * BAG_ROW)
        bagRow.frame:Hide()
        self.bagRows[i] = bagRow
        self.scroll:Wheel(bagRow.frame)
    end
    self.empty = K.Label(f, "", 10, -66, 370)
    self.empty:SetHeight(60); self.empty:SetJustifyV("TOP")
    self.buy = K.Button(f, ns.T("tradeBuy"), 84, function() ns.Trader.OpenBuy(self.props.id) end)
    self.buy:SetPoint("RIGHT", self.scan, "LEFT", -6, 0)
    self.inspector = K.Inspector:New(f)
    local panel = self.inspector.body
    self.scrollBody = ns.NewFrame("ScrollFrame", "ManaCodeMaterialsPanelScroll", panel, "UIPanelScrollFrameTemplate")
    self.scrollBody.scrollBarHideable = 1
    self.panelChild = ns.NewFrame("Frame", nil, self.scrollBody)
    self.panelHeight = 438
    self.panelChild:SetWidth(258); self.panelChild:SetHeight(self.panelHeight)
    self.scrollBody:SetScrollChild(self.panelChild)
    self.panelChild:EnableMouseWheel(true)
    self.panelChild:SetScript("OnMouseWheel", function(_, delta)
        if ScrollFrameTemplate_OnMouseWheel then ScrollFrameTemplate_OnMouseWheel(self.scrollBody, delta) end
    end)
    panel = self.panelChild
    self.selection = self.inspector.item
    K.Label(panel, ns.T("matDo"), 12, -4, 240, "heading"):SetHeight(14)
    self.optionRows = {}
    for i, y in ipairs({-20, -46, -72}) do
        local label, value = K.ValueRow(panel, "", y, 106, 100)
        local detail = K.Label(panel, "", 12, y - 13, 240, "secondary")
        detail:SetHeight(12)
        self.optionRows[i] = {label = label, value = value, detail = detail}
    end
    self.age = K.Label(panel, "", 12, -102, 240, "secondary")
    self.age:SetHeight(12)
    self.obtain = K.Button(panel, ns.T("reagentObtain"), 128, function()
        local recipe = ns.Crafting.byItem[self.props.id]
        if recipe then ns.Trader.OpenRecipe(recipe.profession, recipe.raw) end
    end)
    self.obtain:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -118)
    K.Rule(panel, -146)
    K.Label(panel, ns.T("postTitle"), 12, -152, 140, "heading"):SetHeight(14)
    self.stock = K.Label(panel, "", 0, -152, 100, "secondary")
    self.stock:ClearAllPoints(); self.stock:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -153)
    self.stock:SetHeight(12); self.stock:SetJustifyH("RIGHT")
    self.wall1 = K.Label(panel, "", 12, -168, 240); self.wall1:SetHeight(12)
    self.wall2 = K.Label(panel, "", 12, -181, 240, "secondary"); self.wall2:SetHeight(12)
    K.Label(panel, ns.T("postPrice"), 12, -203, 110):SetHeight(12)
    self.priceEdit = self:Field(panel, 124, -198, 84, function(text)
        local d = self:Draft(self.props.id)
        if text:match("^%s*$") then d.price = nil else d.price = ns.Accounting.Price(text) or d.price end
    end)
    K.Tooltip(self.priceEdit, ns.T("postPrice"), ns.T("postPriceTip"))
    self.priceNote = K.Label(panel, "", 0, -203, 40, "secondary")
    self.priceNote:ClearAllPoints(); self.priceNote:SetPoint("TOPLEFT", self.priceEdit, "TOPRIGHT", 6, -5)
    self.priceNote:SetWidth(44); self.priceNote:SetHeight(12)
    self.modeSegment = K.Segment(panel, {{key = "under", label = ns.T("postUnder")}, {key = "near", label = ns.T("postNear")}},
        function(mode)
            local d = self:Draft(self.props.id)
            d.mode, d.price = mode, nil
            self:Render()
        end)
    self.modeSegment.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -224)
    K.Tooltip(self.modeSegment.frame, ns.T("postModeTitle"), ns.T("postModeTip"))
    self.floor = K.Label(panel, "", 12, -250, 240, "secondary"); self.floor:SetHeight(12)
    K.Label(panel, ns.T("postSize"), 12, -271, 70):SetHeight(12)
    self.sizeEdit = self:Field(panel, 78, -266, 46, function(text)
        local d = self:Draft(self.props.id)
        d.size = tonumber(text) and math.max(1, math.floor(tonumber(text))) or nil
    end)
    K.Tooltip(self.sizeEdit, ns.T("postSize"), ns.T("postSizeTip"))
    K.Label(panel, ns.T("postLots"), 132, -271, 40):SetHeight(12)
    self.lotsEdit = self:Field(panel, 196, -266, 46, function(text)
        local d = self:Draft(self.props.id)
        d.lots = tonumber(text) and math.max(1, math.floor(tonumber(text))) or nil
    end)
    K.Tooltip(self.lotsEdit, ns.T("postLots"), ns.T("postLotsTip"))
    self.sizeHint = K.Label(panel, "", 12, -291, 240, "secondary"); self.sizeHint:SetHeight(12)
    self.hoursSegment = K.Segment(panel, {{key = 12, label = ns.T("postHours", 12)}, {key = 24, label = ns.T("postHours", 24)},
        {key = 48, label = ns.T("postHours", 48)}}, function(hours)
        self:Draft(self.props.id).hours = hours
        self:Render()
    end)
    self.hoursSegment.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -307)
    K.Tooltip(self.hoursSegment.frame, ns.T("postHoursTitle"), ns.T("postHoursTip"))
    local label
    label, self.buyout = K.ValueRow(panel, ns.T("postBuyout"), -334, 106, 100)
    label, self.net = K.ValueRow(panel, ns.T("postNet"), -347, 106, 100)
    label, self.profit = K.ValueRow(panel, ns.T("postProfit"), -360, 106, 100)
    self.total = K.Label(panel, "", 12, -373, 240, "secondary"); self.total:SetHeight(12)
    self.post = K.Button(panel, ns.T("postAction"), 120, function() self:Post() end, "main")
    self.post:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -388)
    K.Tooltip(self.post, ns.T("postAction"), ns.T("postActionTip"))
    self.note = K.Label(panel, "", 12, -418, 200, "secondary"); self.note:SetHeight(12)
    self.help = K.Button(panel, ns.T("tradeInfo"), 24, function() end, "quiet")
    self.help:SetPoint("TOPRIGHT", self.inspector.body, "TOPRIGHT", -12, -44)
    ns.Posting.onChange = function()
        if self.frame:IsVisible() then self:Render() end
    end
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render()
    return self
end
