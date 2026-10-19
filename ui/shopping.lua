local _, ns = ...
local UI = { page = 1, choices = {}, options = {}, rows = {} }
ns.ShoppingUI = UI
local LEFT = 236
local PANEL = 272
local function money(copper)
    return GetCoinTextureString(math.floor(copper))
end
function UI:Render()
    if not self.frame then return end
    local Shop, K = ns.Shopping, ns.TradeKit
    local S, R = Shop.state, ns.Buy.state
    local active = ns.Buy.Active()
    local width = self.frame:GetWidth() or 996
    local right = math.max(300, width - LEFT - 20 - PANEL)
    local visibleChoices = K.ListCapacity(self.frame, 54, 36, 28, #self.choices)
    local choiceOffset = self.choiceScroll:SetRange(#S.items, visibleChoices)
    for i, b in ipairs(self.choices) do
        local item = i <= visibleChoices and S.items[choiceOffset + i]
        b:SetWidth(LEFT - 18); b.text:SetWidth(LEFT - 52)
        if item then K.SetItemChoice(b, item.id, item.id == S.itemID) else b:Hide() end
    end
    self.heading:SetText(S.name or ns.T("buyNoSelection"))
    self.need:SetMaxLetters(S.priceLimit and 8 or 4)
    self.need:SetText(tostring(S.need))
    if not self.editingLimit then self.limit:SetText(S.priceLimit and tostring(S.priceLimit / 10000) or "") end
    self.limit:EnableMouse(not active)
    if active then self.applyLimit:Disable() else self.applyLimit:Enable() end
    if active then self.limit:ClearFocus() end
    self.need:EnableMouse(not active and not S.priceLimit)
    for i, b in ipairs(self.options) do
        local plan = S.options[i]
        b:SetWidth(right)
        if plan then
            b:SetText(ns.T("buyOpt_" .. plan.kind, plan.units, money(plan.cost)))
            b:SetActive(S.plan ~= nil and S.plan.kind == plan.kind)
            if active then b:Disable() else b:Enable() end
            b:Show()
        else b:Hide() end
    end
    local shown, seen = {}, {}
    if S.plan then
        for _, pick in ipairs(S.plan.picks) do
            if pick.lots > 0 then shown[#shown + 1] = pick.offer; seen[pick.offer] = true end
        end
    end
    for _, offer in ipairs(S.offers) do
        if not seen[offer] and offer.count > 0 then shown[#shown + 1] = offer end
    end
    local visibleOffers = K.ListCapacity(self.frame, 182, 70, 22, #self.rows)
    local offerOffset = self.offerScroll:SetRange(#shown, visibleOffers)
    local inner = right - 22
    self.offerHead:SetWidth(inner)
    local columns = {plan = {30, 90}, stack = {120, 80}, unit = {math.max(200, inner - 240), 110},
        lot = {math.max(310, inner - 130), 110}}
    for key, label in pairs(self.columns) do
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", self.offerHead, "TOPLEFT", columns[key][1], -4)
        label:SetWidth(columns[key][2])
    end
    for i, row in ipairs(self.rows) do
        row.frame:SetWidth(inner)
        local offer = i <= visibleOffers and shown[offerOffset + i]
        if offer then
            row.offer = offer
            for key, cell in pairs(row.cells) do
                cell:ClearAllPoints()
                cell:SetPoint("TOPLEFT", row.frame, "TOPLEFT", columns[key][1], -5)
                cell:SetWidth(columns[key][2])
            end
            row.cells.plan:SetText(ns.T("buyPlanRow", S.plan and ns.Plan.LotsOf(S.plan, offer) or 0, offer.count))
            row.cells.stack:SetText(ns.T("buyStackRow", offer.stack))
            row.cells.unit:SetText(money(offer.buyout / offer.stack))
            row.cells.lot:SetText(money(offer.buyout))
            if i % 2 == 1 then row.stripe:Show() else row.stripe:Hide() end
            row.frame:Show()
            if active then row.minus:Disable(); row.plus:Disable()
            else
                row.minus:Enable()
                if S.priceLimit and offer.buyout >= S.priceLimit * offer.stack then row.plus:Disable() else row.plus:Enable() end
            end
        else row.frame:Hide() end
    end
    if Shop.Got() > 0 then
        self.summary:SetText(ns.T("buyProgress", Shop.Got(), S.need, money(Shop.Spent())))
    elseif S.plan then
        self.summary:SetText(ns.T("buyTotal", S.plan.units, money(S.plan.cost)))
    else self.summary:SetText(ns.T("buyAvailable", ns.Plan.Available(S.offers))) end
    self.go:Disable()
    if active then
        local n, cost = ns.Buy.Offer()
        self.go:SetText(R.phase == "ready" and ns.T("buyConfirm", n, money(cost)) or ns.T("buyFinding", R.page + 1))
        if R.phase == "ready" then self.go:Enable() end
    elseif Shop.Left() == 0 then
        self.go:SetText(ns.T("buyGoReached"))
    elseif S.plan then
        self.go:SetText(ns.T("buyGo", S.plan.units, money(S.plan.cost)))
        if ns.Scan.state.phase == "idle" then self.go:Enable() end
    else self.go:SetText(ns.T("buyGoEmpty")) end
    self:RenderPanel()
end
function UI:RenderPanel()
    local K, S = ns.TradeKit, ns.Shopping.state
    local id = S.itemID
    local stats = id and ns.Shopping.Stats(S.offers)
    if not id then
        self.panelItem:Hide(); self.panelMarket:Hide()
        for _, row in ipairs(self.stats) do row.key:Hide(); row.value:Hide() end
        self.panelNow:Hide(); self.panelHistory:Hide()
        self.panelEmpty:Show()
        return
    end
    self.panelEmpty:Hide(); self.panelNow:Show(); self.panelHistory:Show(); self.panelMarket:Show()
    K.SetItemChoice(self.panelItem, id, false)
    local board = ns.Activity and ns.Activity.Board(id, 7)
    local quote = ns.Markets.Quote(id)
    local values = {
        stats and K.Money(stats.min), stats and K.Money(stats.market), stats and K.Money(stats.median),
        stats and K.Money(stats.mean), stats and ns.T("buyStatSupplyValue", stats.units, stats.lots),
        board and board.median and K.Money(board.median),
        quote and quote.at and not quote.vendor and K.Ago(math.max(0, time() - quote.at)),
    }
    for i, row in ipairs(self.stats) do
        row.key:Show(); row.value:Show()
        row.value:SetText(values[i] or ns.T("tradeNoPrice"))
    end
end
function UI:NewPanel(frame)
    local K = ns.TradeKit
    local panel = ns.NewFrame("Frame", nil, frame)
    panel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -34)
    panel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 40)
    panel:SetWidth(PANEL - 8)
    K.Panel(panel)
    self.panel = panel
    self.panelItem = K.ItemChoice(panel, function()
        local id = ns.Shopping.state.itemID
        if id and ns.MarketWindow then ns.MarketWindow.Open(id) end
    end)
    self.panelItem:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8)
    self.panelItem:SetWidth(PANEL - 28); self.panelItem.text:SetWidth(PANEL - 60)
    self.panelItem.extraTip = ns.T("itemHistoryOpenTip")
    self.panelMarket = K.Button(panel, ns.T("inspectorMarket"), PANEL - 28, function()
        local id = ns.Shopping.state.itemID
        if id and ns.MarketWindow then ns.MarketWindow.Open(id) end
    end)
    self.panelMarket:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -36)
    K.Tooltip(self.panelMarket, ns.T("inspectorMarket"), ns.T("inspectorMarketTip"))
    self.panelNow = K.Label(panel, ns.T("buyPanelNow"), 12, -68, PANEL - 40, "heading")
    self.panelNow:SetHeight(14)
    K.Tooltip(panel, ns.T("buyPanelNow"), ns.T("buyPanelTip") .. "\n\n" .. ns.T("buyStatMarketTip"))
    self.stats = {}
    local keys = {"buyStatMin", "buyStatMarket", "buyStatMedian", "buyStatMean", "buyStatSupply", "buyStatWeek", "buyStatScan"}
    for i, key in ipairs(keys) do
        local y = -88 - (i - 1) * 18 - (i >= 6 and 28 or 0)
        local label = K.Label(panel, ns.T(key), 12, y, 110, "secondary")
        label:SetHeight(12)
        local value = K.Label(panel, "", 0, 0, PANEL - 130)
        value:SetHeight(12); value:SetJustifyH("RIGHT")
        value:ClearAllPoints(); value:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, y)
        self.stats[i] = {key = label, value = value}
    end
    self.panelHistory = K.Label(panel, ns.T("buyPanelHistory"), 12, -88 - 5 * 18 - 8, PANEL - 40, "heading")
    self.panelHistory:SetHeight(14)
    self.panelEmpty = K.Label(panel, ns.T("buyPanelEmpty"), 12, -12, PANEL - 40, "secondary")
    self.panelEmpty:SetHeight(40); self.panelEmpty:SetJustifyV("TOP")
end
function UI.InsertLink(text)
    if type(text) ~= "string" or not text:find("item:", 1, true) then return end
    local chat = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    if chat and chat:IsShown() then return end
    if ChatFrameEditBox and ChatFrameEditBox:IsShown() and ChatFrameEditBox:HasFocus() then return end
    local trader = ns.Trader and ns.Trader.frame
    if not trader or not trader:IsVisible() then return end
    local id = ns.Lot.FromLink(text)
    if id then ns.Trader.OpenBuy(id) end
end
function UI:NewSearch(frame)
    local K = ns.TradeKit
    local caption = K.Label(frame, ns.T("buyQueryLabel"), 10, -9, 54, "secondary")
    caption:SetHeight(12)
    self.query = K.Edit(frame, 260)
    self.query:SetPoint("TOPLEFT", frame, "TOPLEFT", 66, -4)
    self.query:SetMaxLetters(120)
    local function search()
        self.query:ClearFocus()
        self.choiceScroll.offset, self.offerScroll.offset = 0, 0
        ns.Shopping.Search(self.query:GetText())
    end
    self.query:SetScript("OnEnterPressed", function()
        if self.suggest:Pick() then return end
        search()
    end)
    self.suggest = K.Suggest(self.query, function(text) return ns.Shopping.Suggest(text, 8) end, function(entry)
        self.query:SetText(entry.name); self.query:ClearFocus()
        self.choiceScroll.offset, self.offerScroll.offset = 0, 0
        ns.Shopping.Search(entry.name, entry.id)
    end)
    K.Tooltip(self.query, ns.T("buyQueryLabel"), ns.T("buySuggestTip"))
    self.search = K.Button(frame, ns.T("buySearch"), 80, search)
    self.search:SetPoint("LEFT", self.query, "RIGHT", 6, 0)
    local needLabel = K.Label(frame, ns.T("buyCapNeed"), 0, 0, 86, "secondary")
    needLabel:SetHeight(12); needLabel:ClearAllPoints()
    needLabel:SetPoint("LEFT", self.search, "RIGHT", 18, 0)
    local minus = K.Button(frame, "-", 22, function() ns.Shopping.SetNeed(ns.Shopping.state.need - (IsShiftKeyDown() and 10 or 1)) end, "quiet")
    minus:SetPoint("LEFT", needLabel, "RIGHT", 4, 0)
    self.need = K.Edit(frame, 48)
    self.need:SetPoint("LEFT", minus, "RIGHT", 4, 0)
    self.need:SetNumeric(true)
    self.need:SetMaxLetters(4)
    self.need:SetScript("OnTextChanged", function(edit, user)
        if user then self.pendingNeed, self.pendingAt = tonumber(edit:GetText()) or 1, GetTime() + 0.3 end
    end)
    self.need:SetScript("OnEnterPressed", function(edit) edit:ClearFocus() end)
    local plus = K.Button(frame, "+", 22, function() ns.Shopping.SetNeed(ns.Shopping.state.need + (IsShiftKeyDown() and 10 or 1)) end, "quiet")
    plus:SetPoint("LEFT", self.need, "RIGHT", 4, 0)
    local reset = K.Button(frame, ns.T("buyReset"), 64, function() ns.Shopping.Reset() end, "quiet")
    reset:SetPoint("LEFT", plus, "RIGHT", 10, 0)
end
function UI:NewPlan(frame)
    local K = ns.TradeKit
    self.heading = K.Label(frame, "", LEFT + 10, -37, 500, "heading")
    self.heading:SetHeight(14)
    for i = 1, 3 do
        local option = K.Button(frame, "", 550, function() ns.Shopping.Option(i) end, "quiet")
        option:SetPoint("TOPLEFT", frame, "TOPLEFT", LEFT + 10, -56 - (i - 1) * 25)
        option.text:SetJustifyH("LEFT")
        self.options[i] = option
    end
    self.limitLabel = K.Label(frame, ns.T("buyPriceLimit"), LEFT + 10, -139, 90, "secondary")
    self.limitLabel:SetHeight(12)
    self.limit = K.Edit(frame, 82)
    self.limit:SetPoint("LEFT", self.limitLabel, "RIGHT", 4, 0)
    self.limit:SetMaxLetters(12)
    K.Tooltip(self.limit, ns.T("buyPriceLimit"), ns.T("buyPriceLimitTip"))
    local function applyLimit(edit)
        self.editingLimit = false
        local text = edit:GetText():match("^%s*(.-)%s*$")
        local value = tonumber((text:gsub(",", ".")))
        if text ~= "" and (not value or value < 0.0001 or value > 100000) then
            ns.say(ns.T("buyPriceInvalid")); self:Render(); return false
        end
        self.pendingNeed = nil
        return ns.Shopping.SetPriceLimit(text ~= "" and math.floor(value * 10000 + 0.5) or nil)
    end
    self.applyLimitFn = applyLimit
    K.LiveEdit(self.limit, function(edit)
        local text = edit:GetText():match("^%s*(.-)%s*$")
        local value = tonumber((text:gsub(",", ".")))
        if text == "" or value and value >= 0.0001 and value <= 100000 then
            self.pendingNeed = nil
            ns.Shopping.SetPriceLimit(text ~= "" and math.floor(value * 10000 + 0.5) or nil)
        end
    end)
    self.limit:SetScript("OnEditFocusGained", function() self.editingLimit = true end)
    self.limit:SetScript("OnEditFocusLost", applyLimit)
    self.limit:SetScript("OnEscapePressed", function(edit)
        edit:SetText(ns.Shopping.state.priceLimit and tostring(ns.Shopping.state.priceLimit / 10000) or "")
        edit:ClearFocus()
    end)
    self.applyLimit = K.Button(frame, ns.T("buyApplyPrice"), 90, function()
        applyLimit(self.limit); self.limit:ClearFocus()
    end, "quiet")
    self.applyLimit:SetPoint("LEFT", self.limit, "RIGHT", 6, 0)
    self.offerHead = ns.NewFrame("Frame", nil, frame)
    self.offerHead:SetPoint("TOPLEFT", frame, "TOPLEFT", LEFT + 10, -160)
    self.offerHead:SetHeight(20); self.offerHead:SetWidth(550)
    K.HeaderBand(self.offerHead)
    self.columns = {}
    for _, entry in ipairs({{"plan", "buyColPlan"}, {"stack", "buyColStack"}, {"unit", "buyColUnit"}, {"lot", "buyColLot"}}) do
        local label = K.Label(self.offerHead, ns.T(entry[2]), 0, -4, 100, "secondary")
        label:SetHeight(12)
        if entry[1] ~= "plan" then label:SetJustifyH("RIGHT") end
        self.columns[entry[1]] = label
    end
    self.offerScroll = K.Scroller:New(frame, function() self:Render() end, 22)
    self.offerScroll.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", LEFT + 10, -182)
    self.offerScroll.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8 - PANEL, 70)
    for i = 1, 40 do
        local row = {cells = {}}
        row.frame = ns.NewFrame("Frame", nil, frame)
        row.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", LEFT + 10, -182 - (i - 1) * 22)
        row.frame:SetWidth(550)
        row.frame:SetHeight(22)
        row.stripe = K.Background(row.frame)
        row.stripe:SetVertexColor(unpack(K.theme.row))
        for _, key in ipairs({"plan", "stack", "unit", "lot"}) do
            local cell = K.Label(row.frame, "", 0, -5, 100)
            cell:SetHeight(12)
            if key ~= "plan" then cell:SetJustifyH("RIGHT") end
            row.cells[key] = cell
        end
        row.minus = K.Button(row.frame, "-", 22, function() ns.Shopping.Adjust(row.offer, -1) end, "quiet")
        row.minus:SetHeight(20)
        row.minus:SetPoint("LEFT", row.frame, "LEFT", 2, 0)
        row.plus = K.Button(row.frame, "+", 22, function() ns.Shopping.Adjust(row.offer, 1) end, "quiet")
        row.plus:SetHeight(20)
        row.plus:SetPoint("RIGHT", row.frame, "RIGHT", -2, 0)
        self.rows[i] = row
        self.offerScroll:Wheel(row.frame)
    end
end
function UI:New(parent)
    if self.frame then return self end
    local K = ns.TradeKit
    local frame = ns.NewFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    self.frame = frame
    self:NewSearch(frame)
    local results = K.Label(frame, ns.T("buyResults"), 10, -37, LEFT - 20, "heading")
    results:SetHeight(14)
    self.choiceScroll = K.Scroller:New(frame, function() self:Render() end, 28)
    self.choiceScroll.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -54)
    self.choiceScroll.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", LEFT, 36)
    for i = 1, 40 do
        local choice = K.ItemChoice(frame, function()
            local item = ns.Shopping.state.items[self.choiceScroll.offset + i]
            if item then ns.Shopping.Select(item.id) end
        end)
        choice:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -54 - (i - 1) * 28)
        choice:SetWidth(LEFT - 18); choice.text:SetWidth(LEFT - 52)
        self.choiceScroll:Wheel(choice)
        self.choices[i] = choice
    end
    local divider = K.Rule(frame, 0)
    divider:ClearAllPoints()
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", LEFT, -34); divider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", LEFT, 36)
    divider:SetWidth(1); divider:SetHeight(0)
    self:NewPlan(frame)
    self:NewPanel(frame)
    local foot = K.Rule(frame, 0)
    foot:ClearAllPoints()
    foot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 6, 36); foot:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 36)
    self.summary = K.Label(frame, "", 10, 0, 400)
    self.summary:SetHeight(12)
    self.summary:ClearAllPoints(); self.summary:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 11)
    self.go = K.Button(frame, "", 300, function()
        if self.editingLimit then
            if not self.applyLimitFn(self.limit) then return end
            self.limit:ClearFocus()
        end
        ns.Shopping.Go()
    end, "main")
    self.go:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 4)
    self.summary:SetPoint("RIGHT", self.go, "LEFT", -10, 0)
    frame:SetScript("OnUpdate", function()
        if self.pendingNeed and GetTime() >= self.pendingAt then
            local need = self.pendingNeed
            self.pendingNeed = nil
            ns.Shopping.SetNeed(need)
        end
    end)
    frame:SetScript("OnSizeChanged", function() self:Render() end)
    self:Render()
    return self
end
ns.Shopping.onChange = function() UI:Render() end
if type(ChatEdit_InsertLink) == "function" then hooksecurefunc("ChatEdit_InsertLink", UI.InsertLink) end
