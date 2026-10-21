local _, ns = ...
local K = {}
ns.TradeKit = K
function K.Money(copper)
    if not copper then return ns.T("tradeNoPrice") end
    return (copper < 0 and "-" or "") .. GetCoinTextureString(math.floor(math.abs(copper) + 0.5))
end
function K.MoneyShort(copper, size)
    if not copper then return ns.T("tradeNoPrice") end
    local rounded = math.floor(math.abs(copper) / 100 + 0.5) * 100
    return (copper < 0 and "-" or "") .. GetCoinTextureString(rounded, size or 10)
end
K.theme = {
    white = "Interface\\Buttons\\WHITE8X8",
    grip = {art = "Interface\\AddOns\\ManaCode_AuctionScan\\art\\grip",
        cursor = "Interface\\AddOns\\ManaCode_AuctionScan\\art\\grip_cursor",
        blank = "Interface\\AddOns\\ManaCode_AuctionScan\\art\\blank",
        color = {1, 0.80, 0.30}, lit = {1, 0.93, 0.62}, press = {0.78, 0.58, 0.18}},
    marble = "Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-L1",
    highlight = "Interface\\QuestFrame\\UI-QuestTitleHighlight",
    actionIcons = {refresh = {"Interface\\PaperDollInfoFrame\\UI-GearManager-Undo"},
        buy = {"Interface\\Icons\\INV_Misc_Coin_01", 0.08, 0.92, 0.08, 0.92},
        hide = {"Interface\\Buttons\\UI-GroupLoot-Pass-Up"}},
    text = {0.96, 0.93, 0.87}, secondary = {0.74, 0.68, 0.58}, off = {0.52, 0.47, 0.40},
    gold = {1, 0.82, 0}, accent = {0.95, 0.78, 0.28},
    positive = {0.40, 0.82, 0.48}, negative = {0.94, 0.42, 0.34},
    background = {0.135, 0.115, 0.09, 1}, panel = {0.185, 0.16, 0.125, 1}, card = {0.235, 0.205, 0.165, 1},
    field = {0.075, 0.065, 0.05, 1},
    edge = {0.46, 0.40, 0.30, 1}, line = {1, 0.90, 0.70, 0.12},
    row = {1, 0.90, 0.70, 0.05}, selected = {1, 0.82, 0, 0.20}, match = {0.40, 0.82, 0.48, 0.20},
    hover = {1, 0.90, 0.70, 0.10}, head = {0.26, 0.225, 0.18, 1}, group = {0.165, 0.14, 0.11, 1}, subgroup = {0.125, 0.105, 0.085, 1},
    buttonSkin = {bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16,
        edgeSize = 10, insets = {left = 2, right = 2, top = 2, bottom = 2}},
    control = {bg = {0.32, 0.275, 0.215, 1}, hover = {0.40, 0.345, 0.27, 1},
        down = {0.24, 0.205, 0.16, 1}, edge = {0.60, 0.52, 0.40, 1}, text = {0.96, 0.93, 0.87}},
    main = {bg = {0.40, 0.30, 0.08, 1}, hover = {0.50, 0.38, 0.11, 1},
        down = {0.30, 0.22, 0.05, 1}, edge = {0.88, 0.72, 0.24, 1}, text = {1, 0.82, 0}},
    quiet = {bg = {1, 0.90, 0.70, 0.05}, hover = {1, 0.90, 0.70, 0.11},
        down = {0, 0, 0, 0.25}, edge = {0.46, 0.40, 0.30, 1}, text = {0.88, 0.84, 0.76}},
    nav = {bg = {0, 0, 0, 0}, hover = {1, 0.90, 0.70, 0.06},
        down = {0, 0, 0, 0.2}, edge = {0, 0, 0, 0}, text = {0.78, 0.72, 0.62}},
    segment = {bg = {0, 0, 0, 0}, hover = {1, 0.90, 0.70, 0.07},
        down = {0, 0, 0, 0.2}, edge = {0, 0, 0, 0}, text = {0.78, 0.72, 0.62}},
    chosen = {bg = {0.46, 0.40, 0.31, 1}, edge = {0.70, 0.61, 0.47, 1}, text = {1, 1, 1}},
    chart = {grid = {1, 1, 1, 0.07}, axis = {1, 1, 1, 0.20}, cursor = {1, 0.95, 0.75, 0.6},
        shade = {0, 0, 0, 0.8}, median = {0.72, 0.80, 0.92, 0.55}, minimum = {1, 0.82, 0},
        quartile = {0.38, 0.80, 0.48}, supply = {0.38, 0.60, 0.88}, added = {0.38, 0.80, 0.48},
        early = {0.86, 0.62, 0.30}, late = {0.60, 0.60, 0.64}, tile = {0.16, 0.17, 0.21, 1}},
}
function K.Label(parent, text, x, y, width, kind)
    local font = (kind == "heading" or kind == "title") and "GameFontNormal" or "GameFontHighlightSmall"
    local fs = parent:CreateFontString(nil, "OVERLAY", font)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetWidth(width)
    fs:SetJustifyH("LEFT")
    local color = kind == "title" and K.theme.gold or (kind == "secondary" and K.theme.secondary or K.theme.text)
    fs:SetTextColor(unpack(color))
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
    parent.tradeBase:SetVertexColor(unpack(K.theme.panel))
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
    local fill = skin[b.pressed and "down" or (b.hovered and "hover" or "bg")]
    local edge, text = skin.edge, skin.text
    if b.active and b.kind == "nav" then
        text = K.theme.gold
    elseif b.active and b.kind ~= "main" then
        fill, edge, text = K.theme.chosen.bg, K.theme.chosen.edge, K.theme.chosen.text
    end
    if b.btnDisabled and b.kind == "main" then fill, edge = K.theme.control.down, K.theme.edge end
    b:SetBackdropColor(unpack(fill))
    b:SetBackdropBorderColor(unpack(edge))
    b.text:SetTextColor(unpack(b.btnDisabled and K.theme.off or text))
    if rawget(b, "glyph") then
        b.glyph:SetDesaturated(b.btnDisabled); b.glyph:SetAlpha(b.btnDisabled and 0.5 or 1)
    end
    if rawget(b, "navLine") then
        if b.active then b.navLine:Show() else b.navLine:Hide() end
    end
    if rawget(b, "dot") then
        b.dot:SetVertexColor(unpack(b.btnDisabled and K.theme.off or (b.active and K.theme.accent or K.theme.edge)))
    end
end
function K.Button(parent, text, width, fn, kind, template)
    local b = ns.NewFrame("Button", nil, parent, template)
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
    if kind == "main" then b:SetHeight(26); K.LargeText(b) end
    if kind == "nav" then K.MakeNav(b) end
    b.nativeEnable, b.nativeDisable = b.Enable, b.Disable
    b.Enable = function(self) self.btnDisabled = false; self.nativeEnable(self); K.StyleButton(self) end
    b.Disable = function(self) self.btnDisabled = true; self.nativeDisable(self); K.StyleButton(self) end
    b.SetActive = function(self, active) self.active = active and true or false; K.StyleButton(self) end
    b:SetScript("OnEnter", function(self) self.hovered = true; K.StyleButton(self) end)
    b:SetScript("OnLeave", function(self) self.hovered, self.pressed = false, false; K.StyleButton(self) end)
    b:SetScript("OnMouseDown", function(self) self.pressed = not self.btnDisabled; K.StyleButton(self) end)
    b:SetScript("OnMouseUp", function(self) self.pressed = false; K.StyleButton(self) end)
    b:SetScript(template and "PreClick" or "OnClick", function(self, button)
        if not self.btnDisabled and self.onClick then self.onClick(self, button) end
    end)
    K.StyleButton(b)
    return b
end
function K.SetGlyph(b, key)
    local icon = key and K.theme.actionIcons[key]
    if not icon then
        if rawget(b, "glyph") then b.glyph:Hide() end
        return false
    end
    if not rawget(b, "glyph") then
        b.glyph = b:CreateTexture(nil, "ARTWORK")
        b.glyph:SetWidth(14); b.glyph:SetHeight(14)
        b.glyph:SetPoint("CENTER", b, "CENTER", 0, 0)
    end
    b.glyph:SetTexture(icon[1])
    b.glyph:SetTexCoord(icon[2] or 0, icon[3] or 1, icon[4] or 0, icon[5] or 1)
    b.glyph:Show()
    b:SetText(""); b:SetWidth(22)
    K.StyleButton(b)
    return true
end
function K.IconButton(parent, key, fn, title, tip)
    local b = K.Button(parent, "", 22, fn, "quiet")
    b:SetHeight(20)
    K.SetGlyph(b, key)
    K.Tooltip(b, title, tip)
    return b
end
function K.AuctionChrome(parent, root)
    root:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    root:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 12)
    root:SetFrameLevel(parent:GetFrameLevel() + 6)
    root:EnableMouse(true)
    K.Panel(root)
    root.tradeBase:SetVertexColor(unpack(K.theme.background))
    local chrome = {}
    chrome.title = K.Label(root, ns.T("tradeTitle"), 14, -11, 300, "title")
    chrome.close = ns.NewFrame("Button", nil, root, "UIPanelCloseButton")
    chrome.close:SetPoint("TOPRIGHT", root, "TOPRIGHT", -2, -2)
    chrome.close:SetScript("OnClick", function() HideUIPanel(parent) end)
    for _, y in ipairs({-33, -61}) do
        local line = K.Rule(root, y)
        line:SetPoint("TOPLEFT", root, "TOPLEFT", 6, y); line:SetPoint("TOPRIGHT", root, "TOPRIGHT", -6, y)
    end
    local foot = K.Rule(root, 0)
    foot:ClearAllPoints()
    foot:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 6, 30); foot:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -6, 30)
    chrome.money = root:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    chrome.money:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 14, 10)
    chrome.money:SetJustifyH("LEFT")
    chrome.status = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    chrome.status:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 190, 10)
    chrome.status:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -212, 10)
    chrome.status:SetJustifyH("LEFT")
    chrome.status:SetTextColor(unpack(K.theme.secondary))
    chrome.stop = K.Button(root, ns.T("tradeStop"), 70, nil)
    chrome.stop:SetHeight(20)
    chrome.stop:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -34, 6)
    chrome.resume = K.Button(root, ns.T("tradeResume"), 92, nil)
    chrome.resume:SetHeight(20)
    chrome.resume:SetPoint("RIGHT", chrome.stop, "LEFT", -6, 0)
    chrome.stop:Hide(); chrome.resume:Hide()
    chrome.rescan = K.Button(root, ns.T("tradeRescan"), 92, nil)
    chrome.rescan:SetHeight(20)
    chrome.rescan:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -34, 6)
    chrome.rescanDrop = K.Button(root, ns.T("tradeRescanDrop"), 80, nil, "quiet")
    chrome.rescanDrop:SetHeight(20)
    chrome.rescanDrop:SetPoint("RIGHT", chrome.rescan, "LEFT", -6, 0)
    chrome.rescan:Hide(); chrome.rescanDrop:Hide()
    chrome.progress = K.Progress(root)
    chrome.progress.frame:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 190, 5)
    chrome.progress.frame:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -212, 5)
    return chrome
end
function K.Progress(parent)
    local bar = {shown = 0, active = false, visible = false, phase = 0}
    bar.frame = ns.NewFrame("Frame", nil, parent)
    bar.frame:SetHeight(3)
    local track = bar.frame:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(K.theme.white); track:SetVertexColor(unpack(K.theme.field)); track:SetAllPoints(bar.frame)
    bar.fill = bar.frame:CreateTexture(nil, "ARTWORK")
    bar.fill:SetTexture(K.theme.white)
    bar.fill:SetPoint("TOPLEFT", bar.frame, "TOPLEFT", 0, 0); bar.fill:SetPoint("BOTTOMLEFT", bar.frame, "BOTTOMLEFT", 0, 0)
    local glintFrame = ns.NewFrame("Frame", nil, bar.frame)
    glintFrame:SetAllPoints(bar.frame)
    bar.glint = glintFrame:CreateTexture(nil, "OVERLAY")
    bar.glint:SetTexture(K.theme.white)
    bar.glint:SetPoint("TOPLEFT", bar.frame, "TOPLEFT", 0, 0); bar.glint:SetPoint("BOTTOMLEFT", bar.frame, "BOTTOMLEFT", 0, 0)
    bar.frame:Hide()
    bar.Set = function(self, share, active, visible)
        if visible and not self.visible then self.shown, self.phase = 0, 0 end
        if share and share < self.shown then self.shown = share end
        self.share, self.active, self.visible = share, active and true or false, visible and true or false
        if self.visible then self.frame:Show() else self.frame:Hide() end
    end
    bar.Tick = function(self, elapsed)
        if not self.visible then return end
        local width = self.frame:GetWidth() or 0
        if width <= 0 then return end
        if self.active then self.phase = (self.phase + elapsed / 1.4) % 1 end
        local span, segment
        if self.share then
            self.shown = self.shown + (self.share - self.shown) * math.min(1, elapsed * 6)
            span, segment = math.max(1, width * math.min(1, self.shown)), 48
            self.fill:SetWidth(span); self.fill:Show()
            self.fill:SetVertexColor(unpack(self.active and K.theme.accent or K.theme.off))
            ns.Gradient(self.glint, "HORIZONTAL", 1, 1, 1, 0, 1, 0.95, 0.80, 0.75)
        else
            span, segment = width, math.max(24, width * 0.25)
            self.fill:Hide()
            local a = K.theme.accent
            ns.Gradient(self.glint, "HORIZONTAL", a[1], a[2], a[3], 0, a[1], a[2], a[3], self.active and 1 or 0.4)
        end
        local head = self.phase * (span + segment)
        local left, right = math.max(0, head - segment), math.min(span, head)
        if (self.share and not self.active) or right - left < 1 then self.glint:Hide(); return end
        self.glint:ClearAllPoints()
        self.glint:SetPoint("TOPLEFT", self.frame, "TOPLEFT", left, 0)
        self.glint:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", left, 0)
        self.glint:SetWidth(right - left); self.glint:Show()
    end
    return bar
end
function K.NavDivider(parent, after)
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(K.theme.white); divider:SetVertexColor(unpack(K.theme.edge))
    divider:SetWidth(1); divider:SetHeight(16)
    divider:SetPoint("LEFT", after, "RIGHT", 8, 0)
    return divider
end
function K.Font(name, base, size)
    if not _G[name] then
        local font = CreateFont(name)
        local source = _G[base]
        font:SetFontObject(source)
        ns.SetFont(font, source:GetFont(), size, select(3, source:GetFont()))
    end
    return name
end
function K.NavText(b)
    local font = K.Font("ManaCodeNavFont", "GameFontNormal", 11)
    b:SetNormalFontObject(font); b:SetHighlightFontObject(font); b:SetDisabledFontObject(font)
    b.text:SetFontObject(font)
end
function K.HoverMenu(menu)
    local away = 0
    menu.frame:HookScript("OnEnter", function() if not menu.frame.btnDisabled then menu.cover:Show() end end)
    menu.cover:HookScript("OnShow", function() away = 0 end)
    menu.cover:SetScript("OnUpdate", function(_, elapsed)
        if MouseIsOver(menu.frame) or MouseIsOver(menu.panel) then away = 0; return end
        away = away + elapsed
        if away > 0.3 then menu.cover:Hide() end
    end)
end
function K.MakeNav(b)
    b.kind = "nav"
    b:SetHeight(26)
    K.NavText(b)
    if not rawget(b, "navLine") then
        b.navLine = b:CreateTexture(nil, "ARTWORK")
        b.navLine:SetTexture(K.theme.white)
        b.navLine:SetVertexColor(unpack(K.theme.gold))
        b.navLine:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 4, 1)
        b.navLine:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -4, 1)
        b.navLine:SetHeight(2)
    end
    K.StyleButton(b)
    return b
end
function K.Chip(parent, text, changed)
    local b = K.Button(parent, text, 80, nil, "quiet")
    b.checked = false
    b.dot = b:CreateTexture(nil, "ARTWORK")
    b.dot:SetTexture(K.theme.white); b.dot:SetWidth(6); b.dot:SetHeight(6)
    b.dot:SetPoint("LEFT", b, "LEFT", 8, 0)
    b.text:ClearAllPoints()
    b.text:SetPoint("LEFT", b, "LEFT", 19, 0); b.text:SetPoint("RIGHT", b, "RIGHT", -8, 0)
    b.text:SetJustifyH("LEFT")
    b.SetChecked = function(self, value) self.checked = value and true or false; self:SetActive(self.checked) end
    b.GetChecked = function(self) return self.checked end
    b.onClick = function(self) self:SetChecked(not self.checked); changed(self.checked) end
    K.FitButton(b, 32)
    K.StyleButton(b)
    return b
end
function K.Segment(parent, entries, choose)
    local seg = {buttons = {}, order = {}}
    seg.frame = ns.NewFrame("Frame", nil, parent)
    seg.frame:SetHeight(22)
    seg.frame:SetBackdrop(K.theme.buttonSkin)
    seg.frame:SetBackdropColor(unpack(K.theme.quiet.bg))
    seg.frame:SetBackdropBorderColor(unpack(K.theme.edge))
    local x = 2
    for i, entry in ipairs(entries) do
        local key = entry.key
        local b = K.Button(seg.frame, entry.label, 60, function() choose(key) end, "segment")
        b:SetHeight(18)
        K.FitButton(b, 20)
        b:SetPoint("LEFT", seg.frame, "LEFT", x, 0)
        x = x + (b:GetWidth() or 60) + 1
        seg.buttons[key], seg.order[i] = b, b
    end
    seg.frame:SetWidth(x + 1)
    seg.Select = function(self, key) for k, b in pairs(self.buttons) do b:SetActive(k == key) end end
    seg.Enable = function(self) for _, b in ipairs(self.order) do b:Enable() end end
    seg.Disable = function(self) for _, b in ipairs(self.order) do b:Disable() end end
    return seg
end
function K.Card(parent)
    local card = ns.NewFrame("Frame", nil, parent)
    card:SetBackdrop(K.theme.buttonSkin)
    card:SetBackdropColor(unpack(K.theme.card))
    card:SetBackdropBorderColor(unpack(K.theme.edge))
    return card
end
function K.LargeText(b)
    b:SetNormalFontObject("GameFontNormal")
    b:SetHighlightFontObject("GameFontHighlight")
    b:SetDisabledFontObject("GameFontHighlight")
    b.text:SetFontObject("GameFontNormal")
end
function K.FitButton(b, pad)
    b:SetWidth(math.ceil((b.text:GetStringWidth() or 60) + (pad or 24)))
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
    edit:SetBackdrop(K.theme.buttonSkin)
    edit:SetBackdropColor(unpack(K.theme.field))
    edit:SetBackdropBorderColor(unpack(K.theme.edge))
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local native = edit.SetScript
    edit.SetScript = function(self, name, fn)
        if name ~= "OnEditFocusGained" and name ~= "OnEditFocusLost" then native(self, name, fn); return end
        local color = name == "OnEditFocusGained" and K.theme.accent or K.theme.edge
        native(self, name, function(box, ...)
            box:SetBackdropBorderColor(unpack(color))
            if fn then fn(box, ...) end
        end)
    end
    edit:SetScript("OnEditFocusGained", nil)
    edit:SetScript("OnEditFocusLost", nil)
    return edit
end
function K.LiveEdit(edit, apply, delay)
    local wait = delay or 0.4
    local function flush(box)
        if not box.liveAt then return end
        box.liveAt = nil
        box:SetScript("OnUpdate", nil)
        apply(box)
    end
    edit:SetScript("OnTextChanged", function(box, typed)
        if not typed then return end
        box.liveAt = GetTime() + wait
        box:SetScript("OnUpdate", function(self) if self.liveAt and GetTime() >= self.liveAt then flush(self) end end)
    end)
    edit:SetScript("OnEnterPressed", function(box)
        box.liveAt = box.liveAt or GetTime()
        flush(box)
        box:ClearFocus()
    end)
end
function K.Window(parent, title, width, height)
    local frame = ns.NewFrame("Frame", nil, parent)
    frame:SetWidth(width); frame:SetHeight(height)
    frame:SetPoint("CENTER", parent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG"); frame:EnableMouse(true)
    frame:SetMovable(true); frame:SetClampedToScreen(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    K.Panel(frame)
    frame.heading = K.Label(frame, title, 14, -12, width - 100, "heading")
    frame.close = K.Button(frame, ns.T("acCloseWindow"), 66, function() frame:Hide() end, "quiet")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -8)
    frame:Hide()
    return frame
end
local RecordRow = {}
RecordRow.__index = RecordRow
K.RecordRow = RecordRow
function RecordRow:New(parent, choose)
    local row = setmetatable({}, self)
    row.frame = K.ItemChoice(parent, function() if row.props then choose(row.props.key) end end)
    row.frame:SetHeight(42); row.frame.icon:SetWidth(26); row.frame.icon:SetHeight(26)
    row.detail = K.Label(row.frame, "", 32, -24, 300)
    row.detail:SetTextColor(unpack(K.theme.secondary))
    row.amount = K.Label(row.frame, "", 0, -6, 170)
    row.amount:ClearAllPoints(); row.amount:SetPoint("TOPRIGHT", row.frame, "TOPRIGHT", -8, -6)
    row.amount:SetJustifyH("RIGHT")
    row.state = K.Label(row.frame, "", 0, -24, 170)
    row.state:ClearAllPoints(); row.state:SetPoint("TOPRIGHT", row.frame, "TOPRIGHT", -8, -24)
    row.state:SetJustifyH("RIGHT")
    row.result = K.ItemChoice(row.frame, function() if row.props then choose(row.props.key) end end)
    row.result:SetPoint("TOPRIGHT", row.frame, "TOPRIGHT", -8, -23)
    row.result:SetHeight(18); row.result.icon:SetWidth(14); row.result.icon:SetHeight(14)
    row.result.text:ClearAllPoints(); row.result.text:SetPoint("LEFT", row.result, "LEFT", 20, 0)
    return row
end
function RecordRow:SetProps(props)
    self.props = props; self:Render()
end
function RecordRow:Render()
    local p, frame = self.props, self.frame
    local width, side = p.width or 700, math.min(210, (p.width or 700) * 0.38)
    frame:SetWidth(width)
    if p.itemID then
        K.SetItemChoice(frame, p.itemID, p.active)
        frame.itemLink = p.link and p.link:find("item:", 1, true) and p.link or nil
        frame.extraTip = p.tip
    else
        frame.itemID = nil; frame.icon:SetTexture(nil); frame.text:SetText(p.title or "")
        frame.text:SetTextColor(unpack(K.theme.text)); frame:Show()
        if p.active then frame.selected:Show() else frame.selected:Hide() end
    end
    frame.text:ClearAllPoints(); frame.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 32, -6)
    frame.text:SetWidth(math.max(40, width - side - 44))
    self.detail:SetWidth(math.max(40, width - side - 44))
    self.amount:SetWidth(side); self.state:SetWidth(side)
    self.detail:SetText(p.detail or ""); self.amount:SetText(p.amount or ""); self.state:SetText(p.state or "")
    if p.outputID then
        K.SetItemChoice(self.result, p.outputID, false)
        self.result:SetWidth(side); self.result.text:SetWidth(side - 22)
        self.result.text:SetText(ns.Markets.Name(p.outputID) .. " x" .. p.outputCount)
        self.state:Hide()
    else self.result:Hide(); self.state:Show() end
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
        GameTooltip:SetHyperlink(self.itemLink or ("item:" .. self.itemID))
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
function K.ItemsArrived()
    if ns.Trader and ns.Trader.frame then ns.Trader.Refresh() end
end
function K.SetItemChoice(b, id, active, quality)
    b.itemID = id
    b.itemLink = nil
    local _, _, rarity = ns.Compat.ItemInfo(id)
    if not rarity then ns.Compat.RequestItem(id, K.ItemsArrived) end
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
    parent.tradeHeadLine = parent:CreateTexture(nil, "BORDER")
    parent.tradeHeadLine:SetTexture(K.theme.white); parent.tradeHeadLine:SetVertexColor(unpack(K.theme.edge))
    parent.tradeHeadLine:SetPoint("TOPLEFT", band, "BOTTOMLEFT", 0, 0)
    parent.tradeHeadLine:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT", 0, 0); parent.tradeHeadLine:SetHeight(1)
    band:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -302, y + 5); band:SetHeight(20)
    return band
end
function K.HeaderBand(parent)
    local band = parent:CreateTexture(nil, "BACKGROUND")
    band:SetTexture(K.theme.white); band:SetVertexColor(unpack(K.theme.head))
    band:SetAllPoints(parent)
    local line = parent:CreateTexture(nil, "BORDER")
    line:SetTexture(K.theme.white); line:SetVertexColor(unpack(K.theme.edge))
    line:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0); line:SetHeight(1)
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
local Inspector = {all = {}}
Inspector.__index = Inspector
K.Inspector = Inspector
function Inspector:New(parent)
    local view = setmetatable({parent = parent, top = -2}, self)
    local panel = ns.NewFrame("Frame", nil, parent)
    view.frame = panel
    panel:SetFrameLevel(parent:GetFrameLevel() + 12)
    panel:EnableMouse(true); K.Panel(panel)
    view.item = K.ItemChoice(panel, function() if view.props then Inspector.Switch("market", view.props.id) end end)
    view.item.extraTip = ns.T("itemHistoryOpenTip")
    view.item:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -6)
    view.item:SetWidth(180); view.item.text:SetWidth(148)
    view.item:SetHeight(30); view.item.text:SetHeight(26); view.item.text:SetJustifyV("MIDDLE")
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
        view.actions.frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -10)
        K.Tooltip(view.actions.frame, ns.T("collectionActions"), ns.T("collectionActionsTip"))
    end
    view.market = K.Button(panel, ns.T("inspectorMarket"), 117, function()
        if view.props then Inspector.Switch("market", view.props.id) end
    end)
    view.market:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -40)
    K.Tooltip(view.market, ns.T("inspectorMarket"), ns.T("inspectorMarketTip"))
    view.offers = K.Button(panel, ns.T("offersOpen"), 117, function()
        if view.item.itemID then ns.OfferPreview.Open(view.item.itemID) end
    end, "quiet")
    view.offers:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -40)
    K.Tooltip(view.offers, ns.T("offersTitle"), ns.T("offersOpenTip"))
    K.Rule(panel, -66)
    view.body = ns.NewFrame("Frame", nil, panel)
    view.body:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -26)
    view.body:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    panel:HookScript("OnShow", function() view:Layout() end)
    Inspector.all[#Inspector.all + 1] = view
    view:Layout()
    return view
end
function Inspector.Switch(mode, id)
    if mode == "market" then
        local target = id or Inspector.lastID
        if target and ns.MarketWindow then ns.MarketWindow.Open(target) end
    elseif ns.MarketWindow then ns.MarketWindow.Close() end
end
function Inspector:Place(top, bottom)
    if self.top == top and self.bottom == bottom then return end
    self.top, self.bottom = top, bottom; self:Layout()
end
function Inspector:Layout()
    local panel = self.frame
    panel:ClearAllPoints()
    panel:SetPoint("TOPRIGHT", self.parent, "TOPRIGHT", -6, self.top)
    panel:SetPoint("BOTTOMRIGHT", self.parent, "BOTTOMRIGHT", -6, self.bottom or 2)
    panel:SetWidth(264)
    local item = self.actions and 210 or 240
    self.item:SetWidth(item); self.item.text:SetWidth(item - 32)
    self.body:Show()
end
function Inspector:SetProps(props)
    self.props = props
    Inspector.lastID = props.id
    self:Render()
end
function Inspector:Clear()
    self.props = nil
    self.item:Hide(); self.offers:Hide(); self.market:Hide()
    if self.actions then self.actions.frame:Hide() end
    self:Layout()
end
function Inspector:Render()
    K.SetItemChoice(self.item, self.props.id, self.props.active)
    self.offers:Show(); self.market:Show()
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
function K.ResizeGrip(parent, limits, allowed, apply, reset)
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
    grip:SetWidth(22); grip:SetHeight(22)
    grip:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -3, 15)
    grip:SetFrameStrata("FULLSCREEN")
    grip:RegisterForClicks("RightButtonUp")
    grip:SetScript("OnClick", function(_, button)
        if button == "RightButton" and reset and allowed() then reset() end
    end)
    grip.art = grip:CreateTexture(nil, "ARTWORK")
    grip.art:SetAllPoints(grip); grip.art:SetTexture(K.theme.grip.art)
    grip.art:SetVertexColor(unpack(K.theme.grip.color))
    local glow = grip:CreateTexture(nil, "HIGHLIGHT")
    glow:SetAllPoints(grip); glow:SetTexture(K.theme.grip.art); glow:SetBlendMode("ADD")
    glow:SetVertexColor(unpack(K.theme.grip.lit)); glow:SetAlpha(0.35)
    local screen = UIParent or parent
    local badge = ns.NewFrame("Frame", nil, screen)
    badge:SetFrameStrata("TOOLTIP"); badge:SetWidth(24); badge:SetHeight(24); badge:Hide()
    local arrow = badge:CreateTexture(nil, "OVERLAY")
    arrow:SetAllPoints(badge); arrow:SetTexture(K.theme.grip.cursor); arrow:SetTexCoord(0, 0.78125, 0, 0.78125)
    badge:SetScript("OnUpdate", function(self)
        if not GetCursorPosition or not SetCursor then return end
        local scale = screen:GetEffectiveScale()
        local x, y = GetCursorPosition()
        self:ClearAllPoints(); self:SetPoint("CENTER", screen, "BOTTOMLEFT", x / scale, y / scale)
        SetCursor(K.theme.grip.blank)
    end)
    badge:SetScript("OnHide", function() if ResetCursor then ResetCursor() end end)
    grip.badge = badge
    grip:HookScript("OnEnter", function(self) badge:Show(); self.art:SetVertexColor(unpack(K.theme.grip.lit)) end)
    grip:HookScript("OnLeave", function(self)
        if outline.active then return end
        badge:Hide(); self.art:SetVertexColor(unpack(K.theme.grip.color))
    end)
    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or not allowed() then return end
        grip.art:SetVertexColor(unpack(K.theme.grip.press))
        outline.x0, outline.y0 = cursor(parent)
        outline.width0, outline.height0 = parent:GetWidth(), parent:GetHeight()
        outline.width, outline.height = nil, nil
        outline.active = true
        follow(outline)
        outline:SetScript("OnUpdate", follow)
        outline:Show()
        GameTooltip:Hide()
    end)
    grip:SetScript("OnMouseUp", function(self)
        local over = self:IsMouseOver()
        self.art:SetVertexColor(unpack(over and K.theme.grip.lit or K.theme.grip.color))
        if not over then badge:Hide() end
        if not outline.active then return end
        local width, height = measure()
        stop()
        apply(width, height)
    end)
    grip:SetScript("OnHide", function() stop(); badge:Hide() end)
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
    menu.panel = panel
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
function K.MarketColumns(width)
    return {item = {0, width - 304}, price = {width - 304, 104},
        margin = {width - 194, 118}, units = {width - 70, 40}}
end
function MarketRow:New(parent, selectRow, toggleMaterial, toggleHide)
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
    row.match:SetVertexColor(unpack(K.theme.match)); row.match:Hide()
    row.matchBar = row.frame:CreateTexture(nil, "BORDER")
    row.matchBar:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 0, 0)
    row.matchBar:SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0)
    row.matchBar:SetWidth(4); row.matchBar:SetTexture(K.theme.white)
    row.matchBar:SetVertexColor(unpack(K.theme.positive)); row.matchBar:Hide()
    row.frame:SetHeight(30)
    row.frame.text:SetWidth(205)
    row.price = K.Label(row.frame, "", 240, -3, 120)
    row.margin = K.Label(row.frame, "", 365, -3, 120)
    row.marginRate = K.Label(row.frame, "", 0, 0, 118)
    row.marginRate:SetTextColor(unpack(K.theme.secondary))
    row.units = K.Label(row.frame, "", 490, -3, 50)
    row.tag = K.Label(row.frame, "", 0, -3, K.ITEM_TAG)
    row.tag:SetHeight(12); row.tag:SetJustifyH("RIGHT"); row.tag:Hide()
    row.detail = K.Label(row.frame, "", 28, -17, 440)
    row.detail:ClearAllPoints()
    row.detail:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 28, -14)
    row.detail:SetHeight(10)
    row.frame.text:ClearAllPoints()
    row.frame.text:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 28, -2)
    row.frame.text:SetHeight(12)
    row.refresh = K.IconButton(row.frame, "refresh", function()
        if row.props.action then row.props.action(row.props.id) else ns.Markets.Scan(row.props.id) end
    end, ns.T("cacheRefreshItem"), ns.T("cacheRefreshTip"))
    row.refresh:SetPoint("RIGHT", row.frame, "RIGHT", -2, 0)
    if toggleHide then
        row.hide = K.Button(row.frame, ns.T("hiddenHide"), 66, function() toggleHide(row.props.id, row.props) end, "quiet")
        row.hide:SetHeight(20)
        row.hide:SetPoint("RIGHT", row.refresh, "LEFT", -4, 0)
    end
    if toggleMaterial then
        row.expand = K.Button(row.frame, "+", 16, function() toggleMaterial(row.props.id, row.props) end, "quiet")
        row.expand.text:ClearAllPoints(); row.expand.text:SetPoint("CENTER", row.expand, "CENTER", 0, 0)
        K.Tooltip(row.expand, ns.T("craftMaterialSource"), ns.T("craftTreeTip"))
    end
    row.buttons = {row.refresh}
    if row.hide then row.buttons[2] = row.hide end
    return row
end
function MarketRow:Reveal()
    if self.refreshWanted then self.refresh:Show() else self.refresh:Hide() end
    if self.hide then
        if self.hideWanted then self.hide:Show() else self.hide:Hide() end
    end
end
function MarketRow:SetProps(props)
    self.props = props
    self:Render()
end
function MarketRow:Render()
    local p = self.props
    self.frame.extraTip = p.extraTip
    K.SetItemChoice(self.frame, p.id, p.active, p.quality)
    local columns = p.width and K.MarketColumns(p.width - (p.reserve or 0))
    if self.hide then
        if p.hideable then
            if p.hideLabel then
                K.SetGlyph(self.hide, nil); self.hide:SetText(p.hideLabel); self.hide:SetWidth(66)
            else K.SetGlyph(self.hide, "hide") end
            K.Tooltip(self.hide, p.hideLabel or ns.T("hiddenHide"), ns.T(p.hidden and "hiddenRestoreTip" or "hiddenHideTip"))
            self.hideWanted = true
        else self.hideWanted = false end
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
        if p.expandable then self.expand:Show() else self.expand:Hide() end
    end
    if p.tag and columns then
        self.tag:ClearAllPoints()
        self.tag:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", columns.item[2] - 6, -2)
        self.tag:SetText(p.tag); self.tag:SetTextColor(unpack(K.theme.accent)); self.tag:Show()
        self.frame.text:SetWidth(math.max(40, (self.frame.text:GetWidth() or columns.item[2]) - K.ITEM_TAG))
    else self.tag:Hide() end
    self.price:SetText(K.Money(p.quote and p.quote.price))
    self.margin:SetText(p.marginText or K.Money(p.margin))
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
    self.refreshWanted = not (p.noRefresh or (p.quote and p.quote.vendor))
    self:Reveal()
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
    view.scroll = K.Scroller:New(view.frame, function() view:Render() end, 46)
    view.scroll.frame:SetAllPoints(view.frame)
    for i = 1, 4 do
        local card = {}
        card.frame = K.ItemChoice(view.frame, function() end)
        card.frame:SetHeight(42)
        card.back = card.frame:CreateTexture(nil, "BACKGROUND")
        card.back:SetAllPoints(card.frame); card.back:SetTexture(K.theme.white)
        card.back:SetVertexColor(unpack(K.theme.row))
        card.frame.selected:SetDrawLayer("BORDER")
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
            card.chance:SetText(K.Chance(output.chance))
            card.line:SetWidth(math.max(40, width - 48))
            card.line:SetText(ns.T("deCardLine", (string.format("%.2f", output.quantity):gsub("%.", ",")),
                K.MoneyShort(output.price), K.MoneyShort(output.price and output.quantity * output.price)))
            card.frame.extraTip = output.id == self.props.target and ns.T("deTargetOutcome") or ns.T("deOtherOutcome")
        else card.frame:Hide() end
    end
end
function K.Chance(chance)
    local value = chance * 100
    local text = value >= 10 and string.format("%.0f", value) or (string.format("%.1f", value):gsub("%.0$", ""))
    return (text:gsub("%.", ",")) .. "%"
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
function K.DayShift()
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
function TimeChart:Rect(layer, color, x, y, w, h, alpha, gradient)
    local pool = self.pools[layer]
    pool.used = pool.used + 1
    local t = pool[pool.used]
    if not t then
        t = self.frame:CreateTexture(nil, layer); t:SetTexture(K.theme.white)
        pool[pool.used] = t
    end
    t:ClearAllPoints(); t:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, -y)
    t:SetWidth(math.max(1, w)); t:SetHeight(math.max(1, h))
    local a = (color[4] or 1) * (alpha or 1)
    if gradient then
        t:SetVertexColor(1, 1, 1, 1)
        ns.Gradient(t, "VERTICAL", color[1], color[2], color[3], 0.02, color[1], color[2], color[3], a)
    else
        ns.Gradient(t, "VERTICAL", 1, 1, 1, 1, 1, 1, 1, 1)
        t:SetVertexColor(color[1], color[2], color[3], a)
    end
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
    local gutter, axis = 8, 72
    local plot = width - gutter - axis
    local count = math.max(8, math.min(120, math.floor(plot / 6)))
    local layout = {gutter = gutter, plot = plot, axis = gutter + plot, axisWidth = axis, count = count, slot = plot / count,
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
        if track.kind == "price" then self:Price(box) elseif track.kind == "bars" then self:Bars(box) else self:Flow(box) end
        top = top + h + gap
    end
    layout.bottom = top - gap
    self:Ruler()
end
function TimeChart:Header(box)
    local track, x = box.track, self.layout.gutter
    local title = self:Text(track.title, x, box.top - 15, 200, "LEFT", K.theme.text)
    x = x + math.min(200, title:GetStringWidth() or 120) + 10
    if track.change then
        local change = self:Text(track.change, x, box.top - 15, 140, "LEFT", K.theme[track.tone or "secondary"])
        x = x + math.min(140, change:GetStringWidth() or 60) + 14
    end
    local legend = {}
    for _, series in ipairs(track.series) do legend[#legend + 1] = series end
    for _, series in ipairs(track.down or {}) do legend[#legend + 1] = series end
    for _, series in ipairs(track.extraLegend or {}) do legend[#legend + 1] = series end
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
        self:Text(box.track.format(value), layout.axis + 6, y - 6, layout.axisWidth - 8, "LEFT")
        value = value + step
    end
    self:Rect("BACKGROUND", K.theme.chart.axis, layout.axis, box.top, 1, box.height)
end
function TimeChart:Center(i)
    return self.layout.gutter + (i - 0.5) * self.layout.slot
end
function TimeChart:Price(box)
    local layout, track, p = self.layout, box.track, self.props
    local candles = p.mode == "candles" and p.candles and p.candles() or nil
    if candles and #candles == 0 then candles = nil end
    local low, high
    local function widen(value)
        if value then low, high = math.min(low or value, value), math.max(high or value, value) end
    end
    if candles then
        for _, candle in ipairs(candles) do widen(candle.low); widen(candle.high) end
    else
        for i = 1, layout.count do
            local b = layout.buckets[i]
            for _, series in ipairs(b and track.series or {}) do widen(b[series.field]) end
        end
    end
    for _, reference in ipairs(track.references or {}) do widen(reference.value) end
    for _, marker in ipairs(track.markers or {}) do
        if marker.at >= p.from and marker.at <= p.to then widen(marker.value) end
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
    for _, reference in ipairs(track.references or {}) do
        local y = box.scale(reference.value)
        for x = layout.gutter, layout.gutter + layout.plot - 4, 10 do
            self:Rect("BORDER", reference.color, x, y, 5, 1)
        end
    end
    if candles then self:Candles(box, candles) else self:Lines(box) end
    for _, marker in ipairs(track.markers or {}) do
        if marker.at >= p.from and marker.at <= p.to then
            local x = layout.gutter + (marker.at - p.from) / layout.span * layout.plot
            x = math.max(layout.gutter + 3, math.min(layout.gutter + layout.plot - 3, x))
            self:Rect("ARTWORK", marker.color, x - 3, box.scale(marker.value) - 3, 6, 6)
        end
    end
    if track.last then
        local y = math.max(box.top + 7, math.min(base - 7, box.scale(track.last)))
        self:Rect("ARTWORK", K.theme.chart.shade, layout.axis + 2, y - 7, layout.axisWidth - 4, 14, 0.9)
        self:Rect("ARTWORK", K.theme[track.tone or "text"], layout.axis, y, 4, 1)
        self:Text(track.format(track.last), layout.axis + 6, y - 6, layout.axisWidth - 8, "LEFT", K.theme[track.tone or "text"])
    end
end
function TimeChart:Segment(box, series, x0, y0, x1, y1, dim)
    local thick, base = series.thick or 2, box.top + box.height
    local x, dx = x0, math.max(1, x1 - x0)
    while x < x1 do
        local w = math.min(2, x1 - x)
        local ya = y0 + (y1 - y0) * (x - x0) / dx
        local yb = y0 + (y1 - y0) * (x + w - x0) / dx
        local top = math.min(ya, yb) - thick / 2
        self:Rect("ARTWORK", series.color, x, top, w, math.abs(yb - ya) + thick, dim and 0.35 or 1)
        if series.area and base - top - thick > 1 then
            self:Rect("BORDER", series.color, x, top + thick, w, base - top - thick, dim and 0.08 or 0.28, true)
        end
        x = x + w
    end
end
function TimeChart:Lines(box)
    local layout, track = self.layout, box.track
    local limit = math.max(1, math.ceil(43200 / (layout.span / layout.count)))
    for _, series in ipairs(track.series) do
        local last, lastValue
        for i = 1, layout.count do
            local b = layout.buckets[i]
            local value = b and b[series.field]
            if value then
                if last then
                    self:Segment(box, series, self:Center(last), box.scale(lastValue), self:Center(i), box.scale(value),
                        i - last > limit)
                end
                if series.dots and layout.slot >= 4 then
                    self:Rect("ARTWORK", series.color, self:Center(i) - 2, box.scale(value) - 2, 4, 4)
                end
                last, lastValue = i, value
            end
        end
        if last and last < layout.count then
            self:Segment(box, series, self:Center(last), box.scale(lastValue), layout.gutter + layout.plot,
                box.scale(lastValue), true)
        end
    end
end
function TimeChart:Candles(box, candles)
    local layout, p = self.layout, self.props
    local width = math.max(3, math.min(12, math.floor(layout.plot / math.max(1, p.days or 7) * 0.6)))
    for _, candle in ipairs(candles) do
        local x = layout.gutter + (candle.at - p.from) / layout.span * layout.plot
        x = math.max(layout.gutter + width / 2, math.min(layout.gutter + layout.plot - width / 2, x))
        local color = K.theme[candle.close >= candle.open and "positive" or "negative"]
        local top, bottom = box.scale(math.max(candle.open, candle.close)), box.scale(math.min(candle.open, candle.close))
        self:Rect("ARTWORK", color, x - width / 2, top, width, math.max(1, bottom - top))
        self:Rect("BORDER", color, x - 0.5, box.scale(candle.high), 1, math.max(1, box.scale(candle.low) - box.scale(candle.high)))
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
    local shift = K.DayShift()
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
    for _, box in ipairs(layout.boxes) do
        for index, marker in ipairs(box.scale and box.track.markers or {}) do
            local px = layout.gutter + (marker.at - self.props.from) / layout.span * layout.plot
            if marker.at >= self.props.from and marker.at <= self.props.to and math.abs(x - px) <= 7 and self.props.markerTip then
                local key = "marker:" .. index
                if self.hovered == key then return end
                self:Unhover(); self.hovered = key
                self.anchor:ClearAllPoints(); self.anchor:SetPoint("TOPLEFT", self.frame, "TOPLEFT", px, -box.scale(marker.value))
                GameTooltip:SetOwner(self.anchor, "ANCHOR_RIGHT")
                local title, body = self.props.markerTip(marker)
                GameTooltip:AddLine(title, unpack(K.theme.gold))
                GameTooltip:AddLine(body, unpack(K.theme.text)); GameTooltip:Show()
                return
            end
        end
    end
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
        for _, series in ipairs(box.track.kind == "price" and box.scale and self.props.mode ~= "candles" and box.track.series or {}) do
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
function K.Modal(parent, name)
    local dim = ns.NewFrame("Frame", name, parent)
    dim:SetAllPoints(parent)
    dim:SetFrameStrata("DIALOG")
    dim:SetFrameLevel(parent:GetFrameLevel() + 40)
    dim:EnableMouse(true)
    local shade = dim:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints(dim); shade:SetTexture(K.theme.white); shade:SetVertexColor(0, 0, 0, 0.62)
    local window = ns.NewFrame("Frame", nil, dim)
    window:SetPoint("CENTER", dim, "CENTER", 0, 0)
    window:EnableMouse(true)
    K.Panel(window)
    dim.window = window
    dim.close = ns.NewFrame("Button", nil, window, "UIPanelCloseButton")
    dim.close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -2, -2)
    dim.close:SetScript("OnClick", function() dim:Hide() end)
    dim.Layout = function(self)
        local width = math.max(600, math.min(940, (parent:GetWidth() or 996) - 40))
        local height = math.max(380, math.min(580, (parent:GetHeight() or 540) - 40))
        window:SetWidth(width); window:SetHeight(height)
    end
    dim:SetScript("OnShow", function(self) self:Layout() end)
    dim:Layout()
    dim:Hide()
    if type(UISpecialFrames) == "table" then tinsert(UISpecialFrames, name) end
    return dim
end
function K.DisenchantColumns(width, target, refresh)
    local action, level, price, margin, rate = refresh and 54 or 30, 40, 86, 92, 58
    local via, viaRate = target and 88 or 0, target and 70 or 0
    local rest = width - action - level - price - margin - rate - via - viaRate
    if target and rest < 200 then rest, viaRate = rest + viaRate, 0 end
    if target and rest < 200 then rest, via = rest + via, 0 end
    local columns, x = {item = {0, rest}}, rest
    for _, column in ipairs({{"ilvl", level}, {"price", price}, {"margin", margin}, {"rate", rate},
        {"via", via}, {"viaRate", viaRate}}) do
        if column[2] > 0 then columns[column[1]] = {x, column[2]}; x = x + column[2] end
    end
    columns.action = {x, action}
    return columns
end
local GroupRow = {}
GroupRow.__index = GroupRow
K.GroupRow = GroupRow
function GroupRow:New(parent, toggle)
    local row = setmetatable({}, self)
    row.frame = ns.NewFrame("Button", nil, parent)
    row.frame:SetHeight(30)
    row.back = row.frame:CreateTexture(nil, "BACKGROUND")
    row.back:SetAllPoints(row.frame); row.back:SetTexture(K.theme.white)
    row.back:SetVertexColor(unpack(K.theme.group))
    local hover = row.frame:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(row.frame); hover:SetTexture(K.theme.white)
    hover:SetVertexColor(unpack(K.theme.hover)); row.frame:SetHighlightTexture(hover)
    row.caret = K.Label(row.frame, "", 8, -6, 12, "secondary")
    row.caret:ClearAllPoints(); row.caret:SetPoint("LEFT", row.frame, "LEFT", 8, 0)
    row.name = K.Label(row.frame, "", 22, -6, 200)
    row.name:SetHeight(12)
    row.name:ClearAllPoints(); row.name:SetPoint("LEFT", row.frame, "LEFT", 22, 0)
    row.detail = K.Label(row.frame, "", 0, -6, 300, "secondary")
    row.detail:SetHeight(12)
    row.detail:ClearAllPoints(); row.detail:SetPoint("LEFT", row.name, "RIGHT", 6, 0)
    row.tag = K.Label(row.frame, "", 0, -6, 180, "secondary")
    row.tag:SetHeight(12); row.tag:SetJustifyH("RIGHT")
    row.tag:ClearAllPoints(); row.tag:SetPoint("RIGHT", row.frame, "RIGHT", -8, 0)
    row.frame:SetScript("OnClick", function() toggle(row.props.key) end)
    row.buttons = {}
    for i = 1, 3 do
        local button = K.Button(row.frame, "", 60, function()
            local action = row.props.actions and row.props.actions[i]
            if action then action.fn(row.props.key, row.props) end
        end, "quiet")
        button:SetHeight(20)
        button:Hide()
        row.buttons[i] = button
    end
    row.buttons[3]:SetPoint("RIGHT", row.frame, "RIGHT", -4, 0)
    row.buttons[2]:SetPoint("RIGHT", row.buttons[3], "LEFT", -3, 0)
    row.buttons[1]:SetPoint("RIGHT", row.buttons[2], "LEFT", -3, 0)
    return row
end
function GroupRow:SetProps(props)
    self.props = props; self:Render()
end
function GroupRow:Render()
    local p = self.props
    self.frame:SetWidth(p.width)
    if p.sub then self.frame:SetHeight(20) elseif p.height then self.frame:SetHeight(p.height) end
    self.back:SetVertexColor(unpack(K.theme[p.sub and "subgroup" or "group"]))
    local reserve = (p.actionWidth or 0) + 8
    if p.sub then
        self.caret:Hide(); self.name:Hide()
        self.detail:ClearAllPoints(); self.detail:SetPoint("LEFT", self.frame, "LEFT", 22, 0)
        self.detail:SetWidth(math.max(40, p.width - 30))
    else
        self.caret:Show(); self.name:Show()
        self.caret:SetText(p.open and "-" or "+")
        self.name:SetWidth(300)
        self.name:SetText(p.name)
        self.name:SetWidth(math.min(240, math.max(40, (self.name:GetStringWidth() or 120) + 4)))
        self.detail:ClearAllPoints(); self.detail:SetPoint("LEFT", self.name, "RIGHT", 6, 0)
        self.detail:SetWidth(math.max(40, p.width - 60 - reserve - 120 - (self.name:GetWidth() or 120)))
    end
    self.detail:SetText(p.detail or "")
    self.tag:ClearAllPoints(); self.tag:SetPoint("RIGHT", self.frame, "RIGHT", -reserve, 0)
    self.tag:SetText(p.sub and "" or (p.tag or ""))
    self.tag:SetTextColor(unpack(K.theme[p.tone or "secondary"]))
    K.Tooltip(self.frame, p.name or "", p.tip or "")
    K.PlaceActions(self)
    K.RevealActions(self)
    self.frame:Show()
end
local DRow = {}
DRow.__index = DRow
K.DisenchantRow = DRow
function DRow:New(parent, select, buy, refresh)
    local row = setmetatable({}, self)
    row.frame = K.ItemChoice(parent, function() select(row.props.id) end)
    row.frame:SetHeight(24)
    row.frame.selected:SetDrawLayer("BORDER")
    parent.disenchantRowCount = (rawget(parent, "disenchantRowCount") or 0) + 1
    row.stripe = row.frame:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints(row.frame); row.stripe:SetTexture(K.theme.white)
    row.stripe:SetVertexColor(unpack(K.theme.row))
    if parent.disenchantRowCount % 2 == 0 then row.stripe:Hide() end
    row.match = row.frame:CreateTexture(nil, "BACKGROUND")
    row.match:SetAllPoints(row.frame); row.match:SetTexture(K.theme.white)
    row.match:SetVertexColor(unpack(K.theme.match)); row.match:Hide()
    row.matchBar = row.frame:CreateTexture(nil, "BORDER")
    row.matchBar:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 0, 0)
    row.matchBar:SetPoint("BOTTOMLEFT", row.frame, "BOTTOMLEFT", 0, 0)
    row.matchBar:SetWidth(4); row.matchBar:SetTexture(K.theme.white)
    row.matchBar:SetVertexColor(unpack(K.theme.positive)); row.matchBar:Hide()
    row.frame.icon:ClearAllPoints(); row.frame.icon:SetPoint("LEFT", row.frame, "LEFT", 8, 0)
    row.frame.icon:SetWidth(18); row.frame.icon:SetHeight(18)
    row.frame.text:ClearAllPoints(); row.frame.text:SetPoint("LEFT", row.frame, "LEFT", 32, 0)
    row.frame.text:SetHeight(12)
    row.cells = {}
    for _, key in ipairs({"ilvl", "price", "margin", "rate", "via", "viaRate"}) do
        local cell = K.Label(row.frame, "", 0, -6, 80, (key == "ilvl" or key == "rate") and "secondary" or nil)
        cell:SetHeight(12); cell:SetJustifyH("RIGHT")
        row.cells[key] = cell
    end
    row.tag = K.Label(row.frame, "", 0, -6, K.ITEM_TAG)
    row.tag:SetHeight(12); row.tag:SetJustifyH("RIGHT"); row.tag:Hide()
    row.buy = K.IconButton(row.frame, "buy", function() buy(row.props.id) end, ns.T("deBuyRow"), ns.T("deBuyRowTip"))
    row.buy:SetPoint("RIGHT", row.frame, "RIGHT", -4, 0)
    if refresh then
        row.refresh = K.IconButton(row.frame, "refresh", function() refresh(row.props.id) end,
            ns.T("tradeUpdate"), ns.T("deRefreshRowTip"))
        row.refresh:SetPoint("RIGHT", row.buy, "LEFT", -3, 0)
    end
    return row
end
function DRow:Reveal()
    if self.props.action ~= false then self.buy:Show() else self.buy:Hide() end
    if self.refresh then self.refresh:Show() end
end
function DRow:SetProps(props)
    self.props = props; self:Render()
end
function DRow:Render()
    local p = self.props
    local columns = K.DisenchantColumns(p.width, p.target, self.refresh ~= nil)
    self.frame:SetWidth(p.width)
    K.SetItemChoice(self.frame, p.id, p.active, p.quality)
    self.frame.extraTip = p.tip
    K.ItemTag(self.frame, self.tag, columns.item, p.tag)
    for key, cell in pairs(self.cells) do
        local column = columns[key]
        cell:ClearAllPoints()
        if column then
            cell:SetPoint("LEFT", self.frame, "LEFT", column[1], 0)
            cell:SetWidth(column[2] - 6); cell:Show()
        else cell:Hide() end
    end
    self.cells.ilvl:SetText(p.level and tostring(p.level) or "")
    self.cells.price:SetText(K.Money(p.cost))
    self.cells.margin:SetText(K.Money(p.margin))
    self.cells.margin:SetTextColor(unpack(K.theme[p.margin and (p.margin > 0 and "positive" or "negative") or "text"]))
    self.cells.rate:SetText(p.percent and ns.T("deMarginRate", p.percent) or "")
    self.cells.via:SetText(p.via and K.Money(p.via) or "")
    self.cells.viaRate:SetText(p.viaRate and ns.T("deViaShort", p.viaRate) or "")
    self.cells.viaRate:SetTextColor(unpack(K.theme[p.viaRate and (p.viaRate < 0 and "positive" or "negative") or "secondary"]))
    if p.match then self.match:Show(); self.matchBar:Show() else self.match:Hide(); self.matchBar:Hide() end
    if p.actionDisabled then self.buy:Disable() else self.buy:Enable() end
    if self.refresh then
        if p.refreshDisabled then self.refresh:Disable() else self.refresh:Enable() end
    end
    self:Reveal()
end
function K.CraftColumns(width)
    local action = 80
    local price, margin, units = 86, 92, 48
    local state = width >= 820 and 72 or 0
    local best = width >= 960 and 180 or 0
    local item = width - action - price - margin - units - state - best
    local columns, x = {item = {0, item}}, item
    columns.price = {x, price}; x = x + price
    if best > 0 then columns.best = {x, best}; x = x + best end
    columns.margin = {x, margin}; x = x + margin
    columns.units = {x, units}; x = x + units
    if state > 0 then columns.state = {x, state}; x = x + state end
    columns.action = {x, action}
    return columns
end
function K.ActionWidth(action, default)
    return action.icon and 22 or action.width or default
end
function K.PlaceActions(row)
    local actions = row.props and row.props.actions or {}
    local right
    for i = #actions, 1, -1 do
        local button = row.buttons[i]
        if button then
            button:SetWidth(K.ActionWidth(actions[i], 60))
            button:ClearAllPoints()
            if right then button:SetPoint("RIGHT", right, "LEFT", -3, 0)
            else button:SetPoint("RIGHT", row.frame, "RIGHT", -4, 0) end
            right = button
        end
    end
end
function K.RevealActions(row)
    local p = row.props
    for i, button in ipairs(row.buttons) do
        local action = p and p.actions and p.actions[i]
        if action then
            if not K.SetGlyph(button, action.icon) then button:SetText(action.label) end
            if action.disabled then button:Disable() else button:Enable() end
            if action.tip then K.Tooltip(button, action.label, action.tip) end
            button:Show()
        else button:Hide() end
    end
end
local CraftRow = {}
CraftRow.__index = CraftRow
K.CraftRow = CraftRow
function CraftRow:New(parent, select, expand)
    local row = setmetatable({buttons = {}}, self)
    row.frame = K.ItemChoice(parent, function() select(row.props.id, row.props) end)
    row.frame:SetHeight(30)
    row.frame.selected:SetDrawLayer("BORDER")
    parent.craftRowCount = (rawget(parent, "craftRowCount") or 0) + 1
    row.stripe = row.frame:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints(row.frame); row.stripe:SetTexture(K.theme.white)
    row.stripe:SetVertexColor(unpack(K.theme.row))
    if parent.craftRowCount % 2 == 0 then row.stripe:Hide() end
    row.expand = K.Button(row.frame, "+", 18, function() expand(row.props.id, row.props) end, "quiet")
    row.expand:SetHeight(18)
    row.expand.text:ClearAllPoints(); row.expand.text:SetPoint("CENTER", row.expand, "CENTER", 0, 0)
    row.frame.icon:SetWidth(22); row.frame.icon:SetHeight(22)
    row.frame.text:SetHeight(12)
    row.cross = K.Label(row.frame, "x", 0, 0, 10)
    row.cross:SetHeight(12); row.cross:SetTextColor(unpack(K.theme.negative)); row.cross:Hide()
    row.detail = K.Label(row.frame, "", 0, -16, 200, "secondary"); row.detail:SetHeight(12)
    row.cells = {}
    for _, key in ipairs({"price", "best", "margin", "units", "state"}) do
        local cell = K.Label(row.frame, "", 0, -3, 80); cell:SetHeight(12); cell:SetJustifyH("RIGHT")
        row.cells[key] = cell
    end
    row.bestNote = K.Label(row.frame, "", 0, -16, 80, "secondary"); row.bestNote:SetHeight(12); row.bestNote:SetJustifyH("RIGHT")
    row.marginRate = K.Label(row.frame, "", 0, -16, 80, "secondary"); row.marginRate:SetHeight(12); row.marginRate:SetJustifyH("RIGHT")
    row.arrow = row.frame:CreateTexture(nil, "ARTWORK")
    row.arrow:SetTexture("Interface\\Buttons\\UI-SortArrow"); row.arrow:SetWidth(9); row.arrow:SetHeight(9)
    row.change = K.Label(row.frame, "", 0, -16, 70, "secondary"); row.change:SetHeight(12); row.change:SetJustifyH("RIGHT")
    for i = 1, 3 do
        local button = K.Button(row.frame, "", 60, function()
            local action = row.props.actions and row.props.actions[i]
            if action then action.fn(row.props.id, row.props) end
        end, "quiet")
        button:SetHeight(20)
        button:Hide()
        row.buttons[i] = button
    end
    row.buttons[3]:SetPoint("RIGHT", row.frame, "RIGHT", -4, 0)
    row.buttons[2]:SetPoint("RIGHT", row.buttons[3], "LEFT", -3, 0)
    row.buttons[1]:SetPoint("RIGHT", row.buttons[2], "LEFT", -3, 0)
    return row
end
function CraftRow:SetProps(props)
    self.props = props; self:Render()
end
function CraftRow:Render()
    local p = self.props
    local columns = K.CraftColumns(p.width)
    local offset = 26 + (p.depth or 0) * 14
    self.frame:SetWidth(p.width)
    K.SetItemChoice(self.frame, p.id, p.active, p.quality)
    self.frame.extraTip = p.tip
    self.frame.icon:ClearAllPoints(); self.frame.icon:SetPoint("LEFT", self.frame, "LEFT", offset, 0)
    self.frame.text:ClearAllPoints(); self.frame.text:SetPoint("TOPLEFT", self.frame, "TOPLEFT", offset + 26, -3)
    self.frame.text:SetWidth(math.max(40, columns.item[2] - offset - 30))
    if p.unlearned then
        self.frame.text:SetTextColor(unpack(K.theme.off))
        self.cross:ClearAllPoints(); self.cross:SetPoint("LEFT", self.frame, "LEFT", offset - 12, 0); self.cross:Show()
    else self.cross:Hide() end
    self.detail:ClearAllPoints(); self.detail:SetPoint("TOPLEFT", self.frame, "TOPLEFT", offset + 26, -16)
    self.detail:SetWidth(math.max(40, columns.item[2] - offset - 30))
    self.detail:SetText(p.detail or "")
    self.expand:ClearAllPoints(); self.expand:SetPoint("LEFT", self.frame, "LEFT", offset - 22, 0)
    self.expand:SetText(p.opened and "-" or "+")
    if p.expandable then self.expand:Show() else self.expand:Hide() end
    for key, cell in pairs(self.cells) do
        local column = columns[key]
        cell:ClearAllPoints()
        if column then
            cell:SetPoint("TOPLEFT", self.frame, "TOPLEFT", column[1], (key == "units" or key == "state") and -9 or -3)
            cell:SetWidth(column[2] - 6); cell:Show()
        else cell:Hide() end
    end
    self.cells.price:SetText(K.Money(p.price))
    self.change:ClearAllPoints(); self.change:SetPoint("TOPLEFT", self.frame, "TOPLEFT", columns.price[1], -16)
    self.change:SetWidth(columns.price[2] - 6)
    if p.change then
        local up = p.change >= 0
        self.change:SetText(ns.T("craftChange", math.abs(p.change)))
        self.change:SetTextColor(unpack(K.theme[up and "positive" or "negative"]))
        self.arrow:ClearAllPoints(); self.arrow:SetPoint("RIGHT", self.change, "LEFT", -1, 0)
        if up then self.arrow:SetTexCoord(0, 0.5625, 1, 0) else self.arrow:SetTexCoord(0, 0.5625, 0, 1) end
        self.arrow:SetVertexColor(unpack(K.theme[up and "positive" or "negative"]))
        self.arrow:Show(); self.change:Show()
    else self.arrow:Hide(); self.change:Hide() end
    if columns.best then
        self.cells.best:SetText(p.best and ns.Markets.Name(p.best) or "")
        self.cells.best:SetJustifyH("LEFT")
        self.bestNote:ClearAllPoints(); self.bestNote:SetPoint("TOPLEFT", self.frame, "TOPLEFT", columns.best[1], -16)
        self.bestNote:SetWidth(columns.best[2] - 6); self.bestNote:SetJustifyH("LEFT")
        self.bestNote:SetText(p.best and K.Money(p.bestPrice) or ""); self.bestNote:Show()
    else self.bestNote:Hide() end
    self.cells.margin:SetText(K.Money(p.margin))
    self.cells.margin:SetTextColor(unpack(K.theme[p.margin and (p.margin > 0 and "positive" or "negative") or "text"]))
    self.marginRate:ClearAllPoints(); self.marginRate:SetPoint("TOPLEFT", self.frame, "TOPLEFT", columns.margin[1], -16)
    self.marginRate:SetWidth(columns.margin[2] - 6)
    self.marginRate:SetText(p.percent and ns.T("deMarginRate", p.percent) or "")
    self.cells.units:SetText(p.units and tostring(p.units) or ns.T("tradeNoPrice"))
    self.cells.state:SetText(p.state or "")
    self.cells.state:SetTextColor(unpack(K.theme[p.stateTone or "secondary"]))
    K.PlaceActions(self)
    K.RevealActions(self)
    self.frame:Show()
end
local Batch = {}
Batch.__index = Batch
K.BatchPanel = Batch
local batchSerial = 0
function Batch:Wheel(delta)
    if ScrollFrameTemplate_OnMouseWheel then ScrollFrameTemplate_OnMouseWheel(self.frame, delta) end
end
function Batch:Scrollable(frame)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta) self:Wheel(delta) end)
end
function Batch:New(parent)
    batchSerial = batchSerial + 1
    local panel = setmetatable({rows = {}, queue = 1}, self)
    panel.frame = ns.NewFrame("ScrollFrame", "ManaCodeBatchScroll" .. batchSerial, parent, "UIPanelScrollFrameTemplate")
    panel.frame.scrollBarHideable = 1
    panel.child = ns.NewFrame("Frame", nil, panel.frame)
    panel.child:SetWidth(220); panel.child:SetHeight(400)
    panel.frame:SetScrollChild(panel.child)
    panel:Scrollable(panel.child)
    local c = panel.child
    panel.title = K.Label(c, ns.T("batchTitle"), 0, 0, 200, "heading"); panel.title:SetHeight(14)
    panel.info = K.Button(c, ns.T("tradeInfo"), 22, function() end, "quiet")
    panel.info:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0, 0)
    K.Tooltip(panel.info, ns.T("batchTitle"), ns.T("batchTip"))
    panel.scan = K.Button(c, ns.T("batchScan"), 60, function()
        if panel.props and panel.props.scan then panel.props.scan.run() end
    end, "quiet")
    panel.scan:SetHeight(20); panel.scan:SetPoint("RIGHT", panel.info, "LEFT", -4, 0)
    K.Tooltip(panel.scan, ns.T("scanSelection"), ns.T("scanRecipeSelectionTip"))
    panel.scan:Hide()
    panel.status = K.Label(c, "", 0, -18, 220, "secondary"); panel.status:SetHeight(12); panel.status:SetJustifyV("TOP")
    panel.sourceChip = K.Chip(c, ns.T("batchMakeChip"), function(checked) panel:Emit("craftAll", checked) end)
    K.Tooltip(panel.sourceChip, ns.T("craftMaterialSource"), ns.T("craftTreeTip"))
    panel.ownedChip = K.Chip(c, ns.T("batchOwnedChip"), function(checked) panel:Emit("owned", checked) end)
    K.Tooltip(panel.ownedChip, ns.T("craftOwnedTitle"), ns.T("craftOwnedTip"))
    panel.quantityLabel = K.Label(c, ns.T("batchQuantity"), 0, 0, 80, "secondary"); panel.quantityLabel:SetHeight(12)
    panel.quantity = K.Edit(c, 56)
    panel.quantity:SetNumeric(true); panel.quantity:SetMaxLetters(6)
    K.Tooltip(panel.quantity, ns.T("craftQuantity"), ns.T("craftQuantityTip"))
    K.LiveEdit(panel.quantity, function(edit)
        local value = tonumber(edit:GetText())
        if value and value >= 1 and value <= 100000 then panel:Emit("quantity", value)
        else edit:SetText(tostring(panel.plan and panel.plan.requested or 1)) end
    end)
    panel.crafts = K.Label(c, "", 0, 0, 90, "secondary"); panel.crafts:SetHeight(12)
    local steps = {}
    for i, n in ipairs({1, 10, 20, 100}) do steps[i] = {key = n, label = ns.T("batchStep", n)} end
    panel.steps = K.Segment(c, steps, function(n)
        local edit = panel.quantity
        edit.liveAt = nil; edit:SetScript("OnUpdate", nil)
        edit:ClearFocus(); edit:SetText(tostring(n))
        panel:Emit("quantity", n)
    end)
    panel.reagentsTitle = K.Label(c, ns.T("batchReagents"), 0, 0, 200, "heading"); panel.reagentsTitle:SetHeight(14)
    for i = 1, 16 do
        local row = {buttons = {}}
        row.frame = K.ItemChoice(c, function() panel:Select(row.node and row.node.id) end)
        row.frame:SetHeight(30)
        row.frame.selected:SetDrawLayer("BORDER")
        row.frame.icon:SetWidth(22); row.frame.icon:SetHeight(22)
        row.frame.text:SetHeight(12)
        row.detail = K.Label(row.frame, "", 0, -16, 150, "secondary"); row.detail:SetHeight(12)
        row.price = K.Label(row.frame, "", 0, -3, 80); row.price:SetHeight(12); row.price:SetJustifyH("RIGHT")
        row.price:ClearAllPoints(); row.price:SetPoint("TOPRIGHT", row.frame, "TOPRIGHT", -4, -3)
        row.sum = K.Label(row.frame, "", 0, -16, 80, "secondary"); row.sum:SetHeight(12); row.sum:SetJustifyH("RIGHT")
        row.sum:ClearAllPoints(); row.sum:SetPoint("TOPRIGHT", row.frame, "TOPRIGHT", -4, -16)
        row.expand = K.Button(row.frame, "+", 18, function()
            if row.node then panel:Emit("make", not row.node.crafted, row.node.id) end
        end, "quiet")
        row.expand:SetHeight(18)
        row.expand.text:ClearAllPoints(); row.expand.text:SetPoint("CENTER", row.expand, "CENTER", 0, 0)
        K.Tooltip(row.expand, ns.T("craftMaterialSource"), ns.T("craftTreeTip"))
        row.buttons[1] = K.IconButton(row.frame, "buy", function()
            if row.node and panel.props.buy then panel.props.buy(row.node.id, row.node.need) end
        end, ns.T("tradeBuy"), ns.T("batchBuyRowTip"))
        row.buttons[1]:SetPoint("RIGHT", row.frame, "RIGHT", -88, 0)
        row.buttons[1]:Hide()
        panel:Scrollable(row.frame)
        row.frame:Hide()
        panel.rows[i] = row
    end
    panel:NewTools(c)
    panel.totalKeys, panel.totalValues = {}, {}
    for i = 1, 5 do
        local key = K.Label(c, "", 0, 0, 120, "secondary"); key:SetHeight(12)
        local value = K.Label(c, "", 0, 0, 100); value:SetHeight(12); value:SetJustifyH("RIGHT")
        panel.totalKeys[i], panel.totalValues[i] = key, value
    end
    panel.supply = K.Label(c, "", 0, 0, 220); panel.supply:SetHeight(12)
    panel.buy = K.Button(c, "", 220, function() panel:BuyNext() end, "main")
    K.Tooltip(panel.buy, ns.T("batchBuyMissing"), ns.T("batchBuyTip"))
    panel.queueNote = K.Label(c, "", 0, 0, 220, "secondary"); panel.queueNote:SetHeight(24); panel.queueNote:SetJustifyV("TOP")
    panel.frame:Hide()
    return panel
end
function Batch:NewTools(c)
    local tools = ns.NewFrame("Frame", nil, c)
    tools:SetHeight(90); tools:Hide()
    self.tools = tools
    tools.label = K.Label(tools, ns.T("alchemyPriceLabel"), 0, 0, 220, "secondary"); tools.label:SetHeight(12)
    tools.edit = K.Edit(tools, 52)
    tools.edit:SetPoint("TOPLEFT", tools, "TOPLEFT", 0, -14)
    K.Tooltip(tools.edit, ns.T("alchemyPriceLabel"), ns.T("alchemyPriceHint"))
    tools.edit:SetScript("OnEnterPressed", function() self:SavePrice() end)
    tools.save = K.Button(tools, ns.T("alchemySavePrice"), 66, function() self:SavePrice() end)
    tools.save:SetHeight(22); tools.save:SetPoint("LEFT", tools.edit, "RIGHT", 4, 0)
    tools.reset = K.Button(tools, ns.T("batchPriceReset"), 66, function()
        if self.selected then ns.Alchemy.SetPrice(self.selected, nil); self.editID = nil; self:Emit("price") end
    end, "quiet")
    tools.reset:SetHeight(22); tools.reset:SetPoint("LEFT", tools.save, "RIGHT", 4, 0)
    K.Tooltip(tools.reset, ns.T("batchPriceReset"), ns.T("batchPriceResetTip"))
    tools.own = K.Chip(tools, ns.T("batchOwnChip"), function(checked)
        if self.selected then self:Emit("ignore", checked, self.selected) end
    end)
    tools.own:SetHeight(22)
    K.Tooltip(tools.own, ns.T("batchOwnChip"), ns.T("craftIncludeTip"))
    tools.open = K.Button(tools, ns.T("reagentOpen"), 110, function()
        if self.selected and self.props.reagent then self.props.reagent.open(self.selected) end
    end, "quiet")
    tools.open:SetHeight(22); tools.open:SetPoint("TOPLEFT", tools, "TOPLEFT", 0, -66)
    self:Scrollable(tools)
end
function Batch:SavePrice()
    local edit, id = self.tools.edit, self.selected
    local price = tonumber((edit:GetText():gsub(",", ".")))
    if not id or not price or not ns.Alchemy.SetPrice(id, price * 10000) then
        ns.say(ns.T("alchemyInvalidPrice")); return
    end
    edit:ClearFocus()
    self.editID = nil
    self:Emit("price")
end
function Batch:Select(id)
    self.selected = id
    if self.props and self.props.select then self.props.select(id) else self:Render() end
end
function Batch:PlaceTools(node, y, width)
    local tools = self.tools
    tools:SetWidth(width)
    self:Place(tools, 22, y)
    local vendor = ns.vendorPrices[node.id]
    local quote = ns.Alchemy.Quote(node.id)
    if vendor then
        tools.label:SetText(ns.T("vendorResaleCost", K.Money(vendor)))
        tools.edit:Hide(); tools.save:Hide(); tools.reset:Hide()
    else
        tools.label:SetText(ns.T("alchemyPriceLabel"))
        tools.edit:Show(); tools.save:Show()
        if quote and quote.manual then tools.reset:Show() else tools.reset:Hide() end
        if self.editID ~= node.id and not tools.edit:HasFocus() then
            tools.edit:SetText(quote and quote.manual and string.format("%.4f", quote.price / 10000) or "")
            self.editID = node.id
        end
    end
    tools.own:ClearAllPoints()
    tools.own:SetPoint("TOPLEFT", tools, "TOPLEFT", 0, vendor and -16 or -40)
    tools.own:SetChecked(node.excluded and true or false)
    if ns.Crafting.IsInput(node.id) and not vendor then tools.open:Show() else tools.open:Hide() end
    return vendor and 42 or 92
end
function Batch:Emit(key, value, id)
    if self.props and self.props.change then self.props.change(key, value, id) end
end
function Batch:SetProps(props)
    if not self.props or not props.recipe or not self.props.recipe or self.props.recipe.raw ~= props.recipe.raw then
        self.queue, self.selected, self.editID = 1, nil, nil
    end
    if props.selected ~= nil then self.selected = props.selected or nil end
    self.props = props; self:Render()
end
function Batch:Missing()
    local missing, seen = {}, {}
    for _, node in ipairs(self.plan and self.plan.rows or {}) do
        if not node.excluded and not node.crafted and node.need > 0 and not ns.vendorPrices[node.id] then
            if not seen[node.id] then
                seen[node.id] = {id = node.id, need = 0}
                missing[#missing + 1] = seen[node.id]
            end
            seen[node.id].need = seen[node.id].need + node.need
        end
    end
    return missing
end
function Batch:BuyNext()
    local missing = self:Missing()
    if #missing == 0 or not self.props.buy then return end
    local index = math.max(1, math.min(self.queue, #missing))
    local item = missing[index]
    self.queue = index % #missing + 1
    self.props.buy(item.id, item.need)
    self:Render()
end
function Batch:Place(frame, x, y)
    frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", self.child, "TOPLEFT", x or 0, -y); frame:Show()
end
function Batch:Render()
    local p = self.props
    if not p or not p.recipe then self.frame:Hide(); return end
    self.frame:Show()
    local o = p.options
    local plan = ns.CraftPlan.Build(p.recipe, {make = o.make, ignore = o.ignore, craftAll = o.craftAll, owned = o.owned,
        fee = ns.Fee(), quantity = o.quantity})
    self.plan = plan
    local width = math.max(160, (self.frame:GetWidth() or 240) - 22)
    self.child:SetWidth(width)
    self.status:SetWidth(width)
    local status = ns.T("batchOutput", p.recipe.count)
    if p.known == true then status = status .. " | " .. ns.T("craftRecipeKnown")
    elseif p.known == false then status = status .. " | " .. ns.T("craftRecipeUnknown") end
    if plan.extra > 0 then status = status .. ns.T("craftExtra", plan.extra) end
    status = status .. (p.note or "")
    self.status:SetText(status)
    local wide = (self.status.GetStringWidth and self.status:GetStringWidth() or 0) > width
    self.status:SetHeight(wide and 26 or 12)
    if p.scan then
        self.scan.tipFn = p.scan.tip
        self.scan:Show()
    else self.scan:Hide() end
    local y = wide and 48 or 34
    self.sourceChip:SetChecked(o.craftAll and true or false)
    self.ownedChip:SetChecked(o.owned and true or false)
    self:Place(self.sourceChip, 0, y)
    if p.ownedChip == false then self.ownedChip:Hide()
    else self:Place(self.ownedChip, (self.sourceChip:GetWidth() or 120) + 6, y) end
    y = y + 28
    self:Place(self.quantityLabel, 0, y + 5)
    self:Place(self.quantity, 84, y)
    if not self.quantity:HasFocus() then self.quantity:SetText(tostring(plan.requested)) end
    self.crafts:SetText(ns.T("batchCrafts", plan.crafts))
    self:Place(self.crafts, 146, y + 5)
    y = y + 26
    self.steps:Select(plan.requested)
    self:Place(self.steps.frame, 0, y)
    y = y + 28
    self:Place(self.reagentsTitle, 0, y)
    y = y + 18
    local toolsAt
    self.tools:Hide()
    for i, row in ipairs(self.rows) do
        local node = plan.rows[i]
        row.node = node
        if node then
            self:Place(row.frame, 0, y)
            row.frame:SetWidth(width)
            local offset = 22 + node.depth * 12
            local buyable = not node.excluded and not node.crafted and node.need > 0 and not ns.vendorPrices[node.id]
            local textWidth = math.max(40, width - offset - 112 - (buyable and 26 or 0))
            K.SetItemChoice(row.frame, node.id, node.id == self.selected)
            row.frame.icon:ClearAllPoints(); row.frame.icon:SetPoint("LEFT", row.frame, "LEFT", offset, 0)
            row.frame.text:ClearAllPoints(); row.frame.text:SetPoint("TOPLEFT", row.frame, "TOPLEFT", offset + 26, -3)
            row.frame.text:SetWidth(textWidth)
            row.detail:ClearAllPoints(); row.detail:SetPoint("TOPLEFT", row.frame, "TOPLEFT", offset + 26, -16)
            row.detail:SetWidth(textWidth)
            row.expand:ClearAllPoints(); row.expand:SetPoint("LEFT", row.frame, "LEFT", offset - 20, 0)
            row.expand:SetText(node.crafted and "-" or "+")
            if node.expandable and not node.excluded then row.expand:Show() else row.expand:Hide() end
            local quote = node.quote
            local price = quote and quote.miss == 0 and quote.complete ~= false and quote.price or nil
            local stale = price and not quote.vendor and not quote.manual and not ns.Markets.Fresh(node.id)
            local detail, tone
            if node.excluded then detail, tone = ns.T("batchExcluded"), "secondary"
            elseif node.crafted then detail, tone = ns.T("batchNeedMake", node.count, node.crafts or 0), "text"
            else
                detail = ns.T("batchNeed", node.count, node.own, node.need)
                if node.need == 0 then detail, tone = detail .. " | " .. ns.T("batchEnough"), "positive"
                elseif not price then detail, tone = detail .. " | " .. ns.T("batchNoPrice"), "negative"
                elseif (quote.units or 0) == 0 and not quote.vendor and not quote.manual then
                    detail, tone = detail .. " | " .. ns.T("batchNotOnAuction"), "negative"
                elseif stale then detail, tone = detail .. " | " .. ns.T("batchStale"), "secondary"
                else tone = "text" end
            end
            row.detail:SetText(detail)
            row.detail:SetTextColor(unpack(K.theme[tone]))
            row.price:SetText(node.crafted and "" or K.Money(price))
            row.price:SetTextColor(unpack(K.theme[(not node.crafted and not node.excluded and not price) and "negative" or "text"]))
            row.sum:SetText(K.Money(node.crafted and node.value or node.cash))
            row.props = {active = node.id == self.selected,
                actions = buyable and {{label = ns.T("tradeBuy"), icon = "buy", tip = ns.T("batchBuyRowTip")}} or nil}
            K.RevealActions(row)
            y = y + 30
            if p.reagent and not toolsAt and node.id == self.selected then
                toolsAt = node
                y = y + self:PlaceTools(node, y, width - 22)
            end
        else row.frame:Hide() end
    end
    y = y + 6
    local fee = math.floor(ns.Fee() * 100 + 0.5)
    local totals = {{ns.T("batchCost"), K.Money(plan.cost), "text"},
        {ns.T("batchUnitCost"), K.Money(plan.unitCost and math.floor(plan.unitCost + 0.5)), "text"},
        {ns.T("batchCash"), K.Money(plan.cash), "text"},
        {ns.T("batchRevenue", fee), K.Money(plan.revenue), "text"},
        {ns.T("batchMargin"), K.Money(plan.margin), plan.margin and (plan.margin > 0 and "positive" or "negative") or "text"}}
    for i, total in ipairs(totals) do
        self:Place(self.totalKeys[i], 0, y)
        self.totalValues[i]:ClearAllPoints()
        self.totalValues[i]:SetPoint("TOPRIGHT", self.child, "TOPRIGHT", 0, -y); self.totalValues[i]:Show()
        self.totalKeys[i]:SetText(total[1]); self.totalValues[i]:SetText(total[2])
        self.totalValues[i]:SetTextColor(unpack(K.theme[total[3]]))
        y = y + 13
    end
    if plan.cost then
        self.supply:SetText(plan.short > 0 and ns.T("batchSupplyShort", plan.short) or ns.T("batchSupplyOk"))
        self.supply:SetTextColor(unpack(K.theme[plan.short > 0 and "negative" or "positive"]))
    else
        self.supply:SetText(ns.T("craftBatchMissing", plan.missing))
        self.supply:SetTextColor(unpack(K.theme.negative))
    end
    self:Place(self.supply, 0, y + 2)
    y = y + 20
    local missing = self:Missing()
    self.buy:SetWidth(width)
    self:Place(self.buy, 0, y)
    if #missing == 0 then
        self.buy:SetText(ns.T("batchNothingToBuy")); self.buy:Disable(); self.queueNote:SetText("")
    else
        local index = math.max(1, math.min(self.queue, #missing))
        self.buy.tipFn = function()
            return ns.T("batchBuyTip") .. "\n\n" .. ns.Markets.Name(missing[index].id) .. " x" .. missing[index].need
        end
        self.buy:SetText(#missing == 1 and ns.T("batchBuyMissing")
            or ns.T("batchBuyNext", index, #missing))
        self.buy:Enable()
        local current = missing[index]
        local note = ns.T("batchQueueNow", ns.Markets.Name(current.id) .. " x" .. current.need)
        local rest = {}
        for i = 1, math.min(#missing - 1, 3) do
            local following = missing[(index + i - 1) % #missing + 1]
            rest[#rest + 1] = ns.Markets.Name(following.id) .. " x" .. following.need
        end
        if #rest > 0 then note = note .. "\n" .. ns.T("batchQueue", table.concat(rest, ", ")) end
        self.queueNote:SetText(note)
    end
    y = y + 30
    self.queueNote:SetWidth(width)
    self:Place(self.queueNote, 0, y)
    y = y + 26
    self.child:SetHeight(y)
end
function K.LedgerColumns(width, mode, actions)
    local spec, drop, flex
    if mode == "materials" then
        spec = {{"item", 0}, {"stock", 64}, {"posted", 76}, {"unit", 84}, {"market", 84}, {"value", 92}, {"sold", 64}, {"net", 92}}
        drop, flex = {"sold", "posted", "net"}, "item"
    elseif mode == "journal" then
        spec = {{"item", 0}, {"event", 150}, {"amount", 92}, {"source", 108}, {"when", 92}}
        drop, flex = {"source"}, "item"
    elseif mode == "analysis" then
        spec = {{"item", 0}, {"count", 50}, {"cost", 86}, {"units", 130}, {"expected", 92}, {"gross", 92},
            {"luck", 66}, {"result", 96}}
        drop, flex = {"expected", "units"}, "item"
    else
        spec = {{"item", math.max(170, math.min(250, math.floor(width * 0.24)))}, {"stage", 96}, {"cost", 80},
            {"output", 0}, {"market", 88}, {"net", 96}, {"result", 88}, {"when", 86}}
        drop, flex = {"when", "market"}, "output"
    end
    local action = actions and (mode == "journal" and 86 or 134) or 0
    local used, skip = action, {}
    for _, column in ipairs(spec) do used = used + column[2] end
    local minimum = flex == "item" and 200 or 130
    for _, key in ipairs(drop) do
        if width - used >= minimum then break end
        for _, column in ipairs(spec) do if column[1] == key then used, skip[key] = used - column[2], true end end
    end
    local rest = math.max(flex == "item" and 120 or 96, width - used)
    local columns, x = {}, 0
    for _, column in ipairs(spec) do
        if not skip[column[1]] then
            local size = column[1] == flex and rest or column[2]
            columns[column[1]] = {x, size}; x = x + size
        end
    end
    columns.action = {x, action}
    return columns
end
local LedgerRow = {}
LedgerRow.__index = LedgerRow
K.LedgerRow = LedgerRow
function LedgerRow:New(parent, select)
    local row = setmetatable({cells = {}, buttons = {}}, self)
    row.parent = parent
    row.frame = K.ItemChoice(parent, function() if row.props then select(row.props.key) end end)
    row.frame:SetHeight(24)
    row.frame.selected:SetDrawLayer("BORDER")
    parent.ledgerRowCount = (rawget(parent, "ledgerRowCount") or 0) + 1
    row.stripe = row.frame:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints(row.frame); row.stripe:SetTexture(K.theme.white)
    row.stripe:SetVertexColor(unpack(K.theme.row))
    if parent.ledgerRowCount % 2 == 0 then row.stripe:Hide() end
    row.frame.icon:ClearAllPoints(); row.frame.icon:SetPoint("LEFT", row.frame, "LEFT", 8, 0)
    row.frame.icon:SetWidth(18); row.frame.icon:SetHeight(18)
    row.frame.text:ClearAllPoints(); row.frame.text:SetPoint("LEFT", row.frame, "LEFT", 32, 0)
    row.frame.text:SetHeight(12)
    for i = 1, 2 do
        local button = K.Button(row.frame, "", 64, function()
            local action = row.props and row.props.actions and row.props.actions[i]
            if action then action.fn(row.props.key, row.props) end
        end, "quiet")
        button:SetHeight(20); button:Hide()
        row.buttons[i] = button
    end
    row.buttons[1]:SetPoint("RIGHT", row.frame, "RIGHT", -4, 0)
    row.buttons[2]:SetPoint("RIGHT", row.buttons[1], "LEFT", -3, 0)
    return row
end
function LedgerRow:Cell(key)
    local cell = self.cells[key]
    if not cell then
        cell = K.Label(self.frame, "", 0, -6, 80)
        cell:SetHeight(12); cell:SetJustifyH("RIGHT")
        self.cells[key] = cell
    end
    return cell
end
function LedgerRow:Icons(column, icons)
    self.icons = self.icons or {}
    for i = 1, 3 do
        local slot = self.icons[i]
        if not slot then
            slot = {texture = self.frame:CreateTexture(nil, "ARTWORK"), label = K.Label(self.frame, "", 0, -6, 40)}
            slot.texture:SetWidth(16); slot.texture:SetHeight(16)
            slot.label:SetHeight(12)
            self.icons[i] = slot
        end
        local entry = column and icons and icons[i]
        if entry then
            local x = column[1] + (i - 1) * 58
            slot.texture:SetTexture(select(10, ns.Compat.ItemInfo(entry.id)))
            slot.texture:ClearAllPoints(); slot.texture:SetPoint("LEFT", self.frame, "LEFT", x, 0)
            slot.label:ClearAllPoints(); slot.label:SetPoint("LEFT", self.frame, "LEFT", x + 19, 0)
            local more = i == 3 and #icons > 3 and (" +" .. (#icons - 3)) or ""
            slot.label:SetText("x" .. entry.count .. more)
            slot.texture:Show(); slot.label:Show()
        else slot.texture:Hide(); slot.label:Hide() end
    end
end
function LedgerRow:SetProps(props)
    self.props = props; self:Render()
end
function LedgerRow:Render()
    local p, frame = self.props, self.frame
    local columns = K.LedgerColumns(p.width, p.mode, p.hasActions)
    frame:SetWidth(p.width)
    self:Icons(columns.output, p.icons)
    if p.id then
        K.SetItemChoice(frame, p.id, p.active, p.quality)
        frame.itemLink = p.link and p.link:find("item:", 1, true) and p.link or nil
    else
        frame.itemID, frame.itemLink = nil, nil
        frame.icon:SetTexture(nil); frame.text:SetText(p.title or "")
        frame.text:SetTextColor(unpack(K.theme.text))
        if p.active then frame.selected:Show() else frame.selected:Hide() end
        frame:Show()
    end
    frame.extraTip = p.tip
    frame.text:SetWidth(math.max(40, columns.item[2] - 38))
    for key, cell in pairs(self.cells) do if not columns[key] or not p.cells[key] then cell:Hide() end end
    for key, value in pairs(p.cells) do
        local column = columns[key]
        if column then
            local cell = self:Cell(key)
            cell:ClearAllPoints(); cell:SetPoint("LEFT", frame, "LEFT", column[1], 0)
            cell:SetWidth(column[2] - 6)
            cell:SetText(value[1] or "")
            cell:SetTextColor(unpack(K.theme[value[2] or "text"]))
            cell:Show()
        end
    end
    for i, button in ipairs(self.buttons) do
        local action = p.actions and p.actions[i]
        if action then button:SetWidth(K.ActionWidth(action, 64)) end
    end
    K.RevealActions(self)
end
function K.DisabledTip(b, title, reason)
    b.disabledTipTitle, b.disabledTip = title, reason
    if rawget(b, "disabledTipHooked") then return end
    b.disabledTipHooked = true
    b:HookScript("OnEnter", function(self)
        if not self.btnDisabled or not self.disabledTip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.disabledTipTitle, unpack(K.theme.text))
        GameTooltip:AddLine(self.disabledTip, K.theme.gold[1], K.theme.gold[2], K.theme.gold[3], true)
        GameTooltip:Show()
    end)
    b:HookScript("OnLeave", function() GameTooltip:Hide() end)
end
function K.RecycleColumns(width)
    local action, bags, assemble, split, asIs = 30, 66, 96, 90, 90
    local item = width - action - bags - assemble - split - asIs
    if item < 230 then item, bags = item + bags, 0 end
    local columns, x = {item = {0, item}}, item
    for _, column in ipairs({{"asIs", asIs}, {"split", split}, {"assemble", assemble}, {"bags", bags}}) do
        if column[2] > 0 then columns[column[1]] = {x, column[2]}; x = x + column[2] end
    end
    columns.action = {x, action}
    return columns
end
local RecycleRow = {}
RecycleRow.__index = RecycleRow
K.RecycleRow = RecycleRow
function RecycleRow:New(parent, select)
    local row = setmetatable({buttons = {}}, self)
    row.frame = K.ItemChoice(parent, function() select(row.props.key) end)
    row.frame:SetHeight(24)
    row.frame.selected:SetDrawLayer("BORDER")
    parent.recycleRowCount = (rawget(parent, "recycleRowCount") or 0) + 1
    row.stripe = row.frame:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints(row.frame); row.stripe:SetTexture(K.theme.white)
    row.stripe:SetVertexColor(unpack(K.theme.row))
    if parent.recycleRowCount % 2 == 0 then row.stripe:Hide() end
    row.frame.icon:ClearAllPoints(); row.frame.icon:SetPoint("LEFT", row.frame, "LEFT", 8, 0)
    row.frame.icon:SetWidth(18); row.frame.icon:SetHeight(18)
    row.frame.text:ClearAllPoints(); row.frame.text:SetPoint("LEFT", row.frame, "LEFT", 32, 0)
    row.frame.text:SetHeight(12)
    row.cells = {}
    for _, key in ipairs({"asIs", "split", "assemble", "bags"}) do
        local cell = K.Label(row.frame, "", 0, -6, 80, key == "bags" and "secondary" or nil)
        cell:SetHeight(12); cell:SetJustifyH("RIGHT")
        row.cells[key] = cell
    end
    row.buttons[1] = K.Button(row.frame, ns.T("tradeUpdate"), 62, function()
        local action = row.props.actions and row.props.actions[1]
        if action then action.fn(row.props.key, row.props) end
    end, "quiet")
    row.buttons[1]:SetHeight(20)
    row.buttons[1]:SetPoint("RIGHT", row.frame, "RIGHT", -4, 0)
    row.buttons[1]:Hide()
    return row
end
function RecycleRow:SetProps(props)
    self.props = props; self:Render()
end
function RecycleRow:Render()
    local p, e = self.props, self.props.estimate
    local columns = K.RecycleColumns(p.width)
    self.frame:SetWidth(p.width)
    K.SetItemChoice(self.frame, p.id, p.active)
    self.frame.extraTip = p.tip
    self.frame.text:SetWidth(math.max(40, columns.item[2] - 38))
    for key, cell in pairs(self.cells) do
        local column = columns[key]
        cell:ClearAllPoints()
        if column then
            cell:SetPoint("LEFT", self.frame, "LEFT", column[1], 0)
            cell:SetWidth(column[2] - 6); cell:Show()
        else cell:Hide() end
    end
    self.cells.asIs:SetText(K.Money(e.asIs))
    self.cells.split:SetText(p.oneWay and ns.T("tradeNoPrice") or K.Money(e.split))
    self.cells.assemble:SetText(K.Money(e.assemble))
    self.cells.asIs:SetTextColor(unpack(K.theme[e.best == "asIs" and "positive" or "text"]))
    self.cells.split:SetTextColor(unpack(K.theme[e.best == "split" and "positive" or "text"]))
    self.cells.assemble:SetTextColor(unpack(K.theme[e.assemble and (e.assemble > 0 and "positive" or "negative") or "text"]))
    self.cells.bags:SetText((e.haveBig > 0 or e.haveSmall > 0) and ns.T("recycleBags", e.haveBig, e.haveSmall) or "")
    K.RevealActions(self)
    self.frame:Show()
end
function K.BagColumns(width)
    local spec = {{"count", 56}, {"cost", 86}, {"market", 86}, {"value", 96}, {"posted", 80}}
    local used, skip = 0, {}
    for _, column in ipairs(spec) do used = used + column[2] end
    for _, key in ipairs({"posted", "cost"}) do
        if width - used >= 200 then break end
        for _, column in ipairs(spec) do if column[1] == key then used, skip[key] = used - column[2], true end end
    end
    local rest = math.max(120, width - used)
    local columns, x = {item = {0, rest}}, rest
    for _, column in ipairs(spec) do
        if not skip[column[1]] then columns[column[1]] = {x, column[2]}; x = x + column[2] end
    end
    return columns
end
local BagRow = {}
BagRow.__index = BagRow
K.BagRow = BagRow
function BagRow:New(parent, select)
    local row = setmetatable({cells = {}}, self)
    row.frame = K.ItemChoice(parent, function() if row.props then select(row.props.id) end end)
    row.frame:SetHeight(24)
    row.frame.selected:SetDrawLayer("BORDER")
    parent.bagRowCount = (rawget(parent, "bagRowCount") or 0) + 1
    row.stripe = row.frame:CreateTexture(nil, "BACKGROUND")
    row.stripe:SetAllPoints(row.frame); row.stripe:SetTexture(K.theme.white)
    row.stripe:SetVertexColor(unpack(K.theme.row))
    if parent.bagRowCount % 2 == 0 then row.stripe:Hide() end
    row.frame.icon:ClearAllPoints(); row.frame.icon:SetPoint("LEFT", row.frame, "LEFT", 8, 0)
    row.frame.icon:SetWidth(18); row.frame.icon:SetHeight(18)
    row.frame.text:ClearAllPoints(); row.frame.text:SetPoint("LEFT", row.frame, "LEFT", 32, 0)
    row.frame.text:SetHeight(12)
    return row
end
function BagRow:Cell(key)
    local cell = self.cells[key]
    if not cell then
        cell = K.Label(self.frame, "", 0, -6, 80)
        cell:SetHeight(12); cell:SetJustifyH("RIGHT")
        self.cells[key] = cell
    end
    return cell
end
function BagRow:SetProps(props)
    self.props = props; self:Render()
end
function BagRow:Render()
    local p, frame = self.props, self.frame
    local columns = K.BagColumns(p.width)
    frame:SetWidth(p.width)
    K.SetItemChoice(frame, p.id, p.active)
    frame.extraTip = p.tip
    frame.text:SetWidth(math.max(40, columns.item[2] - 38))
    for key, cell in pairs(self.cells) do if not columns[key] or not p.cells[key] then cell:Hide() end end
    for key, value in pairs(p.cells) do
        local column = columns[key]
        if column then
            local cell = self:Cell(key)
            cell:ClearAllPoints(); cell:SetPoint("LEFT", frame, "LEFT", column[1], 0)
            cell:SetWidth(column[2] - 6)
            cell:SetText(value[1] or "")
            cell:SetTextColor(unpack(K.theme[value[2] or "text"]))
            cell:Show()
        end
    end
end
function K.ValueRow(parent, text, y, labelWidth, valueWidth)
    local label = K.Label(parent, text, 12, y, labelWidth or 118, "secondary")
    label:SetHeight(12)
    local value = K.Label(parent, "", 0, y, valueWidth or 124)
    value:SetHeight(12); value:SetJustifyH("RIGHT")
    value:ClearAllPoints(); value:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, y)
    return label, value
end
function K.PanelScrollBar(scroll, fits)
    local name = scroll:GetName()
    local bar = name and _G[name .. "ScrollBar"]
    if not bar then return end
    local up, down = _G[name .. "ScrollBarScrollUpButton"], _G[name .. "ScrollBarScrollDownButton"]
    scroll:UpdateScrollChildRect()
    if fits then scroll:SetVerticalScroll(0) end
    for _, part in ipairs({bar, up, down}) do
        if fits then part:Hide() else part:Show() end
    end
end
function K.BargainColumns(width, mode)
    local spec, drop
    if mode == "bid" then
        spec = {{"count", 40}, {"price", 90}, {"market", 90}, {"gain", 100}, {"left", 82}, {"buyout", 66}}
        drop = {"buyout", "left", "market"}
    elseif mode == "vendor" then
        spec = {{"count", 40}, {"price", 90}, {"vendor", 90}, {"gain", 100}, {"deal", 82}, {"age", 70}}
        drop = {"age", "deal", "count"}
    else
        spec = {{"count", 40}, {"price", 90}, {"market", 90}, {"discount", 62}, {"revenue", 100}, {"age", 70}}
        drop = {"age", "market", "count"}
    end
    local action = 82
    local used, skip = action, {}
    for _, column in ipairs(spec) do used = used + column[2] end
    for _, key in ipairs(drop) do
        if width - used >= 200 then break end
        for _, column in ipairs(spec) do if column[1] == key then used, skip[key] = used - column[2], true end end
    end
    local rest = math.max(120, width - used)
    local columns, x = {item = {0, rest}}, rest
    for _, column in ipairs(spec) do
        if not skip[column[1]] then columns[column[1]] = {x, column[2]}; x = x + column[2] end
    end
    columns.action = {x, action}
    return columns
end
local BargainRow = setmetatable({}, {__index = K.LedgerRow})
BargainRow.__index = BargainRow
K.BargainRow = BargainRow
K.ITEM_TAG = 86
function K.ItemTag(frame, label, item, text)
    local room = item[2] - 38
    if label and text then
        label:ClearAllPoints(); label:SetPoint("LEFT", frame, "LEFT", item[1] + item[2] - K.ITEM_TAG, 0)
        label:SetWidth(K.ITEM_TAG - 6); label:SetText(text)
        label:SetTextColor(unpack(K.theme.positive)); label:Show()
        room = room - K.ITEM_TAG
    elseif label then label:Hide() end
    frame.text:SetWidth(math.max(40, room))
end
function BargainRow:Render()
    local p, frame = self.props, self.frame
    local columns = K.BargainColumns(p.width, p.mode)
    frame:SetWidth(p.width)
    K.SetItemChoice(frame, p.id, p.active, p.quality)
    frame.extraTip = p.tip
    for key, cell in pairs(self.cells) do if not columns[key] or not p.cells[key] then cell:Hide() end end
    K.ItemTag(frame, p.tag and self:Cell("tag") or self.cells.tag, columns.item, p.tag)
    for key, value in pairs(p.cells) do
        local column = columns[key]
        if column then
            local cell = self:Cell(key)
            cell:ClearAllPoints(); cell:SetPoint("LEFT", frame, "LEFT", column[1], 0)
            cell:SetWidth(column[2] - 6)
            cell:SetText(value[1] or "")
            cell:SetTextColor(unpack(K.theme[value[2] or "text"]))
            cell:Show()
        end
    end
    for i, button in ipairs(self.buttons) do
        local action = p.actions and p.actions[i]
        if action then button:SetWidth(K.ActionWidth(action, 74)) end
    end
    K.RevealActions(self)
end
function K.Suggest(edit, fetch, choose, limit)
    limit = limit or 8
    local box = ns.NewFrame("Frame", nil, edit:GetParent())
    box:SetFrameStrata("DIALOG")
    box:SetPoint("TOPLEFT", edit, "BOTTOMLEFT", -4, -2)
    box:SetBackdrop(K.theme.buttonSkin)
    box:SetBackdropColor(unpack(K.theme.card))
    box:SetBackdropBorderColor(unpack(K.theme.edge))
    box:EnableMouse(true)
    box.entries, box.rows = {}, {}
    local function pick(index)
        local entry = box.entries[index]
        box:Hide()
        if entry then choose(entry) end
    end
    for i = 1, limit do
        local row = K.ItemChoice(box, function() pick(i) end)
        row:SetPoint("TOPLEFT", box, "TOPLEFT", 4, -4 - (i - 1) * 22)
        row:SetHeight(22)
        row.icon:SetWidth(18); row.icon:SetHeight(18)
        row:Hide()
        box.rows[i] = row
    end
    box.Render = function(self)
        local width = math.max(160, (edit:GetWidth() or 200) + 8)
        self:SetWidth(width)
        for i, row in ipairs(self.rows) do
            local entry = self.entries[i]
            if entry then
                K.SetItemChoice(row, entry.id, i == rawget(self, "index"), entry.quality)
                row.text:SetText(entry.name)
                row:SetWidth(width - 8); row.text:SetWidth(width - 40)
            else row:Hide() end
        end
        self:SetHeight(#self.entries * 22 + 8)
        if #self.entries > 0 and edit:HasFocus() then self:Show() else self:Hide() end
    end
    box.Update = function(self)
        self.entries, self.index = fetch(edit:GetText() or "") or {}, nil
        self:Render()
    end
    box.Move = function(self, delta)
        if #self.entries == 0 then return end
        self.index = ((rawget(self, "index") or (delta > 0 and 0 or 1)) + delta - 1) % #self.entries + 1
        self:Render()
    end
    box.Pick = function(self)
        local index = rawget(self, "index")
        if self:IsShown() and index then pick(index); return true end
        self:Hide()
        return false
    end
    edit:HookScript("OnTextChanged", function(_, user) if user then box:Update() end end)
    edit:HookScript("OnEditFocusLost", function()
        if not (MouseIsOver and MouseIsOver(box)) then box:Hide() end
    end)
    edit:HookScript("OnEscapePressed", function() box:Hide() end)
    edit:HookScript("OnTabPressed", function()
        if box:IsShown() then box:Move(IsShiftKeyDown() and -1 or 1) end
    end)
    box:Hide()
    return box
end
function K.Ago(seconds)
    if seconds < 3600 then return ns.T("buyAgoMin", math.max(1, math.floor(seconds / 60))) end
    if seconds < 172800 then return ns.T("buyAgoHour", math.floor(seconds / 3600)) end
    return ns.T("buyAgoDay", math.floor(seconds / 86400))
end
