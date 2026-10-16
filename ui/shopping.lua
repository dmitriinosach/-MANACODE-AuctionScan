local _, ns = ...
local UI = { page = 1, choices = {}, options = {}, rows = {} }
ns.ShoppingUI = UI
local function money(copper)
    return GetCoinTextureString(math.floor(copper))
end
function UI:Render()
    if not self.frame then return end
    local Shop, K = ns.Shopping, ns.TradeKit
    local S, R = Shop.state, ns.Buy.state
    local active = ns.Buy.Active()
    local visibleChoices = K.ListCapacity(self.frame, 56, 24, 28, #self.choices)
    local choiceOffset = self.choiceScroll:SetRange(#S.items, visibleChoices)
    for i, b in ipairs(self.choices) do
        local item = i <= visibleChoices and S.items[choiceOffset + i]
        if item then K.SetItemChoice(b, item.id, item.id == S.itemID) else b:Hide() end
    end
    self.heading:SetText(S.name or ns.T("buySearchHint"))
    self.need:SetText(tostring(S.need))
    for i, b in ipairs(self.options) do
        local plan = S.options[i]
        if plan then
            b:SetText(ns.T("buyOpt_" .. plan.kind, plan.units, money(plan.cost)))
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
    local visibleOffers = K.ListCapacity(self.frame, 154, 74, 22, #self.rows)
    local offerOffset = self.offerScroll:SetRange(#shown, visibleOffers)
    local width = (self.frame:GetWidth() or 996) - 252
    for i, row in ipairs(self.rows) do
        row.frame:SetWidth(width); row.text:SetWidth(width - 60)
        local offer = i <= visibleOffers and shown[offerOffset + i]
        if offer then
            row.offer = offer
            row.text:SetText(ns.T("buyOfferRow", S.plan and ns.Plan.LotsOf(S.plan, offer) or 0,
                offer.count, offer.stack, money(offer.buyout / offer.stack), money(offer.buyout)))
            row.frame:Show()
            if active then row.minus:Disable(); row.plus:Disable() else row.minus:Enable(); row.plus:Enable() end
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
end
function UI:New(parent)
    if self.frame then return self end
    local K = ns.TradeKit
    local frame = ns.NewFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    self.frame = frame
    self.query = K.Edit(frame, 260)
    self.query:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -4)
    self.query:SetMaxLetters(120)
    local function search()
        self.query:ClearFocus()
        self.choiceScroll.offset, self.offerScroll.offset = 0, 0
        ns.Shopping.Search(self.query:GetText())
    end
    self.query:SetScript("OnEnterPressed", search)
    local searchButton = K.Button(frame, ns.T("buySearch"), 90, search, "main")
    searchButton:SetPoint("LEFT", self.query, "RIGHT", 6, 0)
    K.Label(frame, ns.T("buyCapNeed"), 430, -10, 95)
    self.need = K.Edit(frame, 48)
    self.need:SetPoint("TOPLEFT", frame, "TOPLEFT", 552, -4)
    self.need:SetNumeric(true)
    self.need:SetMaxLetters(4)
    self.need:SetScript("OnTextChanged", function(edit, user)
        if user then self.pendingNeed, self.pendingAt = tonumber(edit:GetText()) or 1, GetTime() + 0.3 end
    end)
    self.need:SetScript("OnEnterPressed", function(edit) edit:ClearFocus() end)
    local minus = K.Button(frame, "-", 22, function() ns.Shopping.SetNeed(ns.Shopping.state.need - (IsShiftKeyDown() and 10 or 1)) end)
    minus:SetPoint("RIGHT", self.need, "LEFT", -4, 0)
    local plus = K.Button(frame, "+", 22, function() ns.Shopping.SetNeed(ns.Shopping.state.need + (IsShiftKeyDown() and 10 or 1)) end)
    plus:SetPoint("LEFT", self.need, "RIGHT", 4, 0)
    local reset = K.Button(frame, ns.T("buyReset"), 70, function() ns.Shopping.Reset() end)
    reset:SetPoint("LEFT", plus, "RIGHT", 8, 0)
    K.Label(frame, ns.T("buyResults"), 10, -38, 192, "heading")
    self.heading = K.Label(frame, "", 216, -38, 550, "heading")
    self.choiceScroll = K.Scroller:New(frame, function() self:Render() end, 28)
    self.choiceScroll.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -56)
    self.choiceScroll.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 206, 24)
    for i = 1, 40 do
        local choice = K.ItemChoice(frame, function()
            local item = ns.Shopping.state.items[self.choiceScroll.offset + i]
            if item then ns.Shopping.Select(item.id) end
        end)
        choice:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -56 - (i - 1) * 28)
        choice:SetWidth(178); choice.text:SetWidth(144)
        self.choiceScroll:Wheel(choice)
        self.choices[i] = choice
    end
    for i = 1, 3 do
        local option = K.Button(frame, "", 550, function() ns.Shopping.Option(i) end)
        option:SetPoint("TOPLEFT", frame, "TOPLEFT", 216, -58 - (i - 1) * 24)
        self.options[i] = option
    end
    K.Label(frame, ns.T("buyOffersHead"), 240, -136, 510)
    self.offerScroll = K.Scroller:New(frame, function() self:Render() end, 22)
    self.offerScroll.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 216, -154)
    self.offerScroll.frame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 74)
    for i = 1, 40 do
        local row = {}
        row.frame = ns.NewFrame("Frame", nil, frame)
        row.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 216, -154 - (i - 1) * 22)
        row.frame:SetWidth(550)
        row.frame:SetHeight(22)
        row.text = K.Label(row.frame, "", 26, -4, 492)
        row.minus = K.Button(row.frame, "-", 22, function() ns.Shopping.Adjust(row.offer, -1) end)
        row.minus:SetPoint("LEFT", row.frame, "LEFT", 0, 0)
        row.plus = K.Button(row.frame, "+", 22, function() ns.Shopping.Adjust(row.offer, 1) end)
        row.plus:SetPoint("RIGHT", row.frame, "RIGHT", 0, 0)
        self.rows[i] = row
        self.offerScroll:Wheel(row.frame)
    end
    self.summary = K.Label(frame, "", 216, -274, 550, "heading")
    self.summary:ClearAllPoints(); self.summary:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 216, 42)
    self.go = K.Button(frame, "", 450, function() ns.Shopping.Go() end, "main")
    self.go:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 216, 6)
    local stop = K.Button(frame, ns.T("buyStop"), 80, function() ns.Buy.Stop(); ns.Scan.Stop() end)
    stop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 6)
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
