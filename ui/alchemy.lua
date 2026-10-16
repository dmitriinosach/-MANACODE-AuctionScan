local _, ns = ...
local UI = {props = {profession = "alchemy", recipe = 46376, id = 46376, fee = 0.05, page = 1, view = "list"},
    rows = {}, make = {}, ignore = {}, open = {}}
ns.AlchemyUI = UI
function UI:SetProps(props)
    local view = props.view or (props.recipe and "recipe")
    if props.profession and props.profession ~= self.props.profession then
        ns.Batch.Stop()
        self.props.profession = props.profession
        local first = ns.craftCatalogs[props.profession].recipes[1].raw
        self.props.recipe, self.props.id, self.props.page = first, first, 1
        self.make, self.ignore, self.props.craftAll = {}, {}, false
        self.open = {}
        if self.scroll then self.scroll.offset = 0 end
        view = view or "list"
    end
    if props.recipe and props.recipe ~= self.props.recipe then
        ns.Batch.Stop()
        self.props.id = props.recipe
        if self.scroll then self.scroll.offset = 0 end
        self.make, self.ignore, self.props.craftAll = {}, {}, false
    end
    if view and view ~= self.props.view then
        if self.scroll then self.scroll.offset = 0 end
        if view == "recipe" then self.props.id = props.recipe or self.props.recipe end
    end
    for key, value in pairs(props) do self.props[key] = value end
    self.props.view = view or self.props.view
    self:Render()
end
function UI:Select(id, row)
    if self.props.view ~= "list" then self:SetProps({id = id}); return end
    local owner = row and row.owner
    if not owner or ns.craftCatalogs[self.props.profession].byItem[id] then self:SetProps({recipe = id}); return end
    self:SetProps({recipe = owner})
    for key in pairs(self.open[owner] or {}) do self.make[key] = true end
    self:SetProps({id = id})
end
function UI:ToggleMaterial(id, row)
    if self.props.view == "list" then
        local owner = row and row.owner
        if owner then
            local tree = self.open[owner]
            tree[id] = not tree[id] or nil
        else self.open[id] = not self.open[id] and {} or nil end
        self:Render(); return
    end
    local current = self.make[id]
    if current == nil then current = self.props.craftAll end
    self.make[id] = not current
    self:Render()
end
function UI:Controls()
    if not self.frame then return end
    local phase, list = ns.Scan.state.phase, self.props.view == "list"
    if phase == "idle" then
        self.stop:Hide()
        if list or ns.vendorPrices[self.props.id] then self.update:Hide() else self.update:Show() end
    else self.stop:Show(); self.update:Hide() end
    if list then self.buy:Hide() else self.buy:Show() end
    if ns.vendorPrices[self.props.id] then self.buy:Disable() else self.buy:Enable() end
    if phase == "paused" then self.resume:Show() else self.resume:Hide() end
    if phase == "idle" and not ns.Buy.Active() then self.scan:Enable() else self.scan:Disable() end
end
function UI:SavePrice()
    local price = tonumber((self.priceEdit:GetText():gsub(",", ".")))
    if not price or not ns.Alchemy.SetPrice(self.props.id, price * 10000) then
        ns.say(ns.T("alchemyInvalidPrice")); return
    end
    self.priceEdit:ClearFocus()
    self.editID = nil
    self:Render()
end
function UI:Render()
    if not self.frame then return end
    local K, p = ns.TradeKit, self.props
    local list = p.view == "list"
    local catalog = ns.craftCatalogs[p.profession]
    local width = (self.frame:GetWidth() or 996) - 310
    local columns = K.MarketColumns(width, not list and "craft" or nil)
    for key, label in pairs(self.headers) do
        if columns[key] then
            label:ClearAllPoints()
            label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + columns[key][1], -38)
            label:SetWidth(columns[key][2]); label:Show()
        else label:Hide() end
    end
    self.headers.item:SetText(ns.T(list and "craftListRecipes" or "alchemyItem"))
    for _, frame in ipairs({self.picker.frame, self.back, self.materials}) do
        if list then frame:Hide() else frame:Show() end
    end
    if list then self.listTitle:Show() else self.listTitle:Hide() end
    self.scan:SetText(ns.T(list and "craftListScan" or "scanSelection"))
    K.Tooltip(self.scan, ns.T(list and "craftListScan" or "scanSelection"),
        ns.T(list and "craftListScanTip" or "scanRecipeSelectionTip"))
    self.owned:SetText(ns.T(p.owned and "craftOwnedYes" or "craftOwnedNo"))
    self.fee:SetText(ns.T("tradeFee", math.floor(p.fee * 100 + 0.5)))
    if list then self:RenderList(catalog, width) else self:RenderRecipe(catalog, width) end
    self:Controls()
end
function UI:RenderList(catalog, width)
    local K, p = ns.TradeKit, self.props
    local ranked = ns.CraftPlan.Rank(catalog.recipes, {owned = p.owned, fee = p.fee})
    self.ranked = ranked
    local priced, profitable = 0, 0
    for _, entry in ipairs(ranked) do
        if entry.plan.margin then
            priced = priced + 1
            if entry.plan.margin > 0 then profitable = profitable + 1 end
        end
    end
    local entries = {}
    for _, entry in ipairs(ranked) do
        entries[#entries + 1] = entry
        if self.open[entry.raw] then
            for _, node in ipairs(ns.CraftPlan.Build(entry.recipe, {make = self.open[entry.raw], fee = p.fee}).rows) do
                entries[#entries + 1] = {node = node, owner = entry.raw}
            end
        end
    end
    local visible = K.ListCapacity(self.frame, 56, 96, 29, #self.rows)
    local offset = self.scroll:SetRange(#entries, visible)
    for i, row in ipairs(self.rows) do
        local entry = i <= visible and entries[offset + i]
        if entry and entry.node then
            local node = entry.node
            local have = math.max(0, GetItemCount(node.id, true) or 0)
            local q = ns.Alchemy.Quote(node.id)
            local detail = ns.T(have >= node.count and "craftListInputEnough" or "craftListInput", node.count, have)
            if q and q.vendor then detail = detail .. ns.T("cacheVendorRole")
            elseif q and q.manual then detail = detail .. ns.T("alchemyOwnPrice") end
            if node.crafted then detail = detail .. ns.T("craftSourceMake") end
            if node.extra and node.extra > 0 then detail = detail .. ns.T("craftExtra", node.extra) end
            K.Tooltip(row.expand, ns.T("craftListExpand"), ns.T("craftListExpandTip"))
            row:SetProps({id = node.id, quote = q, active = false, width = width, depth = node.depth + 1, include = false,
                expandable = node.expandable, crafted = node.crafted, owner = entry.owner,
                detail = detail, extraTip = ns.T("craftListInputTip")})
        elseif entry then
            local q = ns.Markets.Quote(entry.raw)
            local detail = ns.T("craftListDetail", ns.T(entry.recipe.category), entry.recipe.count, K.Money(entry.plan.cost))
            if q then detail = detail .. ns.T("cacheAge", math.max(0, math.floor((time() - q.at) / 60))) end
            local stock = ns.CraftPlan.Stock(entry.recipe)
            if stock > 0 then detail = detail .. ns.T("craftListStock", stock) end
            K.Tooltip(row.expand, ns.T("craftListExpand"), ns.T("craftListExpandTip"))
            row:SetProps({id = entry.raw, quote = q, active = entry.raw == p.recipe, width = width,
                margin = entry.plan.margin, detail = detail, depth = 0, include = false,
                expandable = true, crafted = self.open[entry.raw] ~= nil})
        else row.frame:Hide() end
    end
    self.listTitle:SetText(ns.T("craftListTitle", ns.T(catalog.labelKey), #ranked))
    self.inspector:Clear()
    self.category:SetText(ns.T(catalog.labelKey))
    self.summary:SetHeight(230); self.summary:SetText(ns.T("craftListSummary", #ranked, priced, profitable))
    for _, frame in ipairs({self.priceEdit, self.save, self.reset, self.priceLabel, self.priceHint, self.reagent}) do
        frame:Hide()
    end
end
function UI:RenderRecipe(catalog, width)
    local K, p = ns.TradeKit, self.props
    local recipe = catalog.byItem[p.recipe]
    self.picker:SetProps({families = catalog.recipes, raw = p.recipe, headingKey = catalog.labelKey})
    local plan = ns.CraftPlan.Build(recipe, {make = self.make, ignore = self.ignore, craftAll = p.craftAll, owned = p.owned, fee = p.fee})
    self.plan = plan
    local entries = {{id = recipe.raw, count = recipe.count, output = true}}
    local visible = K.ListCapacity(self.frame, 56, 96, 29, #self.rows)
    local offset = self.scroll:SetRange(#plan.rows, math.max(1, visible - 1))
    for i = offset + 1, math.min(offset + visible - 1, #plan.rows) do
        entries[#entries + 1] = plan.rows[i]
    end
    for i, row in ipairs(self.rows) do
        local entry = entries[i]
        if entry then
            local q = entry.output and ns.Markets.Quote(entry.id) or ns.Alchemy.Quote(entry.id)
            local subtotal = entry.output and plan.revenue or entry.value
            local role = ns.T(entry.output and "alchemyOutput" or "alchemyInput", entry.count)
            if q and q.vendor then role = role .. ns.T("cacheVendorRole")
            elseif q and q.manual then role = role .. ns.T("alchemyOwnPrice")
            elseif q then role = role .. ns.T("cacheAge", math.max(0, math.floor((time() - q.at) / 60))) end
            if not entry.output then
                role = role .. ns.T(entry.excluded and "craftCostExcluded" or (entry.crafted and "craftSourceMake" or "craftSourceBuy"))
                if p.owned then role = role .. ns.T("craftOwnedRow", entry.own, entry.need) end
                if entry.extra and entry.extra > 0 then role = role .. ns.T("craftExtra", entry.extra) end
            end
            K.Tooltip(row.expand, ns.T("craftMaterialSource"), ns.T("craftTreeTip"))
            row:SetProps({id = entry.id, quote = q, active = entry.id == p.id,
                margin = entry.output and plan.margin or nil, subtotal = subtotal, layout = "craft", width = width, detail = role,
                depth = entry.depth, expandable = entry.expandable, crafted = entry.crafted, excluded = entry.excluded})
        else row.frame:Hide() end
    end
    self.inspector:SetProps({id = p.id})
    local known = IsSpellKnown and IsSpellKnown(recipe.spell)
    self.category:SetText(ns.T(recipe.category) .. " | " .. ns.T(known and "familyKnown" or "familyUnknownRecipe"))
    if recipe.cooldown then self.category:SetText(self.category:GetText() .. ns.T("craftCooldown")) end
    local buy = ns.CraftPlan.Build(recipe, {ignore = self.ignore, owned = p.owned, fee = p.fee})
    local make = ns.CraftPlan.Build(recipe, {ignore = self.ignore, craftAll = true, owned = p.owned, fee = p.fee})
    self.summary:SetHeight(124)
    self.summary:SetText(ns.T("craftPlanSummary", recipe.count, K.Money(plan.cost), K.Money(plan.cash),
        K.Money(plan.revenue), K.Money(plan.margin), K.Money(buy.cost), K.Money(make.cost)))
    self.materials:SetText(ns.T(p.craftAll and "craftAllMake" or "craftAllBuy"))
    local vendor = ns.vendorPrices[p.id]
    local editable = ns.Crafting.IsInput(p.id) and not vendor
    for _, frame in ipairs({self.priceEdit, self.save, self.reset, self.priceLabel}) do
        if editable then frame:Show() else frame:Hide() end
    end
    self.priceHint:SetText(vendor and ns.T("vendorResaleCost", K.Money(vendor))
        or (editable and ns.T("alchemyPriceShortHint") or ns.T("alchemySelectReagent")))
    self.priceHint:SetHeight((editable or vendor) and 18 or 34)
    if (editable or vendor) and (self.frame:GetHeight() or 510) < 350 then self.priceHint:Hide()
    else self.priceHint:Show() end
    if ns.Crafting.IsInput(p.id) then self.reagent:Show() else self.reagent:Hide() end
    if self.editID ~= p.id then
        local q = ns.Alchemy.Quote(p.id)
        self.priceEdit:SetText(q and q.manual and string.format("%.4f", q.price / 10000) or "")
        self.editID = p.id
    end
end
function UI:New(parent)
    local K = ns.TradeKit
    self.frame = ns.NewFrame("Frame", nil, parent)
    local f = self.frame
    f:SetAllPoints(parent)
    self.mode = K.ProfessionModes(f, function() return self.props.profession end, "craft")
    self.picker = K.FamilyPicker:New(f, function(id) self:SetProps({recipe = id}) end)
    self.picker.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 114, -3)
    self.picker.frame:SetWidth(170); self.picker.frame.text:SetWidth(138)
    self.listTitle = K.Label(f, "", 118, -11, 240, "heading")
    self.back = K.Button(f, ns.T("craftListBack"), 72, function() self:SetProps({view = "list"}) end, "quiet")
    self.back:SetPoint("LEFT", self.picker.frame, "RIGHT", 4, 0)
    K.Tooltip(self.back, ns.T("craftListBack"), ns.T("craftListBackTip"))
    self.scan = K.Button(f, ns.T("scanSelection"), 140, function()
        if self.props.view == "list" then ns.Crafting.CompleteProfession(self.props.profession, IsShiftKeyDown())
        else
            ns.Crafting.Complete(ns.craftCatalogs[self.props.profession].byItem[self.props.recipe], IsShiftKeyDown(),
                {make = self.make, ignore = self.ignore, craftAll = self.props.craftAll, owned = self.props.owned, fee = self.props.fee})
        end
        self:Render()
    end, "main")
    self.scan:SetPoint("TOPRIGHT", f, "TOPRIGHT", -282, -5)
    K.TableHeader(f, -38)
    self.headers = {}
    for _, entry in ipairs({{"item", "alchemyItem"}, {"price", "tradeUnitPrice"},
        {"subtotal", "alchemySubtotal"}, {"margin", "craftMargin"}, {"units", "tradeUnits"}}) do
        local label = K.Label(f, ns.T(entry[2]), 0, -38, 100)
        if entry[1] ~= "item" then label:SetJustifyH("RIGHT") end
        self.headers[entry[1]] = label
    end
    self.scroll = K.TableScroll(f, function() self:Render() end, 85, 96, 29)
    for i = 1, 40 do
        local row = K.MarketRow:New(f, function(id, props) self:Select(id, props) end,
            function(id, props) self:ToggleMaterial(id, props) end,
            function(id, checked) self.ignore[id] = not checked; self:Render() end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -56 - (i - 1) * 29)
        row.frame:SetHeight(28)
        self.rows[i] = row
        self.scroll:Wheel(row.frame)
    end
    local info = K.Button(f, ns.T("tradeInfo"), 24, function() end)
    info:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 122, 4)
    K.Tooltip(info, ns.T("craftProfessions"), ns.T("alchemyInfo") .. "\n\n" .. ns.T("craftMarginTip"))
    self.materials = K.Button(f, "", 192, function()
        self.make = {}; self:SetProps({craftAll = not self.props.craftAll, page = 1})
    end)
    self.materials:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 58)
    K.Tooltip(self.materials, ns.T("craftMaterialSource"), ns.T("craftTreeTip"))
    self.owned = K.Button(f, "", 140, function() self:SetProps({owned = not self.props.owned}) end)
    self.owned:SetPoint("LEFT", self.materials, "RIGHT", 8, 0)
    K.Tooltip(self.owned, ns.T("craftOwnedTitle"), ns.T("craftOwnedTip"))
    self.status = K.Label(f, ns.T("tradeReadyShort"), 0, 0, 200)
    self.status:ClearAllPoints(); self.status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 32)
    self.status:SetHeight(14)
    self.fee = K.Button(f, "", 106, function() self:SetProps({fee = self.props.fee == 0.05 and 0.15 or 0.05}) end)
    self.fee:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 4)
    K.Tooltip(self.fee, ns.T("tradeFeeTitle"), ns.T("tradeFeeTip"))
    local buy = K.Button(f, ns.T("tradeBuy"), 84, function() ns.Trader.OpenBuy(self.props.id) end)
    self.buy = buy
    buy:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    self.update = K.Button(f, ns.T("tradeUpdate"), 84, function() ns.Markets.Scan(self.props.id) end)
    self.update:SetPoint("RIGHT", buy, "LEFT", -6, 0)
    K.Tooltip(self.update, ns.T("cacheRefreshItem"), ns.T("cacheRefreshTip"))
    self.stop = K.Button(f, ns.T("tradeStop"), 60, function()
        ns.Batch.Stop(); ns.Scan.Stop(); self:Controls()
    end)
    self.stop:SetPoint("RIGHT", buy, "LEFT", -6, 0)
    self.resume = K.Button(f, ns.T("tradeResume"), 92, function()
        if ns.Scan.state.phase == "paused" then ns.Scan.Start("pages") end
        self:Controls()
    end)
    self.resume:SetPoint("RIGHT", self.stop, "LEFT", -6, 0)
    self.inspector = K.Inspector:New(f)
    local panel = self.inspector.body
    self.selection = self.inspector.item
    self.category = K.Label(panel, "", 12, -48, 240)
    self.category:SetHeight(28); self.category:SetJustifyV("TOP")
    self.summary = K.Label(panel, "", 12, -80, 240)
    self.summary:SetHeight(124); self.summary:SetJustifyV("TOP")
    self.priceLabel = K.Label(panel, ns.T("alchemyPriceLabel"), 12, -206, 240)
    self.priceEdit = K.Edit(panel, 118)
    self.priceEdit:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -226)
    K.Tooltip(self.priceEdit, ns.T("alchemyPriceLabel"), ns.T("alchemyPriceHint"))
    self.priceEdit:SetScript("OnEnterPressed", function() self:SavePrice() end)
    self.save = K.Button(panel, ns.T("alchemySavePrice"), 110, function() self:SavePrice() end)
    self.save:SetPoint("LEFT", self.priceEdit, "RIGHT", 8, 0)
    self.reset = K.Button(panel, ns.T("alchemyMarketPrice"), 144, function()
        ns.Alchemy.SetPrice(self.props.id, nil); self.editID = nil; self:Render()
    end)
    self.reset:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -253)
    self.priceHint = K.Label(panel, "", 12, -282, 240)
    self.priceHint:SetHeight(34); self.priceHint:SetJustifyV("TOP")
    self.reagent = K.Button(panel, ns.T("reagentOpen"), 224, function()
        ns.Trader.OpenReagent(self.props.id, self.props.fee)
    end)
    self.reagent:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 8)
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render()
    return self
end
