local _, ns = ...
local UI = {props = {profession = "alchemy", recipe = 46376, id = 46376, page = 1},
    rows = {}, groups = {}, collapsed = {}, make = {}, ignore = {}, open = {}}
ns.AlchemyUI = UI
function UI:SetProps(props)
    if props.profession and props.profession ~= self.props.profession then
        self.props.profession = props.profession
        local catalog = ns.craftCatalogs[props.profession]
        local first = (ns.Hidden.Filter(catalog.recipes, false)[1] or catalog.recipes[1]).raw
        self.props.recipe, self.props.id, self.props.page = first, first, 1
        self.showHidden = false
        self.make, self.ignore, self.props.craftAll = {}, {}, false
        self.open = {}
        self.props.quantity = nil
        if self.scroll then self.scroll.offset = 0 end
    end
    if props.recipe and props.recipe ~= self.props.recipe then
        self.props.id = props.recipe
        self.make, self.ignore, self.props.craftAll = {}, {}, false
        self.props.quantity = nil
    end
    if props.reveal then self.revealID = props.recipe or self.props.recipe end
    for key, value in pairs(props) do
        if key ~= "reveal" and key ~= "fee" then self.props[key] = value end
    end
    self:Render()
end
function UI:Select(id, row)
    if row and row.hidden then return end
    local owner = row and row.owner
    if not owner then self:SetProps({recipe = id, id = id}); return end
    self:SetProps({recipe = owner})
    for key in pairs(self.open[owner] or {}) do self.make[key] = true end
    self:SetProps({id = id})
end
function UI:ToggleMaterial(id, row)
    local owner = row and row.owner
    if owner then
        local tree = self.open[owner]
        tree[id] = not tree[id] or nil
    else self.open[id] = not self.open[id] and {} or nil end
    self:Render()
end
function UI:Controls()
    if not self.frame then return end
    if ns.Scan.state.phase == "idle" and not ns.Buy.Active() then self.scan:Enable() else self.scan:Disable() end
    local batch = self.batch and self.batch.scan
    if batch then
        if ns.Scan.state.phase == "idle" and not ns.Buy.Active() then batch:Enable() else batch:Disable() end
    end
end
function UI:Options()
    local p = self.props
    return {make = self.make, ignore = self.ignore, craftAll = p.craftAll, owned = p.owned, fee = ns.Fee(), quantity = p.quantity}
end
function UI:ScanSources()
    return ns.Crafting.ProfessionSources(self.props.profession)
end
function UI:RecipeSources()
    return ns.Crafting.RecipeSources(ns.craftCatalogs[self.props.profession].byItem[self.props.recipe], self:Options())
end
function UI:ScanRecipe()
    local recipe = ns.craftCatalogs[self.props.profession].byItem[self.props.recipe]
    if recipe then ns.Crafting.Complete(recipe, ns.TradeKit.ScanMode(), self:Options()) end
    self:Render()
end
function UI:Render()
    if not self.frame then return end
    local K, p = ns.TradeKit, self.props
    local catalog = ns.craftCatalogs[p.profession]
    self.reserve = self.showHidden and 70 or 26
    local width = (self.frame:GetWidth() or 996) - 310
    local columns = K.MarketColumns(width - self.reserve)
    for key, label in pairs(self.headers) do
        if columns[key] then
            label:ClearAllPoints()
            label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + columns[key][1], -38)
            label:SetWidth(columns[key][2]); label:Show()
        else label:Hide() end
    end
    self.sorter:Mark()
    self.scan.tipFn = function()
        return ns.T("craftListScanTip") .. "\n\n" .. ns.Batch.PreviewText(self:ScanSources(), true)
    end
    self.owned:SetText(ns.T(p.owned and "craftOwnedYes" or "craftOwnedNo"))
    self:RenderList(catalog, width)
    self:Controls()
end
function UI:ListEntries(ranked)
    local p = self.props
    local entries, categories, byCategory = {}, {}, {}
    for _, entry in ipairs(ranked) do
        local category = entry.recipe.category
        local bucket = byCategory[category]
        if not bucket then
            bucket = {category = category, key = p.profession .. ":" .. category, entries = {}, priced = 0}
            byCategory[category] = bucket
            categories[#categories + 1] = bucket
        end
        bucket.entries[#bucket.entries + 1] = entry
        if entry.plan.margin then
            bucket.priced = bucket.priced + 1
            bucket.best = math.max(bucket.best or entry.plan.margin, entry.plan.margin)
        end
        if entry.raw == self.revealID then self.collapsed[bucket.key] = nil end
    end
    local hiddenGroups = {}
    for _, bucket in ipairs(categories) do
        if ns.Hidden.IsGroup(bucket.key) then hiddenGroups[#hiddenGroups + 1] = bucket
        else
            entries[#entries + 1] = {category = bucket}
            if not self.collapsed[bucket.key] then
                for _, entry in ipairs(bucket.entries) do
                    entries[#entries + 1] = entry
                    if self.open[entry.raw] then
                        for _, node in ipairs(ns.CraftPlan.Build(entry.recipe, {make = self.open[entry.raw], fee = ns.Fee()}).rows) do
                            entries[#entries + 1] = {node = node, owner = entry.raw}
                        end
                    end
                end
            end
        end
    end
    local hidden = ns.Hidden.Recipes(p.profession)
    if #hidden > 0 or #hiddenGroups > 0 then
        entries[#entries + 1] = {spoiler = true, count = #hidden + #hiddenGroups}
        if self.showHidden then
            for _, bucket in ipairs(hiddenGroups) do entries[#entries + 1] = {category = bucket, hiddenGroup = true} end
            for _, recipe in ipairs(hidden) do entries[#entries + 1] = {hiddenRecipe = recipe} end
        end
    end
    return entries
end
function UI:CategoryProps(bucket, width, hiddenGroup)
    local K = ns.TradeKit
    local actions
    if hiddenGroup then
        actions = {{label = ns.T("hiddenRestore"), width = 64, tip = ns.T("hiddenRestoreTip"),
            fn = function(key) ns.Hidden.SetGroup(key, false); self:Render() end}}
    else
        actions = {{label = ns.T("hiddenHide"), icon = "hide", tip = ns.T("hiddenHideTip"),
            fn = function(key) ns.Hidden.SetGroup(key, true); self:Render() end}}
    end
    local detail = ns.T("craftCategoryDetail", #bucket.entries, bucket.priced, K.Money(bucket.best))
    if hiddenGroup then detail = ns.T("craftHiddenGroup", detail) end
    return {key = bucket.key, width = width, open = hiddenGroup or not self.collapsed[bucket.key], actionWidth = hiddenGroup and 70 or 26,
        name = ns.T(bucket.category), detail = detail, tip = ns.T("craftCategoryTip"), actions = actions}
end
function UI:Reveal(entries, visible)
    local id = self.revealID
    self.revealID = nil
    for index, entry in ipairs(entries) do
        if entry.raw == id and not entry.node then
            local offset = self.scroll.offset or 0
            if index <= offset or index > offset + visible then self.scroll.offset = math.max(0, index - 2) end
            return
        end
    end
end
function UI:RenderList(catalog, width)
    local K, p = ns.TradeKit, self.props
    local ranked = ns.CraftPlan.Rank(catalog.recipes, {owned = p.owned, fee = ns.Fee()})
    ranked = self.sorter:Apply(ranked, {
        item = function(entry) return ns.Markets.Name(entry.raw) end,
        price = function(entry) local q = ns.Markets.Quote(entry.raw); return q and q.price end,
        margin = function(entry) return entry.plan.margin end,
        units = function(entry) local q = ns.Markets.Quote(entry.raw); return q and q.units end,
    }, function(entry) return ns.Collections.Pinned(entry.raw) end)
    self.ranked = ranked
    local entries = self:ListEntries(ranked)
    local visible = K.ListCapacity(self.frame, 56, 40, 29, #self.rows + #self.groups)
    if self.revealID then self:Reveal(entries, visible) end
    local offset = self.scroll:SetRange(#entries, visible)
    self.spoiler:Hide()
    local usedRows, usedGroups = 0, 0
    for i = 1, visible do
        local entry = entries[offset + i]
        local y = -56 - (i - 1) * 29
        if entry and entry.spoiler then
            self.spoiler:ClearAllPoints()
            self.spoiler:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, y)
            self.spoiler:SetWidth(width); self.spoiler:SetHeight(26)
            self.spoiler:SetText(ns.T(self.showHidden and "hiddenSpoilerOpen" or "hiddenSpoilerClosed", entry.count))
            self.spoiler:Show()
        elseif entry and entry.category then
            usedGroups = usedGroups + 1
            local header = self.groups[usedGroups]
            if header then
                header.frame:ClearAllPoints(); header.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, y)
                header:SetProps(self:CategoryProps(entry.category, width, entry.hiddenGroup))
            end
        elseif entry then
            usedRows = usedRows + 1
            local row = self.rows[usedRows]
            if row then
                row.frame:ClearAllPoints(); row.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, y)
                self:ListRow(row, entry, width)
            end
        end
    end
    for i = usedRows + 1, #self.rows do self.rows[i].frame:Hide() end
    for i = usedGroups + 1, #self.groups do self.groups[i].frame:Hide() end
    self.listTitle:SetText(ns.T("craftListTitle", ns.T(catalog.labelKey), #ranked))
    self:RenderPanel(catalog)
end
function UI:RenderPanel(catalog)
    local p = self.props
    local recipe = catalog.byItem[p.recipe]
    if not recipe then
        self.inspector:Clear(); self.category:SetText(ns.T(catalog.labelKey)); self.batch:SetProps({}); return
    end
    self.inspector:SetProps({id = p.id or p.recipe})
    self.category:SetText(ns.T(recipe.category))
    local known = ns.Recipes.Known(recipe.spell, ns.T(catalog.labelKey))
    self.batch:SetProps({recipe = recipe, known = known, options = self:Options(), ownedChip = false,
        note = recipe.cooldown and ns.T("craftCooldown") or nil,
        selected = p.id ~= p.recipe and p.id or false,
        select = function(id) self:SetProps({id = id or p.recipe}) end,
        scan = {run = function() self:ScanRecipe() end, tip = function()
            return ns.T("scanRecipeSelectionTip") .. "\n\n" .. ns.Batch.PreviewText(self:RecipeSources(), false)
        end},
        reagent = {open = function(id) ns.Trader.OpenReagent(id) end},
        change = function(key, value, id)
            if key == "make" then self.make[id] = value; self:Render()
            elseif key == "ignore" then self.ignore[id] = value or nil; self:Render()
            elseif key == "price" then self:Render()
            else self:SetProps({[key] = value}) end
        end,
        buy = function(id, need) ns.Trader.OpenBuy(id, need) end})
end
function UI:ListRow(row, entry, width)
    local K, p = ns.TradeKit, self.props
    if entry.hiddenRecipe then
        local recipe = entry.hiddenRecipe
        row:SetProps({id = recipe.raw, active = false, width = width, reserve = self.reserve, depth = 0,
            expandable = false, hidden = true, hideable = true, noRefresh = true,
            hideLabel = ns.T("hiddenRestore"), detail = ns.T(recipe.category) .. ns.T("hiddenRowNote")})
    elseif entry.node then
        local node = entry.node
        local have = math.max(0, GetItemCount(node.id, true) or 0)
        local q = ns.Alchemy.Quote(node.id)
        local detail = ns.T(have >= node.count and "craftListInputEnough" or "craftListInput", node.count, have)
        if q and q.vendor then detail = detail .. ns.T("cacheVendorRole")
        elseif q and q.manual then detail = detail .. ns.T("alchemyOwnPrice") end
        if node.crafted then detail = detail .. ns.T("craftSourceMake") end
        if node.extra and node.extra > 0 then detail = detail .. ns.T("craftExtra", node.extra) end
        K.Tooltip(row.expand, ns.T("craftListExpand"), ns.T("craftListExpandTip"))
        row:SetProps({id = node.id, quote = q, active = entry.owner == p.recipe and node.id == p.id,
            width = width, depth = node.depth + 1,
            expandable = node.expandable, crafted = node.crafted, owner = entry.owner, reserve = self.reserve,
            detail = detail, extraTip = ns.T("craftListInputTip")})
    else
        local q = ns.Markets.Quote(entry.raw)
        local detail = ns.T("craftListDetail", ns.T(entry.recipe.category), entry.recipe.count, K.Money(entry.plan.cost))
        if q then detail = detail .. ns.T("cacheAge", math.max(0, math.floor((time() - q.at) / 60))) end
        local stock = ns.CraftPlan.Stock(entry.recipe)
        if stock > 0 then detail = detail .. ns.T("craftListStock", stock) end
        K.Tooltip(row.expand, ns.T("craftListExpand"), ns.T("craftListExpandTip"))
        row:SetProps({id = entry.raw, quote = q, active = entry.raw == p.recipe, width = width,
            margin = entry.plan.margin, detail = detail, depth = 0,
            expandable = true, crafted = self.open[entry.raw] ~= nil, reserve = self.reserve, hideable = true})
    end
end
function UI:New(parent)
    local K = ns.TradeKit
    self.frame = ns.NewFrame("Frame", nil, parent)
    local f = self.frame
    f:SetAllPoints(parent)
    self.listTitle = K.Label(f, "", 12, -11, 240, "heading")
    self.scan = K.Button(f, ns.T("craftListScan"), 170, function()
        ns.Crafting.CompleteProfession(self.props.profession, K.ScanMode())
        self:Render()
    end, "main")
    self.scan:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    K.Tooltip(self.scan, ns.T("craftListScan"), ns.T("craftListScanTip"))
    K.TableHeader(f, -38)
    self.headers = {}
    for _, entry in ipairs({{"item", "craftListRecipes"}, {"price", "tradeUnitPrice"},
        {"margin", "craftMargin"}, {"units", "tradeUnits"}}) do
        local label = K.Label(f, ns.T(entry[2]), 0, -38, 100)
        if entry[1] ~= "item" then label:SetJustifyH("RIGHT") end
        self.headers[entry[1]] = label
    end
    self.sorter = K.Sorter(f, self.headers, function() self.scroll.offset = 0; self:Render() end)
    self.scroll = K.TableScroll(f, function() self:Render() end, 85, 40, 29)
    for i = 1, 40 do
        local row = K.MarketRow:New(f, function(id, props) self:Select(id, props) end,
            function(id, props) self:ToggleMaterial(id, props) end,
            function(id) self.open[id] = nil; ns.Hidden.Toggle(id); ns.Trader.Refresh() end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -56 - (i - 1) * 29)
        row.frame:SetHeight(28)
        self.rows[i] = row
        self.scroll:Wheel(row.frame)
    end
    for i = 1, 10 do
        local header = K.GroupRow:New(f, function(key) self.collapsed[key] = not self.collapsed[key] or nil; self:Render() end)
        header.frame:SetHeight(29); header.frame:Hide(); self.scroll:Wheel(header.frame); self.groups[i] = header
    end
    self.spoiler = K.Button(f, "", 400, function() self.showHidden = not self.showHidden; self:Render() end, "quiet")
    self.spoiler.text:ClearAllPoints(); self.spoiler.text:SetPoint("LEFT", self.spoiler, "LEFT", 10, 0)
    self.spoiler:Hide()
    K.Tooltip(self.spoiler, ns.T("hiddenSection"), ns.T("hiddenSpoilerTip"))
    local info = K.Button(f, ns.T("tradeInfo"), 24, function() end)
    info:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 4)
    K.Tooltip(info, ns.T("craftProfessions"), ns.T("alchemyInfo") .. "\n\n" .. ns.T("craftMarginTip"))
    self.owned = K.Button(f, "", 126, function() self:SetProps({owned = not self.props.owned}) end)
    self.owned:SetPoint("LEFT", info, "RIGHT", 6, 0)
    K.Tooltip(self.owned, ns.T("craftOwnedTitle"), ns.T("craftOwnedTip"))
    self.inspector = K.Inspector:New(f)
    local panel = self.inspector.body
    self.selection = self.inspector.item
    self.category = K.Label(panel, "", 12, -48, 240)
    self.category:SetHeight(14); self.category:SetJustifyV("TOP")
    self.batch = K.BatchPanel:New(panel)
    self.batch.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -66)
    self.batch.frame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6, 8)
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render()
    return self
end
