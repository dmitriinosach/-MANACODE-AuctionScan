local _, ns = ...
local UI = { props = { selected = 1, page = 1 }, rows = {}, nav = {} }
UI.professionModes = {}
UI.processKind = "disenchant"
ns.Trader = UI
local PROCESS_KINDS = {
    {key = "disenchant", labelKey = "procDisenchant"},
    {key = "prospect", labelKey = "procProspect", module = "ProspectUI"},
    {key = "mill", labelKey = "procMill", module = "ProspectUI"},
    {key = "recycle", labelKey = "procRecycle"},
}
local PROFESSION_MODES = {
    {key = "craft", labelKey = "modeCraft"},
    {key = "leveling", labelKey = "modeLeveling"},
    {key = "resale", labelKey = "modeNpc"},
}
local BAR_HEIGHT = 26
function UI.Ready()
    if ns.TradeKit and ns.AuctionPage and ns.Markets and type(ns.Markets.routes) == "table"
        and ns.Query and ns.Plan and ns.Buy and ns.Shopping and ns.ShoppingUI
        and ns.Family and ns.FamilyUI and ns.gemFamilies and ns.gemByRaw and ns.gemByItem
        and ns.Alchemy and ns.AlchemyUI and ns.Batch and ns.alchemyRecipes
        and ns.Reagents and ns.ReagentsUI and ns.Resale and ns.ResaleUI and ns.CraftPlan and ns.AuctionWindow
        and ns.Activity and ns.Disenchant and ns.DisenchantUI and ns.MarketBoardUI
        and ns.Collections and ns.CollectionsUI and ns.Hidden and ns.HiddenUI and ns.Recipes
        and ns.seasonalEvents and ns.Seasonal and ns.SeasonalUI and ns.OfferPreview and ns.Leveling and ns.LevelingUI
        and ns.levelingCatalogs and ns.levelingCatalogs.enchanting
        and ns.Accounting and ns.AccountingEvents and ns.AccountingUI
        and ns.Recycle and ns.RecycleUI and ns.recyclePairs then return true end
    if not UI.warned then
        UI.warned = true
        ns.say(ns.T("tradeRestartRequired"))
    end
    return false
end
function UI:SetProps(props)
    self.props = props
    self:Render()
end
function UI.Status(text)
    UI.lastStatus = text
    UI.RenderStatus()
    if ns.MarketBoardUI then ns.MarketBoardUI.Status(text) end
    if ns.FamilyUI then ns.FamilyUI:Controls() end
    if ns.AlchemyUI and ns.AlchemyUI.frame then ns.AlchemyUI:Controls() end
    if ns.ReagentsUI and ns.ReagentsUI.frame then ns.ReagentsUI:Controls() end
    if ns.ResaleUI and ns.ResaleUI.frame then ns.ResaleUI:Controls() end
    if ns.DisenchantUI and ns.DisenchantUI.frame then
        if UI.ViewActive("disenchant") then ns.DisenchantUI:Render() else ns.DisenchantUI:Controls() end
    end
    if ns.CollectionsUI and ns.CollectionsUI.frame and UI.section == "collections" then ns.CollectionsUI:Render() end
    if ns.SeasonalUI and ns.SeasonalUI.frame and UI.section == "seasonal" then ns.SeasonalUI:Render() end
    if ns.LevelingUI and ns.LevelingUI.frame then
        if UI.ViewActive("leveling") then ns.LevelingUI:Render() else ns.LevelingUI:Controls() end
    end
    if ns.RecycleUI and ns.RecycleUI.frame then
        if UI.ViewActive("recycle") then ns.RecycleUI:Render() else ns.RecycleUI:Controls() end
    end
end
function UI.Busy()
    return ns.Scan.state.phase ~= "idle" or ns.Buy.Active() or ns.Batch.job ~= nil
        or (ns.Disenchant and ns.Disenchant.purchase ~= nil) or (ns.Prospect and ns.Prospect.purchase ~= nil)
        or (ns.Bargain and ns.Bargain.Active and ns.Bargain.Active()) or false
end
function UI.StopAll()
    if ns.Disenchant and ns.Disenchant.purchase then ns.Disenchant.CancelBuy() end
    if ns.Prospect and ns.Prospect.purchase then ns.Prospect.CancelBuy() end
    if ns.Bargain and ns.Bargain.Active and ns.Bargain.Active() then ns.Bargain.Cancel() end
    ns.Buy.Stop()
    ns.Batch.Stop()
    ns.Scan.Stop()
    UI.Refresh()
end
function UI.ResumeScan()
    if ns.Scan.state.phase == "paused" then ns.Scan.Start("pages") end
    UI.Refresh()
end
function UI.ContextText()
    local views = {prospect = ns.ProspectUI, mill = ns.ProspectUI, disenchant = ns.DisenchantUI,
        leveling = ns.LevelingUI, hidden = ns.HiddenUI, bargain = ns.BargainUI}
    for key, view in pairs(views) do if view.frame and UI.ViewActive(key) then return view.statusText end end
end
function UI.ActivityText()
    local K, state = ns.TradeKit, ns.Scan.state
    if ns.Buy.Active() then
        local R = ns.Buy.state
        return ns.T("deBuyStage", R.page + 1, R.pages > 0 and tostring(R.pages) or "?", ns.Buy.Left(),
            R.bought, K.Money(R.spent))
    end
    if state.phase == "idle" then
        local parts = {}
        local context = UI.ContextText()
        if context and context ~= "" then parts[#parts + 1] = context end
        if UI.lastStatus then parts[#parts + 1] = UI.lastStatus end
        return table.concat(parts, " | ")
    end
    local text
    local D, view = ns.Disenchant, ns.DisenchantUI
    if D and view and view.frame and D.Progress(view.group) then text = view:ProgressText() end
    local job = ns.Batch.job
    if not text and job and state.scan and state.scan.itemID then
        text = ns.T("statusPrices", math.min(job.index, #job.items), #job.items, ns.Markets.Name(state.scan.itemID),
            state.page + 1, state.pages > 0 and tostring(state.pages) or "?")
        if state.phase == "paused" then text = ns.T("deProgressPaused", text) end
    end
    return text or UI.lastStatus or ns.T("deOtherScan")
end
function UI.ActivityShare()
    if ns.Buy.Active() then
        local R = ns.Buy.state
        return R.pages > 0 and math.min(1, R.page / R.pages) or nil
    end
    local S, job = ns.Scan.state, ns.Batch.job
    if S.mode == "all" and S.phase ~= "idle" then
        return S.count > 0 and S.phase ~= "wait" and math.min(1, S.index / S.count) or nil
    end
    local page = S.phase ~= "idle" and S.pages > 0 and math.min(1, S.page / S.pages) or nil
    if job and #job.items > 1 then return math.min(1, (job.index - 1 + (page or 0)) / #job.items) end
    local classes = S.phase ~= "idle" and S.scan and S.scan.deClasses
    if classes and #classes > 1 and page then return math.min(1, ((S.scan.deRoute or 1) - 1 + page) / #classes) end
    return page
end
function UI.RenderStatus()
    if not UI.footerStatus then return end
    UI.footerStatus:SetText(UI.ActivityText())
    local busy = UI.Busy()
    local waiting = ns.Scan.state.phase == "paused" or ns.Buy.state.phase == "ready"
    UI.footerProgress:Set(busy and UI.ActivityShare() or nil, busy and not waiting, busy)
    if busy then UI.footerStop:Show() else UI.footerStop:Hide() end
    if ns.Scan.state.phase == "paused" then UI.footerResume:Show() else UI.footerResume:Hide() end
end
function UI.ViewActive(view)
    if view == "leveling" then return UI.IsProfession(UI.section) and UI.professionModes[UI.section] == "leveling" end
    for _, kind in ipairs(PROCESS_KINDS) do
        if kind.key == view then return UI.section == "processing" and UI.processKind == view end
    end
    return UI.section == view
end
function UI.IsProfession(section)
    return section == "jewelry" or (section ~= nil and ns.craftCatalogs[section] ~= nil)
end
function UI.ProcessAvailable(kind)
    for _, entry in ipairs(PROCESS_KINDS) do
        if entry.key == kind then return entry.module == nil or ns[entry.module] ~= nil end
    end
    return false
end
function UI.Refresh()
    if UI.frame then UI:Render() end
    if ns.ShoppingUI then ns.ShoppingUI:Render() end
end
function UI:ShowSection(section)
    if section == "leveling" then
        self.professionModes.enchanting = "leveling"; section = "enchanting"
    else
        for _, kind in ipairs(PROCESS_KINDS) do
            if kind.key == section then self.processKind = section; section = "processing" end
        end
    end
    if self.section ~= section and ns.Buy.Active() then ns.Buy.Stop() end
    self.section = section
    for _, view in ipairs({self.jewelry, self.alchemy, self.reagents, self.resale, self.disenchant, self.recycle,
        self.collections, self.hiddenView, self.leveling, self.accounting, self.buyView.frame,
        self.processing, self.professionView, self.bargain, self.seasonal}) do
        view:Hide()
    end
    if self.prospect then self.prospect:Hide() end
    local profession = false
    if section == "buy" then self.buyView.frame:Show()
    elseif section == "processing" then self:ShowProcessKind()
    elseif section == "bargain" then self.bargain:Show()
    elseif section == "seasonal" then self:ShowSeasonEvent()
    elseif section == "reagents" then self.reagents:Show()
    elseif section == "collections" then self.collections:Show()
    elseif section == "hidden" then self.hiddenView:Show()
    elseif section == "accounting" then
        self.accountingView = self.accountingView or ns.AccountingUI:New(self.accounting)
        self.accounting:Show()
    else
        profession = true
        self:ShowProfession(section)
    end
    local labelKey = section == "jewelry" and "jewelrySection"
        or (ns.craftCatalogs[section] and ns.craftCatalogs[section].labelKey) or "craftProfessions"
    self.professionMenu.frame:SetText(ns.T(labelKey))
    for key, button in pairs(self.nav) do button:SetActive(key == section) end
    self.professionMenu.frame:SetActive(profession)
    UI.Refresh()
end
function UI:ShowProcessKind()
    if not UI.ProcessAvailable(self.processKind) then self.processKind = "disenchant" end
    local kind = self.processKind
    self.processing:Show()
    self.disenchant:Hide(); self.recycle:Hide()
    if self.prospect then self.prospect:Hide() end
    if kind == "disenchant" then self.disenchant:Show()
    elseif kind == "recycle" then self.recycle:Show()
    else
        self.prospect:Show()
        ns.ProspectUI:SetProps({mode = kind})
    end
    self.processSegment:Select(kind)
end
function UI.OpenProcessing(kind)
    if not UI.ProcessAvailable(kind) then kind = "disenchant" end
    UI.processKind = kind
    UI:ShowSection("processing")
end
function UI:ShowSeasonEvent()
    local key = ns.SeasonalUI.props.event
    self.seasonal:Show()
    ns.SeasonalUI:SetProps({event = key})
    self.seasonSegment:Select(key)
end
function UI.OpenSeasonal(key)
    local event = ns.Seasonal.Event(key)
    if event and #event.items > 0 then ns.SeasonalUI.props.event = key end
    UI:ShowSection("seasonal")
end
function UI:ShowProfession(profession)
    local mode = self.professionModes[profession] or "craft"
    if mode == "leveling" and not ns.levelingCatalogs[profession] then mode = "craft" end
    self.professionModes[profession] = mode
    self.professionView:Show()
    if mode == "resale" then
        ns.ResaleUI:SetProps({profession = profession})
        self.resale:Show()
    elseif mode == "leveling" then self.leveling:Show()
    elseif ns.craftCatalogs[profession] then
        ns.AlchemyUI:SetProps({profession = profession})
        self.alchemy:Show()
    else self.jewelry:Show() end
    local segment = self.modeSegment
    segment:Select(mode)
    local leveling = segment.buttons.leveling
    if ns.levelingCatalogs[profession] then leveling:Enable() else leveling:Disable() end
end
function UI.SetProfessionMode(profession, mode)
    if not UI.IsProfession(profession) then return end
    if mode ~= "craft" and mode ~= "resale" and mode ~= "leveling" then return end
    if mode == "leveling" and not ns.levelingCatalogs[profession] then return end
    UI.professionModes[profession] = mode
    UI:ShowSection(profession)
end
function UI.OpenProfession(profession)
    UI:ShowSection(profession)
end
function UI.OpenRecipe(profession, id)
    local catalog = ns.craftCatalogs[profession]
    if not catalog or not catalog.byItem[id] then return end
    UI.professionModes[profession] = "craft"
    UI:ShowSection(profession)
    ns.AlchemyUI:SetProps({recipe = id, id = id, reveal = true})
end
function UI.OpenReagent(id)
    UI:ShowSection("reagents")
    ns.ReagentsUI:SetProps({id = id})
end
function UI.OpenBuy(id, need)
    if ns.vendorPrices and ns.vendorPrices[id] then ns.say(ns.T("cacheVendor")); return end
    local name = ns.Compat.ItemInfo(id)
    if not name then ns.say(ns.T("tradeUnknownItem")); return end
    UI:ShowSection("buy")
    if need then
        if need > 1000 then ns.say(ns.T("levelBuyBatch", need)); need = 1000 end
        ns.Shopping.Reset()
        ns.Shopping.SetNeed(need)
        UI.buyView.pendingNeed = nil
    end
    UI.buyView.query:SetText(name)
    ns.Shopping.Search(name, id)
end
function UI:Render()
    self:LayoutNavigation()
    UI.RenderStatus()
    if ns.FamilyUI then ns.FamilyUI:Render() end
    if ns.AlchemyUI then ns.AlchemyUI:Render() end
    if ns.ReagentsUI then ns.ReagentsUI:Render() end
    if ns.ResaleUI then ns.ResaleUI:Render() end
    if ns.DisenchantUI then ns.DisenchantUI:Render() end
    if ns.CollectionsUI then ns.CollectionsUI:Render() end
    if ns.SeasonalUI and ns.SeasonalUI.frame then ns.SeasonalUI:Render() end
    if ns.HiddenUI then ns.HiddenUI:Render() end
    if ns.LevelingUI then ns.LevelingUI:Render() end
    if ns.RecycleUI then ns.RecycleUI:Render() end
    if ns.ProspectUI and ns.ProspectUI.frame then ns.ProspectUI:Render() end
    if ns.BargainUI and ns.BargainUI.frame then ns.BargainUI:Render() end
    if self.accountingView and self.accounting:IsVisible() then self.accountingView:Render() end
    if ns.OfferPreview and ns.OfferPreview.frame and ns.OfferPreview.frame:IsShown() then ns.OfferPreview:Render() end
end
function UI:LayoutNavigation()
    if not self.frame or not self.content then return end
    local narrow = (self.frame:GetWidth() or 996) < 900
    if self.narrowNav == narrow then return end
    self.narrowNav = narrow
    if narrow then self.marketsLabel:Hide() else self.marketsLabel:Show() end
    self.nav.processing:ClearAllPoints()
    if narrow then self.nav.processing:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -34)
    else self.nav.processing:SetPoint("LEFT", self.marketsLabel, "RIGHT", 4, 0) end
end
function UI.UpdateMoney()
    if UI.money then UI.money:SetText(ns.TradeKit.Money(GetMoney())) end
end
function UI:BuildChrome(parent, root)
    local chrome = ns.TradeKit.AuctionChrome(parent, root)
    self.title, self.money, self.footerStatus = chrome.title, chrome.money, chrome.status
    self.footerStop, self.footerResume, self.footerProgress = chrome.stop, chrome.resume, chrome.progress
    chrome.stop.onClick = UI.StopAll
    chrome.resume.onClick = UI.ResumeScan
    ns.TradeKit.Tooltip(chrome.stop, ns.T("tradeStop"), ns.T("statusStopTip"))
    ns.TradeKit.Tooltip(chrome.resume, ns.T("tradeResume"), ns.T("statusResumeTip"))
    root:SetScript("OnUpdate", function(_, elapsed)
        UI.statusTick = (UI.statusTick or 0) + elapsed
        UI.footerProgress:Tick(elapsed)
        if UI.statusTick >= 0.25 then UI.statusTick = 0; UI.RenderStatus() end
    end)
    self.background = rawget(root, "tradeBase")
    local events = ns.NewFrame("Frame", nil, root)
    ns.Listen(events, "PLAYER_MONEY")
    events:SetScript("OnEvent", UI.UpdateMoney)
    root:SetScript("OnShow", UI.UpdateMoney)
end
function UI:NavButton(root, label, section)
    local K = ns.TradeKit
    local b = K.Button(root, label, 80, function() self:ShowSection(section) end, "nav")
    K.FitButton(b, 18)
    self.nav[section] = b
    return b
end
function UI:Container(parent)
    local frame = ns.NewFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    return frame
end
function UI:SegmentBar(container, entries, choose)
    local segment = ns.TradeKit.Segment(container, entries, choose)
    segment.frame:SetPoint("TOPLEFT", container, "TOPLEFT", 8, -2)
    local body = ns.NewFrame("Frame", nil, container)
    body:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -BAR_HEIGHT)
    body:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
    return segment, body
end
function UI:BuildProcessing(content)
    local K = ns.TradeKit
    self.processing = self:Container(content)
    local entries = {}
    for _, kind in ipairs(PROCESS_KINDS) do entries[#entries + 1] = {key = kind.key, label = ns.T(kind.labelKey)} end
    self.processSegment, self.processBody = self:SegmentBar(self.processing, entries, UI.OpenProcessing)
    self.disenchant = ns.DisenchantUI:New(self.processBody).frame
    self.recycle = ns.RecycleUI:New(self.processBody).frame
    if ns.ProspectUI then self.prospect = ns.ProspectUI:New(self.processBody).frame end
    for _, kind in ipairs(PROCESS_KINDS) do
        if not UI.ProcessAvailable(kind.key) then
            local button = self.processSegment.buttons[kind.key]
            button:Disable()
            K.DisabledTip(button, ns.T(kind.labelKey), ns.T("procLater"))
        end
    end
end
function UI:BuildSeasonal(content)
    local K = ns.TradeKit
    self.seasonal = self:Container(content)
    local entries = {}
    for _, event in ipairs(ns.seasonalEvents) do entries[#entries + 1] = {key = event.key, label = ns.T(event.shortKey)} end
    local body
    self.seasonSegment, body = self:SegmentBar(self.seasonal, entries, UI.OpenSeasonal)
    ns.SeasonalUI:New(body)
    for _, event in ipairs(ns.seasonalEvents) do
        local button = self.seasonSegment.buttons[event.key]
        if #event.items > 0 then K.Tooltip(button, ns.T(event.labelKey), ns.T(event.timingKey))
        else
            button:Disable()
            K.DisabledTip(button, ns.T(event.labelKey), ns.T(event.timingKey) .. "\n\n" .. ns.T("seasonNoAuctionItems"))
        end
    end
end
function UI:BuildProfessions(content)
    local K = ns.TradeKit
    self.professionView = self:Container(content)
    local entries = {}
    for _, mode in ipairs(PROFESSION_MODES) do entries[#entries + 1] = {key = mode.key, label = ns.T(mode.labelKey)} end
    self.modeSegment, self.professionBody = self:SegmentBar(self.professionView, entries, function(mode)
        UI.SetProfessionMode(UI.section, mode)
    end)
    K.DisabledTip(self.modeSegment.buttons.leveling, ns.T("modeLeveling"), ns.T("modeNoLeveling"))
    local family = ns.FamilyUI:New(self.professionBody)
    self.jewelry, self.rows = family.frame, family.rows
    self.alchemy = ns.AlchemyUI:New(self.professionBody).frame
    self.resale = ns.ResaleUI:New(self.professionBody).frame
    self.leveling = ns.LevelingUI:New(self.professionBody).frame
end
function UI:New(parent)
    if not UI.Ready() then return nil end
    if self.frame then return self end
    local K = ns.TradeKit
    local root = ns.NewFrame("Frame", nil, parent)
    self.frame = root
    self:BuildChrome(parent, root)
    self.marketsLabel = K.Label(root, ns.T("tradeMarkets"), 14, -33, 60)
    self.marketsLabel:SetFontObject(K.Font("ManaCodeNavTitleFont", "GameFontNormal", 14))
    self.marketsLabel:SetHeight(26); self.marketsLabel:SetJustifyV("MIDDLE")
    self.marketsLabel:SetWidth(math.ceil((self.marketsLabel:GetStringWidth() or 40) + 2))
    self.marketsLabel:SetTextColor(unpack(K.theme.secondary))
    local processingTab = self:NavButton(root, ns.T("navProcessing"), "processing")
    processingTab:SetPoint("LEFT", self.marketsLabel, "RIGHT", 4, 0)
    local professions = {{key = "jewelry", labelKey = "jewelrySection"}}
    for _, key in ipairs(ns.Crafting.order) do
        if ns.craftCatalogs[key] then professions[#professions + 1] = {key = key, labelKey = ns.craftCatalogs[key].labelKey} end
    end
    self.professionMenu = K.Menu(root, professions, UI.OpenProfession)
    K.MakeNav(self.professionMenu.frame)
    K.HoverMenu(self.professionMenu)
    self.professionMenu.frame:SetWidth(150)
    self.professionMenu.frame:SetPoint("LEFT", processingTab, "RIGHT", 2, 0)
    local materialsTab = self:NavButton(root, ns.T("navMaterials"), "reagents")
    materialsTab:SetPoint("LEFT", self.professionMenu.frame, "RIGHT", 2, 0)
    local bargainTab = self:NavButton(root, ns.T("navBelowMarket"), "bargain")
    bargainTab:SetPoint("LEFT", materialsTab, "RIGHT", 2, 0)
    local seasonalTab = self:NavButton(root, ns.T("navSeasonal"), "seasonal")
    seasonalTab:SetPoint("LEFT", bargainTab, "RIGHT", 2, 0)
    local purchase = self:NavButton(root, ns.T("buySection"), "buy")
    purchase:SetPoint("LEFT", seasonalTab, "RIGHT", 2, 0)
    K.NavDivider(root, purchase)
    self:NavButton(root, ns.T("collectionTitle"), "collections"):SetPoint("LEFT", purchase, "RIGHT", 17, 0)
    self:NavButton(root, ns.T("hiddenSection"), "hidden"):SetPoint("LEFT", self.nav.collections, "RIGHT", 2, 0)
    self:NavButton(root, ns.T("acNav"), "accounting"):SetPoint("LEFT", self.nav.hidden, "RIGHT", 2, 0)
    local complete = K.Button(root, ns.T("cacheCompleteAll"), 120, function()
        ns.Batch.All(K.ScanMode()); UI.Refresh()
    end)
    complete.tipFn = function()
        return ns.T("cacheCompleteAllTip") .. "\n\n" .. ns.Batch.PreviewText(ns.Batch.AllSources(), true)
    end
    complete:SetPoint("TOPRIGHT", root, "TOPRIGHT", -34, -7)
    self.complete = complete
    K.Tooltip(complete, ns.T("cacheCompleteAll"), ns.T("cacheCompleteAllTip"))
    local content = ns.NewFrame("Frame", nil, root)
    self.content = content
    content:SetPoint("TOPLEFT", root, "TOPLEFT", 8, -64)
    content:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -8, 32)
    self.buyView = ns.ShoppingUI:New(content)
    self:BuildProcessing(content)
    self:BuildProfessions(content)
    self.reagents = ns.ReagentsUI:New(content).frame
    self.collections = ns.CollectionsUI:New(content).frame
    self:BuildSeasonal(content)
    self.hiddenView = ns.HiddenUI:New(content).frame
    self.bargain = self:Container(content)
    if ns.BargainUI then ns.BargainUI:New(self.bargain)
    else
        self.bargainStub = K.Label(self.bargain, ns.T("bargainStub"), 0, 0, 400, "secondary")
        self.bargainStub:ClearAllPoints()
        self.bargainStub:SetPoint("CENTER", self.bargain, "CENTER", 0, 0)
        self.bargainStub:SetJustifyH("CENTER")
    end
    self.accounting = self:Container(content)
    self:LayoutNavigation()
    ns.OfferPreview.New(root)
    self.tab = ns.AuctionPage.Install(root)
    self:ShowSection("buy")
    ns.AuctionWindow.Install(parent)
    root:Hide()
    root:SetScript("OnSizeChanged", function() self:LayoutNavigation() end)
    return self
end
local events = ns.NewFrame("Frame")
ns.Listen(events, "AUCTION_HOUSE_SHOW")
events:SetScript("OnEvent", function()
    if AuctionFrame then
        if not UI:New(AuctionFrame) then return end
        if PanelTemplates_GetSelectedTab(AuctionFrame) ~= ns.AuctionPage.index then UI.frame:Hide() end
        UI.Refresh()
    end
end)
ns.Scan.onComplete = function(scan)
    if ns.Shopping then ns.Shopping.Accept(scan) end
    if ns.Batch then ns.Batch.Accept(scan) end
    UI.Refresh()
end
