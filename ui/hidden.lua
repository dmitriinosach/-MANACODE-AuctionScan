local _, ns = ...
local UI = {props = {}, rows = {}}
ns.HiddenUI = UI
function UI:SetProps(props)
    for key, value in pairs(props) do self.props[key] = value end
    self.selected = nil; self.scroll.offset = 0; self:Render()
end
function UI:Entries()
    return ns.Hidden.Recipes(self.props.profession, self.props.category)
end
function UI:Render()
    if not self.frame then return end
    local K, p = ns.TradeKit, self.props
    local entries = self.sorter:Apply(self:Entries(), {
        item = function(recipe) return ns.Markets.Name(recipe.raw) end,
        price = function(recipe) local q = ns.Markets.Quote(recipe.raw); return q and q.price end,
        units = function(recipe) local q = ns.Markets.Quote(recipe.raw); return q and q.units end,
    })
    local catalog = p.profession and ns.craftCatalogs[p.profession]
    self.profession.frame:SetText(ns.T(catalog and catalog.labelKey or "hiddenAllProfessions"))
    self.category.frame:SetText(ns.T(p.category or "hiddenAllCategories"))
    local width = (self.frame:GetWidth() or 996) - 310
    local columns = K.MarketColumns(width - 70)
    for key, label in pairs(self.headers) do
        label:ClearAllPoints(); label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + columns[key][1], -38)
        label:SetWidth(columns[key][2])
    end
    self.sorter:Mark()
    self.title:SetText(ns.T("hiddenTitle", #entries))
    local visible = K.ListCapacity(self.frame, 56, 56, 29, #self.rows)
    local offset = self.scroll:SetRange(#entries, visible)
    local selected
    for _, recipe in ipairs(entries) do if recipe.raw == self.selected then selected = recipe end end
    if not selected then selected = entries[1]; self.selected = selected and selected.raw end
    for i, row in ipairs(self.rows) do
        local recipe = i <= visible and entries[offset + i]
        if recipe then
            local q = ns.Markets.Quote(recipe.raw)
            row:SetProps({id = recipe.raw, quote = q, width = width, reserve = 70, reveal = true, active = recipe.raw == self.selected,
                detail = ns.T(ns.craftCatalogs[recipe.profession].labelKey) .. " | " .. ns.T(recipe.category),
                hidden = true, hideable = true, noRefresh = true, hideLabel = ns.T("hiddenRestore")})
        else row.frame:Hide() end
    end
    self.empty:SetText(#entries == 0 and ns.T("hiddenEmpty") or "")
    if selected then self.inspector:SetProps({id = selected.raw}) else self.inspector:Clear() end
    self.summary:SetText(ns.T("hiddenHint"))
    if #entries > 0 then self.restoreAll:Enable() else self.restoreAll:Disable() end
end
function UI:New(parent)
    local K = ns.TradeKit
    local f = ns.NewFrame("Frame", nil, parent); f:SetAllPoints(parent); self.frame = f
    local professions = {{key = "all", labelKey = "hiddenAllProfessions"}}
    for _, key in ipairs(ns.Crafting.order) do
        if ns.craftCatalogs[key] then professions[#professions + 1] = {key = key, labelKey = ns.craftCatalogs[key].labelKey} end
    end
    self.profession = K.Menu(f, professions, function(key)
        self:SetProps({profession = key ~= "all" and key or false, category = false})
    end)
    self.profession.frame:SetWidth(190); self.profession.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -3)
    local categories = {{key = "all", labelKey = "hiddenAllCategories"}}
    for _, key in ipairs(ns.Hidden.Categories()) do categories[#categories + 1] = {key = key, labelKey = key} end
    self.category = K.Menu(f, categories, function(key) self:SetProps({category = key ~= "all" and key or false}) end)
    self.category.frame:SetWidth(190); self.category.frame:SetPoint("LEFT", self.profession.frame, "RIGHT", 8, 0)
    self.title = K.Label(f, "", 410, -11, 240, "heading")
    self.restoreAll = K.Button(f, ns.T("hiddenRestoreAll"), 140, function()
        ns.Hidden.Restore(self.props.profession or nil, self.props.category or nil); ns.Trader.Refresh()
    end, "main")
    self.restoreAll:SetPoint("TOPRIGHT", f, "TOPRIGHT", -282, -5)
    K.Tooltip(self.restoreAll, ns.T("hiddenRestoreAll"), ns.T("hiddenRestoreAllTip"))
    K.TableHeader(f, -38)
    self.headers = {}
    for _, entry in ipairs({{"item", "hiddenColumn"}, {"price", "tradeUnitPrice"}, {"units", "tradeUnits"}}) do
        self.headers[entry[1]] = K.Label(f, ns.T(entry[2]), 0, -38, 100)
        if entry[1] ~= "item" then self.headers[entry[1]]:SetJustifyH("RIGHT") end
    end
    self.sorter = K.Sorter(f, self.headers, function() self.scroll.offset = 0; self:Render() end)
    self.headers.margin = K.Label(f, "", 0, -38, 100)
    self.scroll = K.TableScroll(f, function() self:Render() end, 56, 56, 29)
    for i = 1, 40 do
        local row = K.MarketRow:New(f, function(id) self.selected = id; self:Render() end, nil, nil,
            function(id) ns.Hidden.Toggle(id); ns.Trader.Refresh() end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -56 - (i - 1) * 29)
        row.frame:SetHeight(28); self.rows[i] = row; self.scroll:Wheel(row.frame)
    end
    self.empty = K.Label(f, "", 10, -66, 440); self.empty:SetHeight(64)
    self.inspector = K.Inspector:New(f)
    self.summary = K.Label(self.inspector.body, "", 12, -48, 240)
    self.summary:SetHeight(200); self.summary:SetJustifyV("TOP")
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render(); return self
end
