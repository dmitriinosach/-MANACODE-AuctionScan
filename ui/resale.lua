local _, ns = ...
local UI = {props = {profession = "alchemy", page = 1, fee = 0.05}, rows = {}}
ns.ResaleUI = UI
function UI:SetProps(props)
    if props.profession and props.profession ~= self.props.profession then
        self.props.id = nil
        if self.scroll then self.scroll.offset = 0 end
    end
    for key, value in pairs(props) do self.props[key] = value end
    self:Render()
end
function UI:Controls()
    if not self.frame then return end
    local idle = ns.Scan.state.phase == "idle"
    local ready = idle and not ns.Buy.Active()
    if ready then self.scan:Enable() else self.scan:Disable() end
    if ready and self.props.id then self.update:Enable(); self.buy:Enable()
    else self.update:Disable(); self.buy:Disable() end
    if idle then self.update:Show() else self.update:Hide() end
end
function UI:Render()
    if not self.frame then return end
    local K, p = ns.TradeKit, self.props
    local fee = p.fee
    local items = self.sorter:Apply(ns.Resale.Items(p.profession), {
        item = function(entry) return ns.Markets.Name(entry.raw) end,
        price = function(entry) local q = ns.Markets.Quote(entry.raw); return q and q.price end,
        margin = function(entry) return ns.Resale.Estimate(entry, fee).margin end,
        units = function(entry) local q = ns.Markets.Quote(entry.raw); return q and q.units end,
    })
    if not p.id or not ns.Resale.byItem[p.id] or ns.Resale.byItem[p.id].profession ~= p.profession then
        p.id = items[1] and items[1].raw
    end
    local visible = K.ListCapacity(self.frame, 56, 56, 29, #self.rows)
    local offset = self.scroll:SetRange(#items, visible)
    local width = (self.frame:GetWidth() or 996) - 310
    local columns = K.MarketColumns(width)
    for key, label in pairs(self.headers) do
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + columns[key][1], -38)
        label:SetWidth(columns[key][2])
    end
    self.sorter:Mark()
    for i, row in ipairs(self.rows) do
        local entry = i <= visible and items[offset + i]
        if entry then
            local estimate = ns.Resale.Estimate(entry, p.fee)
            local quote = ns.Markets.Quote(entry.raw)
            local detail = ns.T("vendorResaleCost", K.Money(entry.buy))
            if quote then detail = detail .. ns.T("cacheAge", math.max(0, math.floor((time() - quote.at) / 60))) end
            row:SetProps({id = entry.raw, width = width, active = entry.raw == p.id,
                quote = quote, margin = estimate.margin, detail = detail})
        else row.frame:Hide() end
    end
    local selected = p.id and ns.Resale.byItem[p.id]
    self.empty:SetText(#items == 0 and ns.T("vendorResaleEmpty") or "")
    if selected then
        self.inspector:SetProps({id = p.id})
        local estimate = ns.Resale.Estimate(selected, p.fee)
        self.summary:SetText(ns.T("vendorResaleSummary", K.Money(estimate.cost),
            K.Money(estimate.revenue), K.Money(estimate.margin), K.Money(estimate.breakEven)))
        local vendor = ns.Resale.Vendor(selected)
        self.location:SetText(vendor and ns.T("vendorResaleWhere", ns.T("vendorNPC" .. vendor.npc),
            ns.T("vendorArea" .. vendor.npc), selected.skill) or ns.T("vendorResaleNoVendor"))
        self.stock:SetText(vendor and (vendor.stock > 0 and ns.T("vendorResaleLimited", vendor.stock)
            or ns.T("vendorResaleUnlimited")) or "")
    else
        self.selection:Hide(); self.summary:SetText(""); self.location:SetText(""); self.stock:SetText("")
    end
    self.fee:SetText(ns.T("tradeFee", math.floor(p.fee * 100 + 0.5)))
    self:Controls()
end
function UI:New(parent)
    local K = ns.TradeKit
    self.frame = ns.NewFrame("Frame", nil, parent)
    local f = self.frame
    f:SetAllPoints(parent)
    K.Label(f, ns.T("vendorResaleRecipes"), 12, -11, 236, "heading")
    self.scan = K.Button(f, ns.T("cacheComplete"), 140, function()
        ns.Resale.Complete(self.props.profession, ns.TradeKit.ScanMode()); self:Render()
    end, "main")
    self.scan:SetPoint("TOPRIGHT", f, "TOPRIGHT", -282, -5)
    K.Tooltip(self.scan, ns.T("cacheComplete"), ns.T("vendorResaleScanTip"))
    K.TableHeader(f, -38)
    self.headers = {}
    for _, entry in ipairs({{"item", "vendorResaleRecipes"}, {"price", "tradeUnitPrice"},
        {"margin", "familyMargin"}, {"units", "tradeUnits"}}) do
        local label = K.Label(f, ns.T(entry[2]), 0, -38, 100)
        if entry[1] ~= "item" then label:SetJustifyH("RIGHT") end
        self.headers[entry[1]] = label
    end
    self.sorter = K.Sorter(f, self.headers, function() self.scroll.offset = 0; self:Render() end)
    self.scroll = K.TableScroll(f, function() self:Render() end, 56, 56, 29)
    for i = 1, 40 do
        local row = K.MarketRow:New(f, function(id) self:SetProps({id = id}) end)
        row.frame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -56 - (i - 1) * 29)
        row.frame:SetHeight(28)
        self.rows[i] = row
        self.scroll:Wheel(row.frame)
    end
    self.empty = K.Label(f, "", 10, -66, 370)
    self.empty:SetHeight(60); self.empty:SetJustifyV("TOP")
    self.fee = K.Button(f, "", 106, function() self:SetProps({fee = self.props.fee == 0.05 and 0.15 or 0.05}) end)
    self.fee:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 4)
    self.buy = K.Button(f, ns.T("vendorResaleAuction"), 92, function() ns.Trader.OpenBuy(self.props.id) end)
    self.buy:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -282, 4)
    self.update = K.Button(f, ns.T("tradeUpdate"), 84, function() ns.Markets.Scan(self.props.id) end)
    self.update:SetPoint("RIGHT", self.buy, "LEFT", -6, 0)
    K.Tooltip(self.update, ns.T("cacheRefreshItem"), ns.T("cacheRefreshTip"))
    self.inspector = K.Inspector:New(f)
    local panel = self.inspector.body
    self.selection = self.inspector.item
    self.summary = K.Label(panel, "", 12, -48, 240)
    self.summary:SetHeight(100); self.summary:SetJustifyV("TOP")
    self.location = K.Label(panel, "", 12, -158, 240)
    self.location:SetHeight(64); self.location:SetJustifyV("TOP")
    self.stock = K.Label(panel, "", 12, -228, 240)
    self.stock:SetHeight(26); self.stock:SetJustifyV("TOP")
    local info = K.Button(panel, ns.T("tradeInfo"), 24, function() end)
    info:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 12, 10)
    K.Tooltip(info, ns.T("vendorResaleCategory"), ns.T("vendorResaleTip"))
    K.Label(panel, ns.T("vendorResaleCaveat"), 12, -264, 240):SetHeight(44)
    f:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render()
    return self
end
