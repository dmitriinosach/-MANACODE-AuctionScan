local _, ns = ...
local UI = {props = {id = 36905, page = 1, fee = 0.05}, rows = {}}
ns.ReagentsUI = UI
function UI:SetProps(props)
    if props.id and props.id ~= self.props.id then
        ns.Batch.Stop(); if self.scroll then self.scroll.offset = 0 end
    end
    for key, value in pairs(props) do self.props[key] = value end
    self:Render()
end
function UI:Controls()
    if not self.frame then return end
    local phase = ns.Scan.state.phase
    if phase == "idle" and not ns.Buy.Active() then self.scan:Enable() else self.scan:Disable() end
    if phase == "paused" then self.resume:Show() else self.resume:Hide() end
    if phase == "idle" then self.stop:Hide() else self.stop:Show() end
    if ns.vendorPrices[self.props.id] then self.buy:Disable() else self.buy:Enable() end
    if ns.vendorPrices[self.props.id] then self.refresh:Hide() else self.refresh:Show() end
    if ns.Crafting.byItem[self.props.id] then self.obtain:Show() else self.obtain:Hide() end
end
function UI:Render()
    if not self.frame then return end
    local K, p = ns.TradeKit, self.props
    local uses, items = self.mode == "packs" and ns.Reagents.Packs(p.id, p.fee)
        or ns.Reagents.Uses(p.id, p.fee), ns.Reagents.Items()
    self.viewMenu.frame:SetText(ns.T(self.mode == "packs" and "reagentPacks" or "professionCrafts"))
    self.headers.item:SetText(ns.T(self.mode == "packs" and "packRecipe" or "reagentRecipes"))
    self.headers.price:SetText(ns.T(self.mode == "packs" and "packPrice" or "tradeUnitPrice"))
    self.headers.margin:SetText(ns.T(self.mode == "packs" and "packPremium" or "reagentGain"))
    self.headers.units:SetText(ns.T(self.mode == "packs" and "packLots" or "tradeUnits"))
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
            if self.mode == "packs" then
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
    self.inspector:SetProps({id = p.id})
    local q = ns.Markets.Quote(p.id)
    self.price:SetText(q and q.vendor and ns.T("cacheVendorPrice", K.Money(q.price))
        or ns.T("reagentSale", K.Money(q and q.price),
            K.Money(q and q.price and q.price * (1 - p.fee))))
    local age = q and (q.vendor and ""
        or ns.T("cacheObserved", date("%d.%m %H:%M", q.at))) or ns.T("reagentNoPrice")
    self.age:SetText(age)
    if q and (q.miss or 0) > 0 then self.age:SetText(age .. ns.T("cacheIncomplete")) end
    local activity = ns.Activity.Recent(p.id)
    self.info:SetText(ns.T(self.mode == "packs" and "packGuide" or (#uses == 0 and "reagentNoUses" or "reagentGuide")))
    self.activity:SetText(activity and ns.T("marketActivityShort", activity.added, activity.gone, activity.beforeExpiry) or "")
    K.Tooltip(self.help, ns.T(self.mode == "packs" and "packPremium" or "reagentGain"),
        ns.T(self.mode == "packs" and "packSummary" or "reagentComparisonShort") .. "\n\n" .. ns.T("marketActivityTip"))
    self.empty:SetText(#uses == 0 and ns.T("reagentNoUses") or "")
    self.fee:SetText(ns.T("tradeFee", math.floor(p.fee * 100 + 0.5)))
    self:Controls()
end
function UI:New(parent)
    local K = ns.TradeKit
    self.frame = ns.NewFrame("Frame", nil, parent)
    local f = self.frame
    f:SetAllPoints(parent)
    self.viewMenu = K.Menu(f, {{key = "craft", labelKey = "professionCrafts"}, {key = "packs", labelKey = "reagentPacks"}}, function(mode)
        self.mode = mode; self.scroll.offset = 0; self:Render()
    end)
    self.viewMenu.frame:SetWidth(100); self.viewMenu.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -3)
    self.picker = K.FamilyPicker:New(f, function(id) self:SetProps({id = id}) end)
    self.picker.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 114, -3)
    self.picker.frame:SetWidth(244); self.picker.frame.text:SetWidth(212)
    self.scan = K.Button(f, ns.T("scanSelection"), 140, function()
        ns.Batch.Complete({self.props.id}, IsShiftKeyDown()); self:Render()
    end, "main")
    self.scan:SetPoint("TOPRIGHT", f, "TOPRIGHT", -282, -5)
    K.Tooltip(self.scan, ns.T("scanSelection"), ns.T("scanReagentSelectionTip"))
    K.TableHeader(f, -38)
    self.headers = {}
    for _, entry in ipairs({{"item", "reagentRecipes"}, {"price", "tradeUnitPrice"},
        {"margin", "reagentGain"}, {"units", "tradeUnits"}}) do
        local label = K.Label(f, ns.T(entry[2]), 0, -38, 100)
        if entry[1] ~= "item" then label:SetJustifyH("RIGHT") end
        self.headers[entry[1]] = label
    end
    self.scroll = K.TableScroll(f, function() self:Render() end, 56, 56, 29)
    for i = 1, 40 do
        local row = K.MarketRow:New(f, function(id)
            local recipe = ns.Crafting.byItem[id]
            if recipe then ns.Trader.OpenRecipe(recipe.profession, id, self.props.fee) end
        end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -56 - (i - 1) * 29)
        row.frame:SetHeight(28)
        self.rows[i] = row
        self.scroll:Wheel(row.frame)
    end
    self.empty = K.Label(f, "", 10, -66, 370)
    self.empty:SetHeight(60); self.empty:SetJustifyV("TOP")
    self.fee = K.Button(f, "", 106, function() self:SetProps({fee = self.props.fee == 0.05 and 0.15 or 0.05}) end)
    self.fee:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 4)
    self.status = K.Label(f, ns.T("tradeReadyShort"), 0, 0, 200)
    self.status:ClearAllPoints(); self.status:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 32)
    self.status:SetHeight(14)
    self.buy = K.Button(f, ns.T("tradeBuy"), 84, function() ns.Trader.OpenBuy(self.props.id) end)
    self.buy:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    self.stop = K.Button(f, ns.T("tradeStop"), 60, function() ns.Batch.Stop(); ns.Scan.Stop(); self:Controls() end)
    self.stop:SetPoint("RIGHT", self.buy, "LEFT", -6, 0)
    self.resume = K.Button(f, ns.T("tradeResume"), 92, function()
        if ns.Scan.state.phase == "paused" then ns.Scan.Start("pages") end
        self:Controls()
    end)
    self.resume:SetPoint("RIGHT", self.stop, "LEFT", -6, 0)
    self.inspector = K.Inspector:New(f)
    local panel = self.inspector.body
    self.selection = self.inspector.item
    self.price = K.Label(panel, "", 12, -48, 240)
    self.price:SetHeight(36); self.price:SetJustifyV("TOP")
    self.age = K.Label(panel, "", 12, -90, 240)
    self.age:SetHeight(24); self.age:SetJustifyV("TOP")
    self.age:SetTextColor(unpack(K.theme.secondary))
    K.Rule(panel, -155)
    self.info = K.Label(panel, "", 12, -168, 240)
    self.info:SetHeight(48); self.info:SetJustifyV("TOP")
    self.activity = K.Label(panel, "", 12, -224, 240)
    self.activity:SetHeight(72); self.activity:SetJustifyV("TOP")
    self.help = K.Button(panel, ns.T("tradeInfo"), 24, function() end, "quiet")
    self.help:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 10)
    self.refresh = K.Button(panel, ns.T("tradeUpdate"), 90, function() ns.Markets.Scan(self.props.id) end)
    self.refresh:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -122)
    K.Tooltip(self.refresh, ns.T("cacheRefreshItem"), ns.T("cacheRefreshTip"))
    self.obtain = K.Button(panel, ns.T("reagentObtain"), 128, function()
        local recipe = ns.Crafting.byItem[self.props.id]
        if recipe then ns.Trader.OpenRecipe(recipe.profession, recipe.raw, self.props.fee) end
    end)
    self.obtain:SetPoint("LEFT", self.refresh, "RIGHT", 8, 0)
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render()
    return self
end
