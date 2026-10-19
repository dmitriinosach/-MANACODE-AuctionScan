local _, ns = ...
local UI = {props = {first = 1, target = 450, tool = 0, reserve = 0, choices = {}, known = {}, make = {}, open = {}},
    rows = {}, expanded = nil, stepsOpen = {}, mode = "materials"}
ns.LevelingUI = UI
function UI:SetProps(props)
    for key, value in pairs(props) do self.props[key] = value end
    self.props = ns.Leveling.Options(self.props)
    self.signature = nil
    if self.scroll then self.scroll.offset = 0 end
    self:Render()
end
function UI:Model()
    local p, c, parts = self.props, ns.levelingCatalogs.enchanting, {}
    for id in pairs(c.vendors) do parts[#parts + 1] = id end
    for _, recipe in pairs(c.recipes) do
        for _, input in ipairs(recipe.inputs) do parts[#parts + 1] = input[1] end
        if recipe.acquisition then for _, input in ipairs(recipe.acquisition.inputs) do parts[#parts + 1] = input[1] end end
    end
    for id, obtain in pairs(c.obtains) do
        parts[#parts + 1] = id
        for _, input in ipairs(obtain.inputs) do parts[#parts + 1] = input[1] end
    end
    table.sort(parts)
    local signature, seen = {tostring(math.floor(time() / 60))}, {}
    for _, id in ipairs(parts) do
        if not seen[id] then
            seen[id] = true
            local q = ns.Leveling.Quote(id)
            signature[#signature + 1] = id .. ":" .. tostring(q and q.price) .. ":" .. tostring(q and q.scanID)
                .. ":" .. tostring(q and q.complete) .. ":" .. tostring(q and q.miss)
                .. ":" .. (p.owned and tostring(GetItemCount(id, true) or 0) or "")
        end
    end
    local key = table.concat(signature, "|")
    if key ~= self.signature then
        self.signature = key
        local lowerOptions = ns.Leveling.Options(p); lowerOptions.reserve = 0
        local lower = ns.Leveling.Route(lowerOptions)
        local route = p.reserve == 0 and lower or ns.Leveling.Route(p)
        self.model = {route = route, lower = lower, basket = ns.Leveling.Basket(route)}
    end
    return self.model
end
function UI:Controls()
    if not self.frame then return end
    local phase = ns.Scan.state.phase
    if phase == "idle" and not ns.Buy.Active() then self.scan:Enable(); self.all:Enable()
    else self.scan:Disable(); self.all:Disable() end
end
function UI:Action(entry, button)
    local p = self.props
    if entry.kind == "profession" then
        if entry.key == "enchanting" then
            if self.expanded then self.expanded = nil else self.expanded = "enchanting" end
            self.scroll.offset = 0; self:Render()
        end
    elseif entry.kind == "alternative" then
        p.choices[entry.stage] = entry.spell; self:SetProps({choices = p.choices})
    elseif entry.kind == "step" then
        self.stepsOpen[entry.stage] = not self.stepsOpen[entry.stage]; self:Render()
    elseif entry.kind == "auto" then
        p.choices[entry.stage] = nil; self:SetProps({choices = p.choices})
    elseif entry.kind == "learn" then
        p.known[entry.recipe] = not p.known[entry.recipe]; self:SetProps({known = p.known})
    elseif entry.kind == "material" then
        if entry.expandable and button then p.make[entry.id] = not p.make[entry.id]; self:SetProps({make = p.make})
        elseif entry.need > 0 and not (entry.quote and entry.quote.vendor) then ns.Trader.OpenBuy(entry.id, entry.need) end
    end
end
function UI:Expand(entry)
    if entry.kind == "material" then
        self.props.open[entry.id] = not self.props.open[entry.id]
        self.signature = nil; self:Render()
    else self:Action(entry) end
end
function UI:Entries(model)
    local out, K, c, p = {}, ns.TradeKit, ns.levelingCatalogs.enchanting, self.props
    for _, profession in ipairs({{"enchanting", "professionEnchanting"}, {"alchemy", "alchemySection"},
        {"jewelry", "jewelrySection"}, {"tailoring", "professionTailoring"}, {"blacksmithing", "professionBlacksmithing"}}) do
        local enabled = profession[1] == "enchanting"
        out[#out + 1] = {kind = "profession", key = profession[1], label = ns.T(profession[2]),
            expandable = enabled, opened = enabled and self.expanded, action = enabled and ns.T("levelOpen"),
            detail = enabled and ns.T("levelRange", p.first, p.target) or ns.T("levelNotAdded"),
            cost = enabled and model.lower.missing == 0 and model.lower.cost or nil,
            costText = not enabled and ns.T("tradeNoPrice") or nil}
        if enabled and self.expanded then
            if self.mode == "steps" then
                for _, step in ipairs(model.route.steps) do
                    out[#out + 1] = {kind = "step", spell = step.spell, stage = step.index, depth = 1,
                        expandable = true, opened = self.stepsOpen[step.index], action = ns.T("levelVariants"),
                        detail = ns.T("levelStep", step.first, step.target, step.gains),
                        quantity = ns.T("levelCasts", step.count + step.extra), cost = step.missing == 0 and step.cost or nil,
                        tip = ns.T(step.uncertain and "levelUncertain" or "levelOrange") .. "\n" .. ns.T("levelModelTip")}
                    if self.stepsOpen[step.index] then
                        out[#out + 1] = {kind = "auto", stage = step.index, depth = 2,
                            label = ns.T("levelAutomatic"), action = ns.T("levelResetChoice"), costText = ""}
                        for _, alt in ipairs(ns.Leveling.Alternatives(model.route, step)) do
                            out[#out + 1] = {kind = "alternative", stage = step.index, spell = alt.spell, depth = 2,
                                active = alt.spell == step.spell, action = ns.T("levelChoose"),
                                detail = ns.T(alt.uncertain and "levelUncertain" or "levelOrange"),
                                quantity = ns.T("levelCasts", alt.count + alt.extra), cost = alt.missing == 0 and alt.cost or nil,
                                tip = ns.T("levelVariantTip")}
                        end
                        local acquisition = c.recipes[step.spell].acquisition
                        if acquisition then
                            out[#out + 1] = {kind = "learn", recipe = step.spell, id = acquisition.item, depth = 2,
                                action = ns.T(p.known[step.spell] and "levelUnlearn" or "levelLearned"), costText = "",
                                detail = ns.T(p.known[step.spell] and "levelAlreadyKnown" or "levelAcquireFormula"), tip = ns.T("levelFormulaTip")}
                        end
                        for _, tool in ipairs(step.tools) do
                            out[#out + 1] = {id = tool.item, depth = 2, costText = "", quantity = "1",
                                detail = ns.T(tool.gain and "levelToolGain" or "levelToolNoGain"), tip = ns.T("levelModelTip")}
                            local formula = c.recipes[tool.spell].acquisition
                            if formula then
                                out[#out + 1] = {kind = "learn", recipe = tool.spell, id = formula.item, depth = 3,
                                    action = ns.T(p.known[tool.spell] and "levelUnlearn" or "levelLearned"), costText = "",
                                    detail = ns.T(p.known[tool.spell] and "levelAlreadyKnown" or "levelAcquireFormula"),
                                    tip = ns.T("levelFormulaTip")}
                            end
                        end
                    end
                end
            else
                local function add(node)
                    local vendor = node.quote and node.quote.vendor
                    out[#out + 1] = {kind = "material", id = node.id, depth = node.depth + 1,
                        need = node.need, quote = node.quote, expandable = node.expandable, opened = p.open[node.id],
                        detail = ns.T("levelMaterial", node.count, node.own, node.need)
                            .. (node.extra and node.extra > 0 and ns.T("levelSurplus", node.extra) or ""),
                        action = node.expandable and ns.T(node.crafted and "levelMake" or "levelBuySource")
                            or (node.need > 0 and not vendor and ns.T("tradeBuy") or nil),
                        quantity = K.Money(node.quote and node.quote.price), cost = not node.incomplete and node.cost or nil,
                        tip = ns.T("levelMaterialTip") .. (vendor and "\n" .. ns.T("levelVendorTip") or "")
                            .. (node.quote and node.quote.at and "\n" .. ns.T("cacheObserved", date("%d.%m %H:%M", node.quote.at)) or "")}
                    if p.open[node.id] then
                        if node.crafted then for _, child in ipairs(node.children) do add(child) end
                        else
                            local obtain = ns.Leveling.Obtain(node.id)
                            if obtain then
                                local crafts = math.ceil(node.need / obtain.count)
                                for _, input in ipairs(obtain.inputs) do
                                    out[#out + 1] = {id = input[1], depth = node.depth + 2, costText = "",
                                        detail = ns.T("levelPreview"), quantity = tostring(input[2] * crafts)}
                                end
                            end
                        end
                    end
                end
                for _, node in ipairs(model.basket.roots) do add(node) end
            end
        end
    end
    return out
end
function UI:Render()
    if not self.frame or not self.frame:IsVisible() then return end
    local K, p, model = ns.TradeKit, self.props, self:Model()
    self.first:SetText(tostring(p.first)); self.target:SetText(tostring(p.target)); self.reserve:SetText(tostring(p.reserve))
    self.owned:SetChecked(p.owned); self.tool.frame:SetText(ns.T("levelTool" .. p.tool))
    self.steps:SetActive(self.mode == "steps"); self.materials:SetActive(self.mode == "materials")
    self.summary:SetText(ns.T("levelSummary", K.Money(model.lower.missing == 0 and model.lower.cost or nil),
        K.Money(model.basket.cost), K.Money(model.basket.cash), K.Money(model.basket.lotsCost)))
    self.note:SetText(ns.T(model.route.unavailable and "levelUnavailable" or
        (model.basket.missing > 0 and "levelIncomplete" or (model.basket.stale > 0 and "levelStale"
            or (not model.route.comparison and "levelComparison" or "levelModelNote")))))
    local entries = self:Entries(model)
    local visible = K.ListCapacity(self.frame, 148, 46, 38, #self.rows)
    local offset = self.scroll:SetRange(#entries, visible)
    for i, row in ipairs(self.rows) do
        local entry = i <= visible and entries[offset + i]
        if entry then entry.width = (self.frame:GetWidth() or 996) - 36; row:SetProps(entry) else row.frame:Hide() end
    end
    self:Controls()
end
function UI:New(parent)
    local K = ns.TradeKit
    self.frame = ns.NewFrame("Frame", nil, parent); self.frame:SetAllPoints(parent)
    local f = self.frame
    K.Label(f, ns.T("levelFrom"), 10, -10, 24)
    self.first = K.Edit(f, 42); self.first:SetPoint("TOPLEFT", f, "TOPLEFT", 38, -4)
    K.Label(f, ns.T("levelTo"), 87, -10, 24)
    self.target = K.Edit(f, 42); self.target:SetPoint("TOPLEFT", f, "TOPLEFT", 112, -4)
    self.first:SetNumeric(true); self.target:SetNumeric(true); self.first:SetMaxLetters(3); self.target:SetMaxLetters(3)
    local function read()
        local first, target, reserve = tonumber(self.first:GetText()), tonumber(self.target:GetText()), tonumber(self.reserve:GetText())
        self:SetProps({first = first or self.props.first, target = target or self.props.target, reserve = reserve or 0})
    end
    local function apply()
        self.first:ClearFocus(); self.target:ClearFocus(); self.reserve:ClearFocus()
        read()
    end
    K.LiveEdit(self.first, read, 0.8); K.LiveEdit(self.target, read, 0.8)
    self.apply = K.Button(f, ns.T("levelApply"), 84, apply)
    self.apply:SetPoint("TOPLEFT", f, "TOPLEFT", 162, -4)
    self.scan = K.Button(f, ns.T("levelScanRoute"), 166, function() ns.Leveling.Complete(self.props, false, K.ScanMode()); self:Controls() end, "main")
    self.scan:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -4)
    self.all = K.Button(f, ns.T("levelScanProfession"), 166, function() ns.Leveling.Complete(self.props, true, K.ScanMode()); self:Controls() end)
    self.all:SetPoint("RIGHT", self.scan, "LEFT", -6, 0)
    self.scan.tipFn = function() return ns.T("levelScanTip") .. "\n\n" .. ns.Batch.PreviewText(ns.Leveling.Targets(self.props, false), true) end
    self.all.tipFn = function() return ns.T("levelScanAllTip") .. "\n\n" .. ns.Batch.PreviewText(ns.Leveling.Targets(self.props, true), true) end
    K.Tooltip(self.scan, ns.T("levelScanRoute"), ""); K.Tooltip(self.all, ns.T("levelScanProfession"), "")
    self.steps = K.Button(f, ns.T("levelSteps"), 90, function() self.mode = "steps"; self.scroll.offset = 0; self:Render() end, "quiet")
    self.steps:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -34)
    self.materials = K.Button(f, ns.T("levelMaterials"), 100, function() self.mode = "materials"; self.scroll.offset = 0; self:Render() end, "quiet")
    self.materials:SetPoint("LEFT", self.steps, "RIGHT", 6, 0)
    K.Label(f, ns.T("levelReserve"), 220, -40, 50)
    self.reserve = K.Edit(f, 32); self.reserve:SetPoint("TOPLEFT", f, "TOPLEFT", 273, -34)
    self.reserve:SetMaxLetters(2); self.reserve:SetNumeric(true); K.LiveEdit(self.reserve, read)
    K.Tooltip(self.reserve, ns.T("levelReserve"), ns.T("levelReserveTip"))
    self.owned = K.Check(f, function(checked) self:SetProps({owned = checked}) end)
    self.owned:SetPoint("TOPLEFT", f, "TOPLEFT", 316, -36)
    K.Label(f, ns.T("levelStock"), 337, -40, 130)
    local tools = {}
    for tier = 0, 9 do tools[#tools + 1] = {key = tier, labelKey = "levelTool" .. tier} end
    self.tool = K.Menu(f, tools, function(tier) self:SetProps({tool = tier}) end)
    self.tool.frame:SetWidth(190); self.tool.frame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -34)
    K.Tooltip(self.tool.frame, ns.T("levelToolTitle"), ns.T("levelToolTip"))
    self.summary = K.Label(f, "", 10, -66, 700, "heading"); self.summary:SetHeight(40); self.summary:SetJustifyV("TOP")
    self.summary:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -66)
    self.note = K.Label(f, "", 10, -110, 700); self.note:SetHeight(28); self.note:SetJustifyV("TOP")
    self.note:SetPoint("TOPRIGHT", f, "TOPRIGHT", -46, -110)
    self.help = K.Button(f, ns.T("tradeInfo"), 24, function() end, "quiet")
    self.help:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -108)
    K.Tooltip(self.help, ns.T("levelTitle"), ns.T("levelModelTip"))
    K.TableHeader(f, -140)
    self.scroll = K.TableScroll(f, function() self:Render() end, 148, 46, 38)
    for i = 1, 40 do
        local row = K.LevelingRow:New(f, function(entry, button) self:Action(entry, button) end, function(entry) self:Expand(entry) end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -148 - (i - 1) * 38)
        self.rows[i] = row; self.scroll:Wheel(row.frame)
    end
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render()
    return self
end
