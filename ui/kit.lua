local _, ns = ...
local K = {}
ns.TradeKit = K
function K.Money(copper)
    if not copper then return ns.T("tradeNoPrice") end
    return (copper < 0 and "-" or "") .. GetCoinTextureString(math.floor(math.abs(copper) + 0.5))
end
K.theme = {
    white = "Interface\\Buttons\\WHITE8X8",
    marble = "Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-L1",
    highlight = "Interface\\QuestFrame\\UI-QuestTitleHighlight",
    button = "Interface\\Buttons\\UI-Panel-Button-",
    text = {0.94, 0.95, 0.97}, secondary = {0.76, 0.72, 0.62},
    gold = {1, 0.82, 0}, positive = {0.4, 1, 0.5}, negative = {1, 0.35, 0.3},
    background = {0.03, 0.04, 0.05, 1}, panel = {0.06, 0.07, 0.09, 1},
    edge = {0.40, 0.42, 0.48, 0.9}, line = {1, 1, 1, 0.07},
    row = {1, 1, 1, 0.025}, selected = {0.62, 0.48, 0.18, 0.22},
    hover = {1, 1, 1, 0.08}, head = {0.40, 0.36, 0.30, 0.35},
    buttonSkin = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16,
        edgeSize = 12, insets = {left = 3, right = 3, top = 3, bottom = 3}},
    control = {bg = {0.10, 0.11, 0.13, 1}, hover = {0.17, 0.18, 0.21, 1},
        down = {0.06, 0.065, 0.08, 1}, edge = {0.42, 0.44, 0.50, 0.9}},
    main = {bg = {0.165, 0.13, 0.03, 1}, hover = {0.23, 0.18, 0.04, 1},
        down = {0.11, 0.085, 0.02, 1}, edge = {0.72, 0.60, 0.16, 1}},
    quiet = {bg = {0, 0, 0, 0}, hover = {1, 1, 1, 0.04},
        down = {0, 0, 0, 0.25}, edge = {0.18, 0.21, 0.26, 1}},
    off = {0.60, 0.58, 0.54},
    chart = {grid = {1, 1, 1, 0.07}, axis = {1, 1, 1, 0.20}, cursor = {1, 0.95, 0.75, 0.6},
        shade = {0, 0, 0, 0.8}, median = {0.72, 0.80, 0.92, 0.55}, minimum = {1, 0.82, 0},
        quartile = {0.40, 0.85, 0.50}, supply = {0.30, 0.56, 0.80}, added = {0.34, 0.68, 0.46},
        early = {0.86, 0.62, 0.30}, late = {0.60, 0.60, 0.64}, tile = {0.08, 0.09, 0.11, 1}},
}
function K.Label(parent, text, x, y, width, kind)
    local font = kind == "heading" and "GameFontNormal" or "GameFontHighlightSmall"
    local fs = parent:CreateFontString(nil, "OVERLAY", font)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetWidth(width)
    fs:SetJustifyH("LEFT")
    fs:SetTextColor(unpack(K.theme[kind == "heading" and "gold" or "text"]))
    fs:SetText(text)
    return fs
end
function K.Background(parent)
    local base = parent:CreateTexture(nil, "BACKGROUND")
    base:SetAllPoints(parent)
    base:SetTexture(K.theme.white)
    base:SetVertexColor(unpack(K.theme.background))
    return base
end
function K.Panel(parent)
    if not rawget(parent, "tradeBase") then parent.tradeBase = K.Background(parent) end
    parent:SetBackdrop({edgeFile = K.theme.buttonSkin.edgeFile, edgeSize = 12,
        insets = K.theme.buttonSkin.insets})
    parent:SetAlpha(1)
    parent:SetBackdropColor(unpack(K.theme.panel))
    parent:SetBackdropBorderColor(unpack(K.theme.edge))
end
function K.ScanMode()
    if IsShiftKeyDown() then return true end
    if IsControlKeyDown and IsControlKeyDown() then return "missing" end
    return false
end
function K.Tooltip(parent, title, body)
    parent.tipTitle, parent.tip = title, body
    if rawget(parent, "tradeTipHooked") then return end
    parent.tradeTipHooked = true
    parent:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.tipTitle, unpack(K.theme.text))
        GameTooltip:AddLine(self.tipFn and self.tipFn() or self.tip, K.theme.gold[1], K.theme.gold[2], K.theme.gold[3], true)
        GameTooltip:Show()
    end)
    parent:HookScript("OnLeave", function() GameTooltip:Hide() end)
end
function K.StyleButton(b)
    local skin = K.theme[b.kind] or K.theme.control
    local fill = b.active and K.theme.main.bg or skin[b.pressed and "down" or (b.hovered and "hover" or "bg")]
    local edge = b.active and K.theme.main.edge or skin.edge
    b:SetBackdropColor(unpack(fill))
    b:SetBackdropBorderColor(unpack(edge))
    b.text:SetTextColor(unpack(b.btnDisabled and K.theme.off
        or ((b.active or b.kind == "main") and K.theme.gold or K.theme.text)))
end
function K.Button(parent, text, width, fn, kind)
    local b = ns.NewFrame("Button", nil, parent)
    b.kind, b.onClick = kind, fn
    b.active, b.btnDisabled, b.hovered, b.pressed = false, false, false, false
    b:SetWidth(width)
    b:SetHeight(22)
    b:SetNormalFontObject("GameFontNormalSmall")
    b:SetHighlightFontObject("GameFontHighlightSmall")
    b:SetDisabledFontObject("GameFontHighlightSmall")
    local textRegion = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    textRegion:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:SetFontString(textRegion)
    b.text = textRegion
    textRegion:ClearAllPoints()
    textRegion:SetPoint("LEFT", b, "LEFT", 7, 0)
    textRegion:SetPoint("RIGHT", b, "RIGHT", -7, 0)
    textRegion:SetJustifyH("CENTER")
    b:SetText(text)
    b:SetBackdrop(K.theme.buttonSkin)
    b.nativeEnable, b.nativeDisable = b.Enable, b.Disable
    b.Enable = function(self) self.btnDisabled = false; self.nativeEnable(self); K.StyleButton(self) end
    b.Disable = function(self) self.btnDisabled = true; self.nativeDisable(self); K.StyleButton(self) end
    b.SetActive = function(self, active) self.active = active and true or false; K.StyleButton(self) end
    b:SetScript("OnEnter", function(self) self.hovered = true; K.StyleButton(self) end)
    b:SetScript("OnLeave", function(self) self.hovered, self.pressed = false, false; K.StyleButton(self) end)
    b:SetScript("OnMouseDown", function(self) self.pressed = not self.btnDisabled; K.StyleButton(self) end)
    b:SetScript("OnMouseUp", function(self) self.pressed = false; K.StyleButton(self) end)
    b:SetScript("OnClick", function(self, button)
        if not self.btnDisabled and self.onClick then self.onClick(self, button) end
    end)
    K.StyleButton(b)
    return b
end
function K.Navigation(parent, text, fn)
    local b = ns.NewFrame("Button", nil, parent)
    b:SetWidth(158)
    b:SetHeight(27)
    b.text = K.Label(b, text, 9, -7, 144)
    b.selected = b:CreateTexture(nil, "BACKGROUND")
    b.selected:SetAllPoints(b)
    b.selected:SetTexture(K.theme.white)
    b.selected:SetVertexColor(unpack(K.theme.selected))
    b.selected:Hide()
    local hover = b:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(b); hover:SetTexture(K.theme.white)
    hover:SetVertexColor(unpack(K.theme.hover)); b:SetHighlightTexture(hover)
    b.onClick = fn
    b:SetScript("OnClick", function(self, button) if self.onClick then self.onClick(self, button) end end)
    return b
end
function K.Edit(parent, width)
    local edit = ns.NewFrame("EditBox", nil, parent)
    edit:SetWidth(width)
    edit:SetHeight(22)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetTextInsets(6, 6, 0, 0)
    edit:SetBackdrop({ bgFile = K.theme.white, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    edit:SetBackdropColor(unpack(K.theme.background))
    edit:SetBackdropBorderColor(unpack(K.theme.control.edge))
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return edit
end
function K.Check(parent, changed)
    local check = ns.NewFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetWidth(18); check:SetHeight(18)
    check:SetScript("OnClick", function(self) changed(self:GetChecked() and true or false) end)
    return check
end
function K.ItemChoice(parent, fn)
    local b = K.Navigation(parent, "", fn)
    b:SetWidth(192)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetWidth(20)
    b.icon:SetHeight(20)
    b.icon:SetPoint("LEFT", b, "LEFT", 2, 0)
    b.text:ClearAllPoints()
    b.text:SetPoint("LEFT", b, "LEFT", 28, 0)
    b.text:SetWidth(160)
    b.text:SetHeight(14)
    b:SetScript("OnEnter", function(self)
        if not self.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. self.itemID)
        if ns.Markets then
            local q = ns.Markets.Quote(self.itemID)
            if q and q.vendor then
                GameTooltip:AddLine(ns.T("cacheVendorPrice", K.Money(q.price)), 1, 0.82, 0, true)
            elseif q then
                GameTooltip:AddLine(ns.T("cacheObserved", date("%d.%m %H:%M", q.at)), 1, 0.82, 0, true)
                if q.shared then GameTooltip:AddLine(ns.T("sharedQuote"), 1, 0.82, 0, true) end
                GameTooltip:AddLine(ns.T("offersTooltip", q.units or 0, q.lots or 0), 1, 1, 1, true)
            end
        end
        if self.extraTip then GameTooltip:AddLine(self.extraTip, 1, 0.82, 0, true) end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end
function K.SetItemChoice(b, id, active, quality)
    b.itemID = id
    local _, _, rarity = ns.Compat.ItemInfo(id)
    b.quality = quality or rarity
    b.text:SetText(ns.Markets.Name(id))
    if b.quality and type(GetItemQualityColor) == "function" then
        local r, g, blue = GetItemQualityColor(b.quality)
        b.text:SetTextColor(r, g, blue)
    else b.text:SetTextColor(unpack(K.theme.text)) end
    b.icon:SetTexture(select(10, ns.Compat.ItemInfo(id)))
    if active then b.selected:Show() else b.selected:Hide() end
    b:Show()
end
function K.Rule(parent, y)
    local line = parent:CreateTexture(nil, "BORDER")
    line:SetTexture(K.theme.white); line:SetVertexColor(unpack(K.theme.line))
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, y); line:SetHeight(1)
    return line
end
function K.TableHeader(parent, y)
    local band = parent:CreateTexture(nil, "BACKGROUND")
    band:SetTexture(K.theme.white); band:SetVertexColor(unpack(K.theme.head))
    band:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y + 5)
    band:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -302, y + 5); band:SetHeight(20)
    return band
end
local Sorter = {}
Sorter.__index = Sorter
function K.Sorter(frame, headers, changed, active)
    local sorter = setmetatable({buttons = {}, headers = headers, changed = changed, active = active}, Sorter)
    for key, label in pairs(headers) do
        local button = ns.NewFrame("Button", nil, frame)
        button:SetAllPoints(label)
        button:EnableMouse(true)
        button.arrow = button:CreateTexture(nil, "OVERLAY")
        button.arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
        button.arrow:SetWidth(9); button.arrow:SetHeight(9); button.arrow:Hide()
        button:SetScript("OnClick", function() sorter:Click(key) end)
        K.Tooltip(button, ns.T("sortTitle"), ns.T("sortTip"))
        sorter.buttons[key] = button
    end
    return sorter
end
function Sorter:Click(key)
    local current = self.sort
    if current and current.key == key then
        if current.desc == (key ~= "item") then self.sort = {key = key, desc = not current.desc}
        else self.sort = nil end
    else self.sort = {key = key, desc = key ~= "item"} end
    self.changed()
end
function Sorter:Mark()
    local usable = not self.active or self.active()
    for key, button in pairs(self.buttons) do
        local label = self.headers[key]
        if usable and label:IsShown() then button:Show() else button:Hide() end
        local current = self.sort
        button.arrow:ClearAllPoints()
        if usable and current and current.key == key then
            local width = (label.GetStringWidth and label:GetStringWidth()) or 40
            if key == "item" then button.arrow:SetPoint("LEFT", button, "LEFT", width + 4, 0)
            else button.arrow:SetPoint("RIGHT", button, "RIGHT", -(width + 4), 0) end
            if current.desc then button.arrow:SetTexCoord(0, 0.5625, 0, 1) else button.arrow:SetTexCoord(0, 0.5625, 1, 0) end
            button.arrow:Show()
        else button.arrow:Hide() end
    end
end
function Sorter:Apply(entries, getters, group)
    local current = self.sort
    local get = current and getters[current.key]
    if not get then return entries end
    local keyed = {}
    for i, entry in ipairs(entries) do keyed[i] = {entry = entry, value = get(entry), index = i, first = group and group(entry) or false} end
    table.sort(keyed, function(a, b)
        if a.first ~= b.first then return a.first end
        if a.value ~= b.value then
            if a.value == nil then return false end
            if b.value == nil then return true end
            if current.desc then return a.value > b.value end
            return a.value < b.value
        end
        return a.index < b.index
    end)
    local result = {}
    for i, item in ipairs(keyed) do result[i] = item.entry end
    return result
end
local Inspector = {mode = "summary", all = {}}
Inspector.__index = Inspector
K.Inspector = Inspector
function Inspector:New(parent)
    local view = setmetatable({parent = parent, top = -2}, self)
    local panel = ns.NewFrame("Frame", nil, parent)
    view.frame = panel
    panel:SetFrameLevel(parent:GetFrameLevel() + 12)
    panel:EnableMouse(true); K.Panel(panel)
    view.item = K.ItemChoice(panel, function() Inspector.Switch("market") end)
    view.item.extraTip = ns.T("itemHistoryOpenTip")
    view.item:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -8)
    view.item:SetWidth(180); view.item.text:SetWidth(148)
    view.offers = K.Button(panel, ns.T("offersOpen"), 54, function()
        if view.item.itemID then ns.OfferPreview.Open(view.item.itemID) end
    end, "quiet")
    view.offers:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -10)
    K.Tooltip(view.offers, ns.T("offersTitle"), ns.T("offersOpenTip"))
    if ns.Collections then
        view.actions = K.Menu(panel, {{key = "favorite", labelKey = "collectionFavorite"},
            {key = "tracked", labelKey = "collectionTrack"}}, function(key)
            local id = view.item.itemID
            if not id then return end
            if key == "favorite" then ns.Collections.ToggleFavorite(id) else ns.Collections.ToggleTracked(id) end
            ns.Trader.Refresh()
        end)
        view.actions.frame:SetWidth(24); view.actions.frame:SetText("+"); view.actions.frame.arrow:Hide()
        view.actions.frame.text:ClearAllPoints(); view.actions.frame.text:SetPoint("CENTER", view.actions.frame, "CENTER", 0, 0)
        view.actions.frame:SetPoint("RIGHT", view.offers, "LEFT", -6, 0)
        K.Tooltip(view.actions.frame, ns.T("collectionActions"), ns.T("collectionActionsTip"))
    end
    view.tabs = {
        summary = K.Button(panel, ns.T("inspectorSummary"), 117, function() Inspector.Switch("summary") end, "quiet"),
        market = K.Button(panel, ns.T("inspectorMarket"), 117, function() Inspector.Switch("market") end, "quiet"),
    }
    view.tabs.market:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -38)
    view.tabs.summary:SetPoint("RIGHT", view.tabs.market, "LEFT", -6, 0)
    K.Tooltip(view.tabs.summary, ns.T("inspectorSummary"), ns.T("inspectorSummaryTip"))
    K.Tooltip(view.tabs.market, ns.T("inspectorMarket"), ns.T("inspectorMarketTip"))
    K.Rule(panel, -66)
    view.body = ns.NewFrame("Frame", nil, panel)
    view.body:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -26)
    view.body:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    panel:HookScript("OnShow", function() view:Layout() end)
    Inspector.all[#Inspector.all + 1] = view
    view:Layout()
    return view
end
function Inspector.Switch(mode)
    Inspector.mode = mode == "market" and "market" or "summary"
    for _, view in ipairs(Inspector.all) do view:Layout() end
end
function Inspector:Place(top)
    if self.top == top then return end
    self.top = top; self:Layout()
end
function Inspector:Layout()
    local panel, market = self.frame, Inspector.mode == "market"
    panel:ClearAllPoints()
    panel:SetPoint("TOPRIGHT", self.parent, "TOPRIGHT", -6, self.top)
    panel:SetPoint("BOTTOMRIGHT", self.parent, "BOTTOMRIGHT", -6, 2)
    local item = market and 300 or (self.actions and 150 or 180)
    self.item:SetWidth(item); self.item.text:SetWidth(item - 32)
    self.tabs.summary:SetActive(not market); self.tabs.market:SetActive(market)
    if market then
        panel:SetPoint("TOPLEFT", self.parent, "TOPLEFT", 6, self.top)
        self.body:Hide()
    else
        panel:SetWidth(264); self.body:Show()
    end
    local id = self.props and self.props.id
    if market and id and panel:IsVisible() then
        self.board = self.board or ns.MarketBoardUI:New(panel)
        self.board:SetProps({id = id})
    elseif self.board then self.board.frame:Hide() end
end
function Inspector:SetProps(props)
    self.props = props; self:Render()
end
function Inspector:Clear()
    self.props = nil
    self.item:Hide(); self.offers:Hide()
    if self.actions then self.actions.frame:Hide() end
    self:Layout()
end
function Inspector:Render()
    K.SetItemChoice(self.item, self.props.id, self.props.active)
    self.offers:Show()
    if self.actions then
        self.actions.frame:Show()
        local C, id = ns.Collections, self.props.id
        self.actions.buttons[1].text:SetText(ns.T(C.Favorite(id) and "collectionUnfavorite" or "collectionFavorite"))
        self.actions.buttons[2].text:SetText(ns.T(C.Tracked(id) and "collectionUntrack" or "collectionTrack"))
        if C.CanFavorite(id) then self.actions.buttons[1]:Enable() else self.actions.buttons[1]:Disable() end
    end
    self:Layout()
end
function K.Selector(b)
    b:SetBackdrop(K.theme.buttonSkin)
    b:SetBackdropColor(unpack(K.theme.control.bg))
    b:SetBackdropBorderColor(unpack(K.theme.control.edge))
    b.arrow = b:CreateTexture(nil, "ARTWORK")
    b.arrow:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
    b.arrow:SetTexCoord(0, 0.9375, 0.9375, 0.4375)
    b.arrow:SetWidth(11); b.arrow:SetHeight(6)
    b.arrow:SetPoint("RIGHT", b, "RIGHT", -8, 0)
end
local QuoteEditor = {}
QuoteEditor.__index = QuoteEditor
K.QuoteEditor = QuoteEditor
function QuoteEditor:New(parent, save, refresh)
    local view = setmetatable({}, self)
    view.frame = ns.NewFrame("Frame", nil, parent); view.frame:SetHeight(30)
    view.item = K.ItemChoice(view.frame, function() ns.Trader.OpenReagent(view.props.id) end)
    view.item:SetPoint("LEFT", view.frame, "LEFT", 0, 0)
    view.cell = view.frame:CreateTexture(nil, "BACKGROUND")
    view.cell:SetAllPoints(view.frame); view.cell:SetTexture(K.theme.white)
    view.cell:SetVertexColor(unpack(K.theme.row))
    view.edit = K.Edit(view.frame, 70)
    view.edit:SetPoint("RIGHT", view.frame, "RIGHT", -104, 0)
    view.unit = K.Label(view.frame, ns.T("deGold"), 0, 0, 12)
    view.unit:ClearAllPoints(); view.unit:SetPoint("LEFT", view.edit, "RIGHT", 3, 0)
    view.unit:SetTextColor(unpack(K.theme.gold))
    view.coin = K.Label(view.frame, "", 0, 0, 96)
    view.coin:ClearAllPoints(); view.coin:SetPoint("RIGHT", view.edit, "LEFT", -8, 0)
    view.coin:SetJustifyH("RIGHT")
    view.edit:SetScript("OnTextChanged", function(_, user) if user then view.draft = true end end)
    view.edit:SetScript("OnEnterPressed", function()
        if view.props.disabled then return end
        local value = tonumber((view.edit:GetText():gsub(",", ".")))
        if not value or not save(view.props.id, value * 10000) then ns.say(ns.T("alchemyInvalidPrice")); return end
        view.draft = false; view.edit:ClearFocus(); ns.Trader.Refresh()
    end)
    view.edit:SetScript("OnEscapePressed", function()
        if view.props.disabled then return end
        save(view.props.id, nil); view.draft = false; view.edit:ClearFocus(); ns.Trader.Refresh()
    end)
    K.Tooltip(view.edit, ns.T("deSellPrice"), ns.T("deSellPriceTip"))
    view.refresh = K.Button(view.frame, ns.T("tradeUpdate"), 84, function()
        save(view.props.id, nil); view.draft = false; refresh(view.props.id)
    end, "quiet")
    view.refresh:SetPoint("RIGHT", view.frame, "RIGHT", 0, 0)
    K.Tooltip(view.refresh, ns.T("cacheRefreshItem"), ns.T("dePriceRefreshTip"))
    return view
end
function QuoteEditor:SetProps(props)
    if not self.props or self.props.id ~= props.id then self.draft = false end
    self.props = props; self:Render()
end
function QuoteEditor:Render()
    local p = self.props
    self.frame:SetWidth(p.width)
    K.SetItemChoice(self.item, p.id, false)
    self.item:SetWidth(p.width - 270); self.item.text:SetWidth(math.max(30, p.width - 300))
    self.coin:SetText(K.Money(p.quote and p.quote.price))
    self.coin:SetTextColor(unpack(K.theme[p.quote and p.quote.manual and "gold" or "text"]))
    if not self.draft then self.edit:SetText(p.quote and p.quote.price and string.format("%.4f", p.quote.price / 10000) or "") end
    self.edit:EnableMouse(not p.disabled)
    if p.disabled then self.edit:ClearFocus(); self.refresh:Disable() else self.refresh:Enable() end
    self.frame:Show()
end
local Picker = {}
Picker.__index = Picker
K.FamilyPicker = Picker
local Scroller = {}
Scroller.__index = Scroller
K.Scroller = Scroller
local scrollSerial = 0
function Scroller:New(parent, changed, rowHeight)
    scrollSerial = scrollSerial + 1
    local scroll = setmetatable({offset = 0, count = 0, visible = 1, changed = changed, step = rowHeight}, self)
    scroll.frame = ns.NewFrame("Frame", nil, parent)
    scroll.frame:SetFrameLevel(parent:GetFrameLevel())
    scroll.frame:EnableMouse(true)
    scroll.bar = ns.NewFrame("Slider", "ManaCodeAuctionScroll" .. scrollSerial, scroll.frame, "UIPanelScrollBarTemplate")
    scroll.bar:SetPoint("TOPRIGHT", scroll.frame, "TOPRIGHT", 0, -16)
    scroll.bar:SetPoint("BOTTOMRIGHT", scroll.frame, "BOTTOMRIGHT", 0, 16)
    scroll.bar:SetValueStep(rowHeight)
    scroll.bar:SetScript("OnValueChanged", function(_, value)
        if scroll.muted then return end
        scroll:SetOffset(math.floor(value / rowHeight + 0.5))
    end)
    scroll:Wheel(scroll.frame)
    scroll:Wheel(scroll.bar)
    return scroll
end
function Scroller:Wheel(frame)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta) self:SetOffset(self.offset - delta * 3) end)
end
function Scroller:SetOffset(offset)
    offset = math.max(0, math.min(math.floor(offset), math.max(0, self.count - self.visible)))
    if offset == self.offset then return end
    self.offset = offset
    self.changed()
end
function Scroller:SetRange(count, visible)
    self.count, self.visible = count, math.max(1, visible)
    self.offset = math.max(0, math.min(self.offset, math.max(0, count - self.visible)))
    self.muted = true
    self.bar:SetMinMaxValues(0, math.max(0, count - self.visible) * self.step)
    self.bar:SetValue(self.offset * self.step)
    self.muted = false
    if count > self.visible then self.bar:Show() else self.bar:Hide() end
    return self.offset
end
function K.TableScroll(parent, changed, top, bottom, rowHeight)
    local scroll = Scroller:New(parent, changed, rowHeight)
    scroll.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -top)
    scroll.frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -280, bottom)
    return scroll
end
function K.ListCapacity(frame, top, bottom, rowHeight, maximum)
    return math.max(1, math.min(maximum, math.floor(((frame:GetHeight() or 510) - top - bottom) / rowHeight)))
end
local function cursor(parent)
    local x, y = GetCursorPosition()
    local scale = parent:GetEffectiveScale() or 1
    return x / scale, y / scale
end
local function clamp(value, low, high)
    return math.max(low, math.min(high, math.floor(value + 0.5)))
end
function K.ResizeGrip(parent, limits, allowed, apply)
    local outline = ns.NewFrame("Frame", nil, parent)
    outline:SetFrameStrata("DIALOG")
    outline:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    outline:SetBackdrop({bgFile = K.theme.white, edgeFile = K.theme.white, edgeSize = 2})
    outline:SetBackdropColor(K.theme.gold[1], K.theme.gold[2], K.theme.gold[3], 0.08)
    outline:SetBackdropBorderColor(K.theme.gold[1], K.theme.gold[2], K.theme.gold[3], 0.9)
    outline.size = outline:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    outline.size:SetPoint("BOTTOMRIGHT", outline, "BOTTOMRIGHT", -28, 14)
    outline:Hide()
    local function measure()
        local x, y = cursor(parent)
        return clamp(outline.width0 + x - outline.x0, limits[1], limits[3]),
            clamp(outline.height0 + outline.y0 - y, limits[2], limits[4])
    end
    local function follow(self)
        local width, height = measure()
        if width == self.width and height == self.height then return end
        self.width, self.height = width, height
        self:SetWidth(width); self:SetHeight(height)
        self.size:SetFormattedText("%d x %d", width, height)
    end
    local function stop()
        outline.active = false
        outline:SetScript("OnUpdate", nil)
        outline:Hide()
    end
    local grip = ns.NewFrame("Button", nil, parent)
    grip:SetWidth(16); grip:SetHeight(16)
    grip:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetFrameLevel(parent:GetFrameLevel() + 30)
    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or not allowed() then return end
        outline.x0, outline.y0 = cursor(parent)
        outline.width0, outline.height0 = parent:GetWidth(), parent:GetHeight()
        outline.width, outline.height = nil, nil
        outline.active = true
        follow(outline)
        outline:SetScript("OnUpdate", follow)
        outline:Show()
        GameTooltip:Hide()
    end)
    grip:SetScript("OnMouseUp", function()
        if not outline.active then return end
        local width, height = measure()
        stop()
        apply(width, height)
    end)
    grip:SetScript("OnHide", stop)
    K.Tooltip(grip, ns.T("windowResize"), ns.T("windowResizeTip"))
    grip.outline = outline
    return grip
end
function K.AuctionArt(parent)
    local fills = {}
    for i = 1, 3 do fills[i] = parent:CreateTexture(nil, "ARTWORK") end
    return fills
end
function K.LayoutAuctionArt(parent, width, height, fills)
    local delta = height - 447
    if AuctionFrameTop then AuctionFrameTop:SetWidth(width - 512) end
    for i, suffix in ipairs({"Left", "", "Right"}) do
        local source = _G["AuctionFrameBot" .. suffix]
        local left = i == 1 and 0 or (i == 2 and 256 or width - 256)
        local size = i == 2 and width - 512 or 256
        if source then
            source:ClearAllPoints(); source:SetPoint("TOPLEFT", parent, "TOPLEFT", left, -256 - delta)
            source:SetWidth(size); source:SetHeight(256)
        end
        local fill = fills[i]
        if delta > 0 and source and source:GetTexture() then
            fill:SetTexture(source:GetTexture()); fill:SetTexCoord(0, 1, 0, 0.25)
            fill:ClearAllPoints(); fill:SetPoint("TOPLEFT", parent, "TOPLEFT", left, -256)
            fill:SetWidth(size); fill:SetHeight(delta); fill:Show()
        else fill:Hide() end
    end
end
function K.Menu(parent, entries, choose)
    local menu = {buttons = {}}
    menu.frame = K.Button(parent, "", 184, function()
        if menu.cover:IsShown() then menu.cover:Hide() else menu.cover:Show() end
    end)
    K.Selector(menu.frame)
    menu.frame.text:SetJustifyH("LEFT")
    menu.frame.text:ClearAllPoints()
    menu.frame.text:SetPoint("LEFT", menu.frame, "LEFT", 8, 0)
    menu.frame.text:SetPoint("RIGHT", menu.frame, "RIGHT", -23, 0)
    menu.cover = ns.NewFrame("Button", nil, parent)
    menu.cover:SetAllPoints(parent)
    menu.cover:SetFrameLevel(parent:GetFrameLevel() + 20)
    menu.cover:SetScript("OnClick", function() menu.cover:Hide() end)
    menu.cover:Hide()
    parent:HookScript("OnHide", function() menu.cover:Hide() end)
    local panel = ns.NewFrame("Frame", nil, menu.cover)
    panel:SetPoint("TOPLEFT", menu.frame, "BOTTOMLEFT", 0, -2)
    panel:SetWidth(210); panel:SetHeight(#entries * 28 + 16)
    panel:EnableMouse(true)
    K.Panel(panel)
    for i, entry in ipairs(entries) do
        local button = K.Navigation(panel, ns.T(entry.labelKey), function()
            menu.cover:Hide(); choose(entry.key)
        end)
        button:SetWidth(194)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -8 - (i - 1) * 28)
        menu.buttons[i] = button
    end
    return menu
end
function K.ProfessionModes(parent, profession, mode)
    local menu = K.Menu(parent, {{key = "craft", labelKey = "professionCrafts"},
        {key = "resale", labelKey = "vendorResaleCategory"}}, function(value)
        ns.Trader.SetProfessionMode(profession(), value)
    end)
    menu.frame:SetWidth(100)
    menu.frame:SetText(ns.T(mode == "resale" and "vendorResaleCategory" or "professionCrafts"))
    menu.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -3)
    return menu
end
function Picker:New(parent, choose)
    local picker = setmetatable({rows = {}, choose = choose}, self)
    picker.frame = K.ItemChoice(parent, function()
        if picker.cover:IsShown() then picker.cover:Hide() else picker.cover:Show(); picker:Render() end
    end)
    K.Selector(picker.frame)
    picker.frame.text:SetPoint("RIGHT", picker.frame, "RIGHT", -24, 0)
    picker.cover = ns.NewFrame("Button", nil, parent)
    picker.cover:SetAllPoints(parent)
    picker.cover:SetFrameLevel(parent:GetFrameLevel() + 15)
    picker.cover:SetScript("OnClick", function() picker.cover:Hide() end)
    picker.cover:Hide()
    parent:HookScript("OnHide", function() picker.cover:Hide() end)
    local menu = ns.NewFrame("Frame", nil, picker.cover)
    menu:SetPoint("TOPLEFT", picker.frame, "BOTTOMLEFT", 0, -2)
    menu:SetWidth(300); menu:SetHeight(364)
    menu:EnableMouse(true)
    K.Panel(menu)
    picker.heading = K.Label(menu, "", 10, -10, 258, "heading")
    picker.scroll = Scroller:New(menu, function() picker:Render() end, 27)
    picker.scroll.frame:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -31)
    picker.scroll.frame:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -8, 8)
    for i = 1, 12 do
        local row = K.ItemChoice(menu, function()
            local family = picker.props.families[picker.scroll.offset + i]
            if family then picker.cover:Hide(); picker.choose(family.raw) end
        end)
        row:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -31 - (i - 1) * 27)
        row:SetWidth(264); row.text:SetWidth(230)
        picker.rows[i] = row
        picker.scroll:Wheel(row)
    end
    return picker
end
function Picker:SetProps(props)
    if ns.Collections then
        local ordered = {}
        for key, value in pairs(props) do ordered[key] = value end
        ordered.families = ns.Collections.Order(props.families)
        props = ordered
    end
    if not self.props or self.props.raw ~= props.raw then
        for i, family in ipairs(props.families) do
            if family.raw == props.raw then self.scroll.offset = math.max(0, i - 6); break end
        end
    end
    self.props = props
    self:Render()
end
function Picker:Render()
    local props = self.props
    if not props then return end
    local offset = self.scroll:SetRange(#props.families, #self.rows)
    K.SetItemChoice(self.frame, props.raw, false)
    self.heading:SetText(ns.T(props.headingKey or "familyFamilies"))
    for i, row in ipairs(self.rows) do
        local family = props.families[offset + i]
        if family then K.SetItemChoice(row, family.raw, family.raw == props.raw) else row:Hide() end
    end
end
local ItemRow = {}
ItemRow.__index = ItemRow
K.ItemRow = ItemRow
function ItemRow:New(parent)
    local row = setmetatable({}, self)
    row.frame = ns.NewFrame("Button", nil, parent)
    row.frame:SetHeight(36)
    row.frame:SetHighlightTexture(K.theme.highlight, "ADD")
    row.icon = row.frame:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(28)
    row.icon:SetHeight(28)
    row.icon:SetPoint("LEFT", row.frame, "LEFT", 2, 0)
    row.name = K.Label(row.frame, "", 36, -3, 213)
    row.role = K.Label(row.frame, "", 36, -18, 213)
    row.role:SetTextColor(unpack(K.theme.secondary))
    row.price = K.Label(row.frame, "", 253, -10, 94)
    row.volume = K.Label(row.frame, "", 351, -10, 42)
    row.age = K.Label(row.frame, "", 397, -10, 65)
    row.update = K.Button(row.frame, ns.T("tradeUpdate"), 74, function() ns.Markets.Scan(row.props.id) end)
    row.update:SetPoint("RIGHT", row.frame, "RIGHT", -2, 0)
    row.buy = K.Button(row.frame, ns.T("tradeBuy"), 64, function()
        if ns.Trader and ns.Trader.OpenBuy then ns.Trader.OpenBuy(row.props.id) end
    end)
    row.buy:SetPoint("RIGHT", row.update, "LEFT", -4, 0)
    row.name:SetWidth(180)
    row.role:SetWidth(180)
    row.price:ClearAllPoints()
    row.price:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 220, -10)
    row.volume:ClearAllPoints()
    row.volume:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 316, -10)
    row.age:ClearAllPoints()
    row.age:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 360, -10)
    row.age:SetWidth(52)
    row.frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. row.props.id)
        GameTooltip:Show()
    end)
    row.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end
function ItemRow:SetProps(props)
    self.props = props
    self:Render()
end
function ItemRow:Render()
    local props = self.props
    local icon = select(10, ns.Compat.ItemInfo(props.id))
    self.icon:SetTexture(icon)
    self.name:SetText(ns.Markets.Name(props.id))
    self.role:SetText(props.role)
    self.price:SetText(props.price)
    self.volume:SetText(props.units)
    self.age:SetText(props.age)
    self.frame:Show()
end
local MarketRow = {}
MarketRow.__index = MarketRow
K.MarketRow = MarketRow
function K.MarketColumns(width, layout)
    if layout == "craft" then
        local cell = math.min(104, math.max(76, math.floor((width - 190) / 4)))
        local item = width - 164 - cell * 3
        return {item = {0, item}, price = {item + 6, cell}, subtotal = {item + cell + 12, cell},
            margin = {item + cell * 2 + 18, cell}, units = {width - 140, 40}}
    end
    return {item = {0, width - 374}, price = {width - 374, 104},
        margin = {width - 264, 118}, units = {width - 140, 40}}
end
function MarketRow:New(parent, selectRow, toggleMaterial, toggleCost, toggleHide)
    local row = setmetatable({}, self)
    row.frame = K.ItemChoice(parent, function() selectRow(row.props.id, row.props) end)
    parent.marketRowCount = (rawget(parent, "marketRowCount") or 0) + 1
    row.stripe = row.frame:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints(row.frame); row.stripe:SetTexture(K.theme.white)
    row.stripe:SetVertexColor(unpack(K.theme.row))
    if parent.marketRowCount % 2 == 0 then row.stripe:Hide() end
    row.frame.selected:SetDrawLayer("BORDER")
    row.match = row.frame:CreateTexture(nil, "BACKGROUND")
    row.match:SetAllPoints(row.frame); row.match:SetTexture(K.theme.white)
    row.match:SetVertexColor(0.25, 0.75, 0.35, 0.16); row.match:Hide()
    row.matchBar = row.frame:CreateTexture(nil, "BORDER")
    row.matchBar:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 0, 0)
    row.matchBar:SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0)
    row.matchBar:SetWidth(3); row.matchBar:SetTexture(K.theme.white)
    row.matchBar:SetVertexColor(0.4, 1, 0.5, 1); row.matchBar:Hide()
    row.frame:SetHeight(30)
    row.frame.text:SetWidth(205)
    row.price = K.Label(row.frame, "", 240, -3, 120)
    row.subtotal = K.Label(row.frame, "", 365, -3, 120)
    row.margin = K.Label(row.frame, "", 365, -3, 120)
    row.marginRate = K.Label(row.frame, "", 0, 0, 118)
    row.marginRate:SetTextColor(unpack(K.theme.secondary))
    row.units = K.Label(row.frame, "", 490, -3, 50)
    row.detail = K.Label(row.frame, "", 28, -17, 440)
    row.detail:ClearAllPoints()
    row.detail:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 28, -14)
    row.detail:SetHeight(10)
    row.frame.text:ClearAllPoints()
    row.frame.text:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 28, -2)
    row.frame.text:SetHeight(12)
    row.refresh = K.Button(row.frame, ns.T("tradeUpdate"), 84, function()
        if row.props.action then row.props.action(row.props.id) else ns.Markets.Scan(row.props.id) end
    end, "quiet")
    row.refresh:SetPoint("RIGHT", row.frame, "RIGHT", -2, 0)
    K.Tooltip(row.refresh, ns.T("cacheRefreshItem"), ns.T("cacheRefreshTip"))
    if toggleHide then
        row.hide = K.Button(row.frame, ns.T("hiddenHide"), 66, function() toggleHide(row.props.id, row.props) end, "quiet")
        row.hide:SetPoint("RIGHT", row.refresh, "LEFT", -4, 0)
    end
    if toggleMaterial then
        row.expand = K.Button(row.frame, "+", 16, function() toggleMaterial(row.props.id, row.props) end, "quiet")
        row.expand.text:ClearAllPoints(); row.expand.text:SetPoint("CENTER", row.expand, "CENTER", 0, 0)
        K.Tooltip(row.expand, ns.T("craftMaterialSource"), ns.T("craftTreeTip"))
    end
    if toggleCost then
        row.include = K.Check(row.frame, function(checked) toggleCost(row.props.id, checked) end)
        row.include:SetPoint("LEFT", row.frame, "LEFT", 0, 0)
        K.Tooltip(row.include, ns.T("craftIncludeCost"), ns.T("craftIncludeTip"))
    end
    return row
end
function MarketRow:SetProps(props)
    self.props = props
    self:Render()
end
function MarketRow:Render()
    local p = self.props
    self.frame.extraTip = p.extraTip
    K.SetItemChoice(self.frame, p.id, p.active, p.quality)
    local columns = p.width and K.MarketColumns(p.width - (p.reserve or 0), p.layout)
    if self.hide then
        if p.hideable then
            self.hide:SetText(p.hideLabel or ns.T("hiddenHide"))
            K.Tooltip(self.hide, p.hideLabel or ns.T("hiddenHide"), ns.T(p.hidden and "hiddenRestoreTip" or "hiddenHideTip"))
            self.hide:Show()
        else self.hide:Hide() end
    end
    if p.match then self.match:Show(); self.matchBar:Show() else self.match:Hide(); self.matchBar:Hide() end
    if p.width then
        self.frame:SetWidth(p.width)
        self.frame.text:SetWidth(columns.item[2] - 34)
        self.detail:SetWidth(columns.item[2] - 34)
        for _, key in ipairs({"price", "margin", "units"}) do
            self[key]:ClearAllPoints()
            self[key]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", columns[key][1], -8)
            self[key]:SetWidth(columns[key][2])
            self[key]:SetJustifyH("RIGHT")
        end
        if columns.subtotal then
            self.subtotal:ClearAllPoints()
            self.subtotal:SetPoint("TOPLEFT", self.frame, "TOPLEFT", columns.subtotal[1], -8)
            self.subtotal:SetWidth(columns.subtotal[2]); self.subtotal:SetJustifyH("RIGHT")
            self.subtotal:SetText(K.Money(p.subtotal)); self.subtotal:Show()
        else self.subtotal:Hide() end
    end
    if self.expand then
        local offset = p.depth ~= nil and (34 + p.depth * 12) or 0
        self.frame.icon:ClearAllPoints(); self.frame.icon:SetPoint("LEFT", self.frame, "LEFT", offset + 2, 0)
        self.frame.text:ClearAllPoints(); self.frame.text:SetPoint("TOPLEFT", self.frame, "TOPLEFT", offset + 28, -2)
        self.detail:ClearAllPoints(); self.detail:SetPoint("TOPLEFT", self.frame, "TOPLEFT", offset + 28, -14)
        self.frame.text:SetWidth(math.max(24, columns.item[2] - offset - 34))
        self.detail:SetWidth(math.max(24, columns.item[2] - offset - 34))
        self.expand:ClearAllPoints(); self.expand:SetPoint("LEFT", self.frame, "LEFT", math.max(0, offset - 16), 0)
        self.expand:SetText(p.crafted and "-" or "+")
        if p.excluded then self.expand:Disable() else self.expand:Enable() end
        if p.expandable then self.expand:Show() else self.expand:Hide() end
    end
    if self.include then
        self.include:SetChecked(not p.excluded)
        if p.depth ~= nil and p.include ~= false then self.include:Show() else self.include:Hide() end
    end
    self.price:SetText(K.Money(p.quote and p.quote.price))
    self.margin:SetText(K.Money(p.margin))
    if p.percent then
        self.margin:ClearAllPoints()
        self.margin:SetPoint("TOPRIGHT", self.marginRate, "TOPRIGHT", 0, 13)
        self.marginRate:ClearAllPoints()
        self.marginRate:SetPoint("TOPLEFT", self.frame, "TOPLEFT", columns.margin[1], -15)
        self.marginRate:SetWidth(columns.margin[2])
        self.marginRate:SetJustifyH("RIGHT"); self.marginRate:SetText(ns.T("deMarginRate", p.percent)); self.marginRate:Show()
    else self.marginRate:Hide() end
    self.margin:SetTextColor(unpack(K.theme[p.tone or (p.margin and (p.margin > 0 and "positive" or "negative") or "text")]))
    self.units:SetText(p.quote and tostring(p.quote.units) or ns.T("tradeNoPrice"))
    self.detail:SetText((p.detail or "") .. (p.quote and (p.quote.miss or 0) > 0 and ns.T("cacheIncomplete") or ""))
    self.detail:SetTextColor(unpack(K.theme.secondary))
    if p.noRefresh or (p.quote and p.quote.vendor) then self.refresh:Hide() else self.refresh:Show() end
    self.refresh:SetText(p.actionLabel or ns.T("tradeUpdate"))
    if p.actionDisabled then self.refresh:Disable() else self.refresh:Enable() end
    if p.actionTip then K.Tooltip(self.refresh, p.actionLabel, p.actionTip) end
end
local LevelingRow = {}
LevelingRow.__index = LevelingRow
K.LevelingRow = LevelingRow
function LevelingRow:New(parent, action, expand)
    local view = setmetatable({}, self)
    view.frame = K.Navigation(parent, "", function() action(view.props, false) end)
    view.frame:SetHeight(38)
    view.icon = view.frame:CreateTexture(nil, "ARTWORK")
    view.icon:SetWidth(24); view.icon:SetHeight(24)
    view.name = view.frame.text
    view.detail = K.Label(view.frame, "", 30, -21, 200)
    view.detail:SetHeight(12); view.detail:SetTextColor(unpack(K.theme.secondary))
    view.quantity = K.Label(view.frame, "", 0, -5, 120)
    view.quantity:SetJustifyH("RIGHT")
    view.cost = K.Label(view.frame, "", 0, -5, 124)
    view.cost:SetJustifyH("RIGHT")
    view.button = K.Button(view.frame, "", 90, function() action(view.props, true) end, "quiet")
    view.button:SetPoint("RIGHT", view.frame, "RIGHT", -4, 0)
    view.expand = K.Button(view.frame, "+", 22, function() expand(view.props) end, "quiet")
    view.frame:SetScript("OnEnter", function(frame)
        local p = view.props
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        if p.id then GameTooltip:SetHyperlink("item:" .. p.id)
        elseif p.spell then GameTooltip:SetHyperlink("spell:" .. p.spell)
        else GameTooltip:AddLine(p.label, unpack(K.theme.text)) end
        if p.tip then GameTooltip:AddLine(p.tip, K.theme.gold[1], K.theme.gold[2], K.theme.gold[3], true) end
        GameTooltip:Show()
    end)
    view.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return view
end
function LevelingRow:SetProps(props)
    self.props = props; self:Render()
end
function LevelingRow:Render()
    local p, width = self.props, self.props.width
    self.frame:SetWidth(width)
    local offset = 28 + (p.depth or 0) * 14
    self.icon:ClearAllPoints(); self.icon:SetPoint("LEFT", self.frame, "LEFT", offset, 0)
    self.name:ClearAllPoints(); self.name:SetPoint("TOPLEFT", self.frame, "TOPLEFT", offset + 28, -4)
    self.detail:ClearAllPoints(); self.detail:SetPoint("TOPLEFT", self.frame, "TOPLEFT", offset + 28, -21)
    self.name:SetWidth(math.max(40, width - offset - 388))
    self.detail:SetWidth(math.max(40, width - offset - 388))
    local name, icon
    if p.id then name, icon = ns.Markets.Name(p.id), select(10, ns.Compat.ItemInfo(p.id))
    elseif p.spell then
        name, icon = ns.Compat.SpellIcon(p.spell)
        name = name or ns.T("levelSpell", p.spell)
    else name = p.label end
    self.name:SetText(name); self.icon:SetTexture(icon)
    self.name:SetTextColor(unpack(K.theme[p.active and "gold" or "text"]))
    if p.active then self.frame.selected:Show() else self.frame.selected:Hide() end
    self.detail:SetText(p.detail or "")
    self.quantity:ClearAllPoints(); self.quantity:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -230, -6)
    self.quantity:SetText(p.quantity or "")
    self.cost:ClearAllPoints(); self.cost:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -100, -6)
    self.cost:SetText(p.costText or K.Money(p.cost))
    self.button:SetText(p.action or "")
    if p.action then self.button:Show() else self.button:Hide() end
    self.expand:ClearAllPoints(); self.expand:SetPoint("LEFT", self.frame, "LEFT", offset - 26, 0)
    self.expand:SetText(p.opened and "-" or "+")
    if p.expandable then self.expand:Show() else self.expand:Hide() end
    self.frame:Show()
end
local OutcomeList = {}
OutcomeList.__index = OutcomeList
K.OutcomeList = OutcomeList
function OutcomeList:New(parent)
    local view = setmetatable({cards = {}}, self)
    view.frame = ns.NewFrame("Frame", nil, parent)
    view.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -172)
    view.frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 40)
    view.scroll = K.Scroller:New(view.frame, function() view:Render() end, 46)
    view.scroll.frame:SetAllPoints(view.frame)
    for i = 1, 4 do
        local card = {}
        card.frame = K.ItemChoice(view.frame, function() end)
        card.frame:SetHeight(42)
        card.back = card.frame:CreateTexture(nil, "BACKGROUND")
        card.back:SetAllPoints(card.frame); card.back:SetTexture(K.theme.white)
        card.back:SetVertexColor(unpack(K.theme.row))
        card.icon, card.name = card.frame.icon, card.frame.text
        card.icon:SetWidth(34); card.icon:SetHeight(34)
        card.icon:ClearAllPoints(); card.icon:SetPoint("TOPLEFT", card.frame, "TOPLEFT", 4, -4)
        card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        card.name:ClearAllPoints(); card.name:SetPoint("TOPLEFT", card.frame, "TOPLEFT", 44, -3)
        card.name:SetWidth(130); card.name:SetHeight(12)
        card.amount = K.Label(card.frame, "", 0, 0, 100, "heading")
        card.amount:ClearAllPoints(); card.amount:SetPoint("TOPRIGHT", card.frame, "TOPRIGHT", -6, -2)
        card.amount:SetJustifyH("RIGHT")
        card.track = card.frame:CreateTexture(nil, "BORDER")
        card.track:SetTexture(K.theme.white); card.track:SetVertexColor(unpack(K.theme.chart.axis))
        card.track:SetHeight(7); card.track:SetPoint("TOPLEFT", card.frame, "TOPLEFT", 44, -18)
        card.fill = card.frame:CreateTexture(nil, "ARTWORK")
        card.fill:SetTexture(K.theme.white); card.fill:SetHeight(7)
        card.fill:SetPoint("TOPLEFT", card.frame, "TOPLEFT", 44, -18)
        card.chance = K.Label(card.frame, "", 0, -16, 56)
        card.chance:ClearAllPoints(); card.chance:SetPoint("TOPRIGHT", card.frame, "TOPRIGHT", -4, -16)
        card.line = K.Label(card.frame, "", 44, -29, 178); card.line:SetHeight(12)
        card.frame:Hide(); view.cards[i] = card
        view.scroll:Wheel(card.frame)
    end
    return view
end
function OutcomeList:SetProps(props)
    if not self.props or self.props.source ~= props.source or self.props.target ~= props.target then self.scroll.offset = 0 end
    self.props = props; self:Render()
end
function OutcomeList:Render()
    if not self.props then return end
    local width = (self.frame:GetWidth() or 244) - 18
    local barWidth = math.max(30, width - 108)
    local visible = math.max(0, math.min(#self.cards, math.floor((self.frame:GetHeight() or 184) / 46)))
    local outputs = self.props.outputs or {}
    local offset = self.scroll:SetRange(#outputs, visible)
    for i, card in ipairs(self.cards) do
        local output = i <= visible and outputs[offset + i]
        if output then
            card.frame:ClearAllPoints(); card.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -(i - 1) * 46)
            card.frame:SetWidth(width)
            K.SetItemChoice(card.frame, output.id, output.id == self.props.target)
            local range = output.minCount == output.maxCount and tostring(output.minCount)
                or output.minCount .. "-" .. output.maxCount
            card.amount:SetText(ns.T("deCardCount", range))
            card.name:SetWidth(math.max(50, width - 140))
            card.track:SetWidth(barWidth); card.fill:SetWidth(math.max(2, math.floor(barWidth * output.chance + 0.5)))
            local color = output.chance >= 0.5 and K.theme.chart.added
                or (output.chance >= 0.05 and K.theme.chart.supply or K.theme.chart.late)
            card.fill:SetVertexColor(unpack(color))
            card.chance:SetText(string.format("%g%%", output.chance * 100))
            card.line:SetWidth(math.max(40, width - 48))
            card.line:SetText(ns.T("deCardLine", K.Money(output.price), string.format("%.3g", output.quantity),
                K.Money(output.price and output.quantity * output.price)))
            card.frame.extraTip = output.id == self.props.target and ns.T("deTargetOutcome") or ns.T("deOtherOutcome")
        else card.frame:Hide() end
    end
end
local Chart = {}
Chart.__index = Chart
K.PriceChart = Chart
function Chart:New(parent)
    local chart = setmetatable({dots = {}}, self)
    chart.frame = ns.NewFrame("Frame", nil, parent)
    chart.frame:SetWidth(240)
    chart.frame:SetHeight(132)
    chart.top = K.Label(chart.frame, "", 0, 0, 240)
    chart.bottom = K.Label(chart.frame, "", 0, -98, 240)
    chart.start = K.Label(chart.frame, "", 0, -118, 118)
    chart.finish = K.Label(chart.frame, "", 122, -118, 118)
    chart.finish:SetJustifyH("RIGHT")
    chart.empty = K.Label(chart.frame, "", 10, -28, 220)
    chart.empty:SetHeight(70)
    chart.empty:SetJustifyH("CENTER")
    return chart
end
function Chart:SetProps(props)
    self.props = props
    self:Render()
end
function Chart:Render()
    local points = self.props.points
    for _, dot in ipairs(self.dots) do dot:Hide() end
    local n = #points
    self.empty:SetText(n < 2 and ns.T("familyNeedHistory") or "")
    self.top:SetText(""); self.bottom:SetText(""); self.start:SetText(""); self.finish:SetText("")
    if n < 2 then return end
    local low, high = points[1].price, points[1].price
    for _, p in ipairs(points) do low = math.min(low, p.price); high = math.max(high, p.quartile or p.price) end
    self.top:SetText(self.props.volume and tostring(high) or K.Money(high))
    self.bottom:SetText(self.props.volume and tostring(low) or K.Money(low))
    self.start:SetText(date("%d.%m %H:%M", points[1].at))
    self.finish:SetText(date("%d.%m %H:%M", points[n].at))
    local count = math.min(n, 60)
    for i = 1, count do
        local index = count == 1 and 1 or math.floor(1 + (i - 1) * (n - 1) / (count - 1))
        local p = points[index]
        local dot = self.dots[i]
        if not dot then
            dot = ns.NewFrame("Button", nil, self.frame)
            dot:SetWidth(6); dot:SetHeight(6)
            dot.min = dot:CreateTexture(nil, "ARTWORK")
            dot.min:SetAllPoints(dot); dot.min:SetTexture(K.theme.white)
            dot.min:SetVertexColor(unpack(K.theme.gold))
            dot.q = dot:CreateTexture(nil, "OVERLAY")
            dot.q:SetWidth(4); dot.q:SetHeight(4); dot.q:SetTexture(K.theme.white)
            dot.q:SetVertexColor(unpack(K.theme.positive))
            self.dots[i] = dot
        end
        local x = 6 + 228 * (p.at - points[1].at) / math.max(1, points[n].at - points[1].at)
        local y = -88 + 64 * (p.price - low) / math.max(1, high - low)
        dot:ClearAllPoints(); dot:SetPoint("CENTER", self.frame, "TOPLEFT", x, y)
        dot.q:ClearAllPoints()
        dot.q:SetPoint("CENTER", dot, "CENTER", 0, 64 * ((p.quartile or p.price) - p.price) / math.max(1, high - low))
        K.Tooltip(dot, date("%d.%m %H:%M", p.at), self.props.volume
            and ns.T("historyVolumePoint", p.price, p.quartile) or ns.T("familyPoint", K.Money(p.price), K.Money(p.quartile)))
        dot:Show()
    end
end
local Tile = {}
Tile.__index = Tile
K.StatTile = Tile
function Tile:New(parent)
    local tile = setmetatable({}, self)
    local f = ns.NewFrame("Frame", nil, parent)
    tile.frame = f
    f:SetHeight(54); f:EnableMouse(true)
    f:SetBackdrop(K.theme.buttonSkin)
    f:SetBackdropColor(unpack(K.theme.chart.tile))
    f:SetBackdropBorderColor(unpack(K.theme.quiet.edge))
    tile.accent = f:CreateTexture(nil, "ARTWORK")
    tile.accent:SetTexture(K.theme.white); tile.accent:SetWidth(2)
    tile.accent:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -6)
    tile.accent:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 4, 6)
    tile.title = K.Label(f, "", 11, -7, 120); tile.title:SetHeight(12)
    tile.title:SetTextColor(unpack(K.theme.secondary))
    tile.value = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tile.value:SetPoint("TOPLEFT", f, "TOPLEFT", 11, -21); tile.value:SetHeight(16)
    tile.value:SetJustifyH("LEFT")
    tile.note = K.Label(f, "", 11, -39, 120); tile.note:SetHeight(12)
    return tile
end
function Tile:SetProps(props)
    self.props = props; self:Render()
end
function Tile:Render()
    local p = self.props
    local inner = math.max(40, (p.width or 140) - 16)
    self.frame:SetWidth(p.width or 140)
    self.title:SetWidth(inner); self.value:SetWidth(inner); self.note:SetWidth(inner)
    self.title:SetText(p.title); self.value:SetText(p.value); self.note:SetText(p.note or "")
    self.note:SetTextColor(unpack(K.theme[p.tone or "secondary"]))
    self.accent:SetVertexColor(unpack(p.accent or K.theme.gold))
    K.Tooltip(self.frame, p.title, p.tip or "")
end
local TimeChart = {}
TimeChart.__index = TimeChart
K.TimeChart = TimeChart
local timeSteps = {3600, 7200, 10800, 21600, 43200, 86400, 172800, 259200, 432000, 604800, 1209600}
local function niceStep(value)
    if value <= 0 then return 1 end
    local power = 10 ^ math.floor(math.log(value) / math.log(10) + 1e-9)
    for _, m in ipairs({1, 2, 5, 10}) do
        if value <= m * power * (1 + 1e-9) then return m * power end
    end
    return 10 * power
end
local function zone()
    local now = time()
    local here, utc = date("*t", now), date("!*t", now)
    if type(here) ~= "table" or type(utc) ~= "table" then return 0 end
    local shift = (here.hour - utc.hour) * 3600 + (here.min - utc.min) * 60
    if here.yday ~= utc.yday then
        shift = shift + ((here.year > utc.year or (here.year == utc.year and here.yday > utc.yday)) and 86400 or -86400)
    end
    return shift
end
function TimeChart:New(parent)
    local chart = setmetatable({texts = {}, textUsed = 0, dots = {},
        pools = {BACKGROUND = {used = 0}, BORDER = {used = 0}, ARTWORK = {used = 0}}}, self)
    local f = ns.NewFrame("Frame", nil, parent)
    chart.frame = f
    f:EnableMouse(true)
    local overlay = ns.NewFrame("Frame", nil, f)
    chart.overlay = overlay
    overlay:SetAllPoints(f); overlay:SetFrameLevel(f:GetFrameLevel() + 5)
    chart.cursor = overlay:CreateTexture(nil, "ARTWORK")
    chart.cursor:SetTexture(K.theme.white); chart.cursor:SetVertexColor(unpack(K.theme.chart.cursor))
    chart.cursor:SetWidth(1)
    chart.stamp = overlay:CreateTexture(nil, "ARTWORK")
    chart.stamp:SetTexture(K.theme.white); chart.stamp:SetVertexColor(unpack(K.theme.chart.shade))
    chart.stamp:SetWidth(84); chart.stamp:SetHeight(14)
    chart.stampText = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    chart.stampText:SetPoint("CENTER", chart.stamp, "CENTER", 0, 0)
    chart.anchor = ns.NewFrame("Frame", nil, overlay)
    chart.anchor:SetWidth(1); chart.anchor:SetHeight(1)
    chart.empty = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    chart.empty:SetPoint("CENTER", f, "CENTER", 0, 0); chart.empty:SetWidth(320)
    chart.empty:SetTextColor(unpack(K.theme.secondary))
    f:SetScript("OnEnter", function() f:SetScript("OnUpdate", function() chart:Hover() end) end)
    f:SetScript("OnLeave", function() f:SetScript("OnUpdate", nil); chart:Unhover() end)
    f:SetScript("OnSizeChanged", function() if chart.props then chart:Render() end end)
    chart:Unhover()
    return chart
end
function TimeChart:SetProps(props)
    self.props = props; self:Render()
end
function TimeChart:Rect(layer, color, x, y, w, h, alpha)
    local pool = self.pools[layer]
    pool.used = pool.used + 1
    local t = pool[pool.used]
    if not t then
        t = self.frame:CreateTexture(nil, layer); t:SetTexture(K.theme.white)
        pool[pool.used] = t
    end
    t:ClearAllPoints(); t:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, -y)
    t:SetWidth(math.max(1, w)); t:SetHeight(math.max(1, h))
    t:SetVertexColor(color[1], color[2], color[3], (color[4] or 1) * (alpha or 1))
    t:Show()
    return t
end
function TimeChart:Text(text, x, y, width, justify, color)
    self.textUsed = self.textUsed + 1
    local fs = self.texts[self.textUsed]
    if not fs then
        fs = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        self.texts[self.textUsed] = fs
    end
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, -y)
    fs:SetWidth(width); fs:SetHeight(12); fs:SetJustifyH(justify or "LEFT")
    fs:SetTextColor(unpack(color or K.theme.secondary)); fs:SetText(text); fs:Show()
    return fs
end
function TimeChart:Render()
    local p = self.props
    for _, pool in pairs(self.pools) do
        for i = 1, pool.used do pool[i]:Hide() end
        pool.used = 0
    end
    for i = 1, self.textUsed do self.texts[i]:Hide() end
    self.textUsed, self.layout = 0, nil
    self:Unhover()
    local width, height = self.frame:GetWidth() or 0, self.frame:GetHeight() or 0
    self.empty:SetText(p.empty or "")
    if p.empty or width < 160 or height < 90 then return end
    local gutter, plot = 72, width - 80
    local count = math.max(8, math.min(120, math.floor(plot / 7)))
    local layout = {gutter = gutter, plot = plot, count = count, slot = plot / count,
        buckets = p.buckets(count), boxes = {}, span = math.max(1, p.to - p.from)}
    self.layout = layout
    local total, gap, top = 0, 8, 0
    for _, track in ipairs(p.tracks) do total = total + track.weight end
    local available = height - 16 - gap * (#p.tracks - 1)
    for _, track in ipairs(p.tracks) do
        local h = math.floor(available * track.weight / total)
        local box = {track = track, top = top + 16, height = h - 16}
        layout.boxes[#layout.boxes + 1] = box
        self:Header(box)
        if track.kind == "steps" then self:Steps(box) elseif track.kind == "bars" then self:Bars(box) else self:Flow(box) end
        top = top + h + gap
    end
    layout.bottom = top - gap
    self:Ruler()
end
function TimeChart:Header(box)
    local track, x = box.track, self.layout.gutter
    local title = self:Text(track.title, x, box.top - 15, 200, "LEFT", K.theme.text)
    x = x + math.min(200, title:GetStringWidth() or 120) + 14
    local legend = {}
    for _, series in ipairs(track.series) do legend[#legend + 1] = series end
    for _, series in ipairs(track.down or {}) do legend[#legend + 1] = series end
    if track.median then legend[#legend + 1] = {color = K.theme.chart.median, legend = track.medianLegend} end
    for _, series in ipairs(legend) do
        if series.legend then
            self:Rect("ARTWORK", series.color, x, box.top - 12, 8, 8)
            local label = self:Text(series.legend, x + 11, box.top - 15, 140)
            x = x + 25 + math.min(140, label:GetStringWidth() or 80)
        end
    end
end
function TimeChart:Grid(box, low, high, step)
    local layout = self.layout
    local value = low
    while value <= high + step * 0.001 do
        local y = box.scale(value)
        self:Rect("BACKGROUND", K.theme.chart.grid, layout.gutter, y, layout.plot, 1)
        self:Text(box.track.format(value), 0, y - 6, layout.gutter - 8, "RIGHT")
        value = value + step
    end
    self:Rect("BACKGROUND", K.theme.chart.axis, layout.gutter - 1, box.top, 1, box.height)
end
function TimeChart:Center(i)
    return self.layout.gutter + (i - 0.5) * self.layout.slot
end
function TimeChart:Steps(box)
    local layout, track = self.layout, box.track
    local low, high
    for i = 1, layout.count do
        local b = layout.buckets[i]
        for _, series in ipairs(b and track.series or {}) do
            local v = b[series.field]
            if v then low, high = math.min(low or v, v), math.max(high or v, v) end
        end
    end
    if not low then return end
    if high - low < math.max(1, high * 0.02) then low, high = low * 0.95, high * 1.05 + 1 end
    local step = niceStep((high - low) / 3)
    low, high = math.floor(low / step) * step, math.ceil(high / step) * step
    local base = box.top + box.height
    box.scale = function(v) return base - (v - low) / math.max(1, high - low) * box.height end
    self:Grid(box, low, high, step)
    if track.median then
        self:Rect("BORDER", K.theme.chart.median, layout.gutter, box.scale(track.median), layout.plot, 1)
    end
    local limit = math.max(1, math.ceil(43200 / (layout.span / layout.count)))
    for _, series in ipairs(track.series) do
        local thick, last, lastValue = series.thick or 2, nil, nil
        local function hold(index, x1, value, dim)
            local x0, y = self:Center(index), box.scale(value)
            if series.area then self:Rect("BORDER", series.color, x0, y, x1 - x0, base - y, dim and 0.05 or 0.13) end
            self:Rect("ARTWORK", series.color, x0, y - thick / 2, x1 - x0 + thick / 2, thick, dim and 0.35 or 1)
        end
        for i = 1, layout.count do
            local b = layout.buckets[i]
            local value = b and b[series.field]
            if value then
                if last then
                    local x, y0, y1 = self:Center(i), box.scale(lastValue), box.scale(value)
                    local dim = i - last > limit
                    hold(last, x, lastValue, dim)
                    self:Rect("ARTWORK", series.color, x - thick / 2, math.min(y0, y1) - thick / 2, thick,
                        math.abs(y1 - y0) + thick, dim and 0.35 or 1)
                end
                if series.dots and layout.slot >= 4 then
                    self:Rect("ARTWORK", series.color, self:Center(i) - 2, box.scale(value) - 2, 4, 4)
                end
                last, lastValue = i, value
            end
        end
        if last then hold(last, layout.gutter + layout.plot, lastValue, true) end
    end
end
function TimeChart:Bars(box)
    local layout, series = self.layout, box.track.series[1]
    local high = 0
    for i = 1, layout.count do
        local b = layout.buckets[i]
        if b and b[series.field] then high = math.max(high, b[series.field]) end
    end
    local step = niceStep(math.max(1, high) / 2)
    high = math.max(step, math.ceil(high / step) * step)
    local base = box.top + box.height
    box.scale = function(v) return base - v / high * box.height end
    self:Grid(box, 0, high, step)
    local width = math.max(1, math.min(12, layout.slot - 1))
    for i = 1, layout.count do
        local b = layout.buckets[i]
        local v = b and b[series.field]
        if v then
            local h = math.max(1, v / high * box.height)
            self:Rect("ARTWORK", series.color, self:Center(i) - width / 2, base - h, width, h, v > 0 and 0.85 or 0.35)
        end
    end
end
function TimeChart:Flow(box)
    local layout, track = self.layout, box.track
    local high = 0
    for i = 1, layout.count do
        local b = layout.buckets[i]
        if b and b.compared > 0 then
            local up, down = 0, 0
            for _, series in ipairs(track.series) do up = up + b[series.field] end
            for _, series in ipairs(track.down) do down = down + b[series.field] end
            high = math.max(high, up, down)
        end
    end
    local step = niceStep(math.max(1, high))
    high = math.max(step, math.ceil(high / step) * step)
    local middle, half = box.top + box.height / 2, box.height / 2
    box.scale = function(v) return middle - v / high * half end
    self:Grid(box, -high, high, high)
    self:Rect("BORDER", K.theme.chart.axis, layout.gutter, middle, layout.plot, 1)
    local width = math.max(1, math.min(12, layout.slot - 1))
    for i = 1, layout.count do
        local b = layout.buckets[i]
        if b and b.compared > 0 then
            local x, y, moved = self:Center(i) - width / 2, middle, false
            for _, series in ipairs(track.series) do
                local h = b[series.field] / high * half
                if h > 0 then y, moved = y - h, true; self:Rect("ARTWORK", series.color, x, y, width, h, 0.9) end
            end
            y = middle + 1
            for _, series in ipairs(track.down) do
                local h = b[series.field] / high * half
                if h > 0 then moved = true; self:Rect("ARTWORK", series.color, x, y, width, h, 0.9); y = y + h end
            end
            if not moved then self:Rect("ARTWORK", K.theme.chart.late, x, middle - 1, width, 3, 0.5) end
        end
    end
end
function TimeChart:Ruler()
    local layout, p = self.layout, self.props
    local slots = math.max(2, math.floor(layout.plot / 72))
    local step = timeSteps[#timeSteps]
    for _, value in ipairs(timeSteps) do
        if layout.span / value <= slots then step = value; break end
    end
    local shift = zone()
    local t = math.ceil((p.from + shift) / step) * step - shift
    while t <= p.to do
        local x = layout.gutter + (t - p.from) / layout.span * layout.plot
        self:Rect("BACKGROUND", K.theme.chart.grid, x, 0, 1, layout.bottom)
        local midnight = (t + shift) % 86400 == 0
        self:Text(date((step < 86400 and not midnight) and "%H:%M" or "%d.%m", t), x - 30, layout.bottom + 4, 60, "CENTER")
        t = t + step
    end
end
function TimeChart:Hover()
    local layout = self.layout
    if not layout then return end
    local cursor = GetCursorPosition()
    local x = cursor / (self.frame:GetEffectiveScale() or 1) - (self.frame:GetLeft() or 0)
    local index = math.floor((x - layout.gutter) / layout.slot) + 1
    if index < 1 or index > layout.count then self:Unhover(); return end
    local found
    for d = 0, layout.count do
        if layout.buckets[index - d] then found = index - d; break end
        if layout.buckets[index + d] then found = index + d; break end
    end
    if not found then self:Unhover(); return end
    if found == self.hovered then return end
    self.hovered = found
    local bucket, cx = layout.buckets[found], self:Center(found)
    self.cursor:ClearAllPoints()
    self.cursor:SetPoint("TOPLEFT", self.frame, "TOPLEFT", cx, 0)
    self.cursor:SetHeight(math.max(1, layout.bottom)); self.cursor:Show()
    self.stamp:ClearAllPoints()
    self.stamp:SetPoint("TOP", self.frame, "TOPLEFT", math.max(42, math.min(layout.gutter + layout.plot - 42, cx)),
        -layout.bottom - 2)
    self.stampText:SetText(date("%d.%m %H:%M", bucket.at)); self.stamp:Show(); self.stampText:Show()
    local used = 0
    for _, box in ipairs(layout.boxes) do
        for _, series in ipairs(box.track.kind == "steps" and box.scale and box.track.series or {}) do
            local value = bucket[series.field]
            if value then
                used = used + 1
                local dot = self.dots[used]
                if not dot then
                    dot = self.overlay:CreateTexture(nil, "OVERLAY"); dot:SetTexture(K.theme.white)
                    dot:SetWidth(7); dot:SetHeight(7); self.dots[used] = dot
                end
                dot:SetVertexColor(unpack(series.color))
                dot:ClearAllPoints(); dot:SetPoint("CENTER", self.frame, "TOPLEFT", cx, -box.scale(value)); dot:Show()
            end
        end
    end
    for i = used + 1, #self.dots do self.dots[i]:Hide() end
    local first = layout.boxes[1]
    self.anchor:ClearAllPoints(); self.anchor:SetPoint("TOPLEFT", self.frame, "TOPLEFT", cx, -(first and first.top or 0))
    GameTooltip:SetOwner(self.anchor, "ANCHOR_NONE")
    if cx > layout.gutter + layout.plot * 0.6 then GameTooltip:SetPoint("TOPRIGHT", self.anchor, "TOPLEFT", -14, 0)
    else GameTooltip:SetPoint("TOPLEFT", self.anchor, "TOPRIGHT", 14, 0) end
    local title, lines = self.props.tip(bucket)
    GameTooltip:AddLine(title, unpack(K.theme.gold))
    local secondary = K.theme.secondary
    for _, line in ipairs(lines) do
        local color = line[3] or K.theme.text
        if line[2] then
            GameTooltip:AddDoubleLine(line[1], line[2], secondary[1], secondary[2], secondary[3], color[1], color[2], color[3])
        else GameTooltip:AddLine(line[1], color[1], color[2], color[3], true) end
    end
    GameTooltip:Show()
end
function TimeChart:Unhover()
    self.hovered = nil
    self.cursor:Hide(); self.stamp:Hide(); self.stampText:Hide()
    for _, dot in ipairs(self.dots) do dot:Hide() end
    if GameTooltip:IsOwned(self.anchor) then GameTooltip:Hide() end
end
