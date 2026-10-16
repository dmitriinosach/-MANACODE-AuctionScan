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
function K.Tooltip(parent, title, body)
    parent.tipTitle, parent.tip = title, body
    if rawget(parent, "tradeTipHooked") then return end
    parent.tradeTipHooked = true
    parent:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.tipTitle, unpack(K.theme.text))
        GameTooltip:AddLine(self.tip, K.theme.gold[1], K.theme.gold[2], K.theme.gold[3], true)
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
local Inspector = {}
Inspector.__index = Inspector
K.Inspector = Inspector
function Inspector:New(parent, open)
    local view = setmetatable({}, self)
    local panel = ns.NewFrame("Frame", nil, parent)
    view.frame = panel
    panel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -2)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 2)
    panel:SetWidth(264); panel:EnableMouse(true); K.Panel(panel)
    view.item = K.ItemChoice(panel, open)
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
        view.item:SetWidth(150); view.item.text:SetWidth(118)
        K.Tooltip(view.actions.frame, ns.T("collectionActions"), ns.T("collectionActionsTip"))
    end
    K.Rule(panel, -39)
    return view
end
function Inspector:SetProps(props)
    self.props = props; self:Render()
end
function Inspector:Render()
    K.SetItemChoice(self.item, self.props.id, self.props.active)
    if self.actions then
        local C, id = ns.Collections, self.props.id
        self.actions.buttons[1].text:SetText(ns.T(C.Favorite(id) and "collectionUnfavorite" or "collectionFavorite"))
        self.actions.buttons[2].text:SetText(ns.T(C.Tracked(id) and "collectionUntrack" or "collectionTrack"))
        if C.CanFavorite(id) then self.actions.buttons[1]:Enable() else self.actions.buttons[1]:Disable() end
    end
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
    view.edit = K.Edit(view.frame, 70)
    view.edit:SetPoint("RIGHT", view.frame, "RIGHT", -88, 0)
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
    self.item:SetWidth(p.width - 166); self.item.text:SetWidth(math.max(30, p.width - 196))
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
function K.ResizeGrip(parent, start, finish)
    local grip = ns.NewFrame("Button", nil, parent)
    grip:SetWidth(18); grip:SetHeight(18)
    grip:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -2, -1)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetFrameLevel(parent:GetFrameLevel() + 30)
    grip:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" then start() end end)
    grip:SetScript("OnMouseUp", finish)
    grip:SetScript("OnHide", finish)
    K.Tooltip(grip, ns.T("windowResize"), ns.T("windowResizeTip"))
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
function MarketRow:New(parent, selectRow, toggleMaterial, toggleCost)
    local row = setmetatable({}, self)
    row.frame = K.ItemChoice(parent, function() selectRow(row.props.id) end)
    parent.marketRowCount = (rawget(parent, "marketRowCount") or 0) + 1
    row.stripe = row.frame:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints(row.frame); row.stripe:SetTexture(K.theme.white)
    row.stripe:SetVertexColor(unpack(K.theme.row))
    if parent.marketRowCount % 2 == 0 then row.stripe:Hide() end
    row.frame.selected:SetDrawLayer("BORDER")
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
        ns.Markets.Scan(row.props.id)
    end, "quiet")
    row.refresh:SetPoint("RIGHT", row.frame, "RIGHT", -2, 0)
    K.Tooltip(row.refresh, ns.T("cacheRefreshItem"), ns.T("cacheRefreshTip"))
    if toggleMaterial then
        row.expand = K.Button(row.frame, "+", 16, function() toggleMaterial(row.props.id) end, "quiet")
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
    if p.width then
        local columns = K.MarketColumns(p.width, p.layout)
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
        self.frame.text:SetWidth(math.max(24, K.MarketColumns(p.width, p.layout).item[2] - offset - 34))
        self.detail:SetWidth(math.max(24, K.MarketColumns(p.width, p.layout).item[2] - offset - 34))
        self.expand:ClearAllPoints(); self.expand:SetPoint("LEFT", self.frame, "LEFT", math.max(0, offset - 16), 0)
        self.expand:SetText(p.crafted and "-" or "+")
        if p.excluded then self.expand:Disable() else self.expand:Enable() end
        if p.expandable then self.expand:Show() else self.expand:Hide() end
    end
    if self.include then
        self.include:SetChecked(not p.excluded)
        if p.depth ~= nil then self.include:Show() else self.include:Hide() end
    end
    self.price:SetText(K.Money(p.quote and p.quote.price))
    self.margin:SetText(K.Money(p.margin))
    if p.percent then
        self.margin:ClearAllPoints()
        self.margin:SetPoint("TOPRIGHT", self.marginRate, "TOPRIGHT", 0, 13)
        self.marginRate:ClearAllPoints()
        self.marginRate:SetPoint("TOPLEFT", self.frame, "TOPLEFT", K.MarketColumns(p.width, p.layout).margin[1], -15)
        self.marginRate:SetWidth(K.MarketColumns(p.width, p.layout).margin[2])
        self.marginRate:SetJustifyH("RIGHT"); self.marginRate:SetText(ns.T("deMarginRate", p.percent)); self.marginRate:Show()
    else self.marginRate:Hide() end
    self.margin:SetTextColor(unpack(K.theme[p.tone or (p.margin and (p.margin > 0 and "positive" or "negative") or "text")]))
    self.units:SetText(p.quote and tostring(p.quote.units) or ns.T("tradeNoPrice"))
    self.detail:SetText((p.detail or "") .. (p.quote and (p.quote.miss or 0) > 0 and ns.T("cacheIncomplete") or ""))
    self.detail:SetTextColor(unpack(K.theme.secondary))
    if p.quote and p.quote.vendor then self.refresh:Hide() else self.refresh:Show() end
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
