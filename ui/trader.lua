local _, ns = ...
local UI = { props = { selected = 1, page = 1, fee = 0.05 }, rows = {}, nav = {} }
UI.professionModes = {}
ns.Trader = UI
function UI.Ready()
    if ns.TradeKit and ns.AuctionPage and ns.Markets and type(ns.Markets.routes) == "table"
        and ns.Query and ns.Plan and ns.Buy and ns.Shopping and ns.ShoppingUI
        and ns.Family and ns.FamilyUI and ns.gemFamilies and ns.gemByRaw and ns.gemByItem
        and ns.Alchemy and ns.AlchemyUI and ns.Batch and ns.alchemyRecipes
        and ns.Reagents and ns.ReagentsUI and ns.Resale and ns.ResaleUI and ns.CraftPlan and ns.AuctionWindow
        and ns.Activity and ns.Disenchant and ns.DisenchantUI and ns.MarketBoardUI
        and ns.Collections and ns.CollectionsUI and ns.Hidden and ns.HiddenUI
        and ns.seasonalEvents and ns.OfferPreview then return true end
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
    if UI.status then UI.status:SetText(text) end
    if ns.MarketBoardUI then ns.MarketBoardUI.Status(text) end
    if ns.FamilyUI then ns.FamilyUI:Controls() end
    if ns.AlchemyUI and ns.AlchemyUI.status then
        ns.AlchemyUI.status:SetText(text)
        ns.AlchemyUI:Controls()
    end
    if ns.ReagentsUI and ns.ReagentsUI.status then
        ns.ReagentsUI.status:SetText(text)
        ns.ReagentsUI:Controls()
    end
    if ns.ResaleUI and ns.ResaleUI.status then
        ns.ResaleUI.status:SetText(text)
        ns.ResaleUI:Controls()
    end
    if ns.DisenchantUI and ns.DisenchantUI.frame then
        if UI.section == "disenchant" then ns.DisenchantUI:Render() else ns.DisenchantUI:Controls() end
    end
    if ns.CollectionsUI and ns.CollectionsUI.frame then
        ns.CollectionsUI.status:SetText(text)
        if UI.section == "collections" then ns.CollectionsUI:Render() end
    end
end
function UI.Refresh()
    if UI.frame then UI:Render() end
    if ns.ShoppingUI then ns.ShoppingUI:Render() end
end
function UI:ShowSection(section)
    if self.section ~= section and ns.Buy.Active() then ns.Buy.Stop() end
    if self.section ~= section then ns.Batch.Stop() end
    self.section = section
    self.jewelry:Hide()
    self.alchemy:Hide()
    self.reagents:Hide()
    self.resale:Hide()
    self.disenchant:Hide()
    self.collections:Hide()
    self.hiddenView:Hide()
    self.buyView.frame:Hide()
    if section == "buy" then self.buyView.frame:Show()
    elseif section == "reagents" then self.reagents:Show()
    elseif section == "disenchant" then self.disenchant:Show()
    elseif section == "collections" then self.collections:Show()
    elseif section == "hidden" then self.hiddenView:Show()
    elseif self.professionModes[section] == "resale" then
        ns.ResaleUI:SetProps({profession = section})
        self.resale:Show()
    elseif ns.craftCatalogs[section] then
        ns.AlchemyUI:SetProps({profession = section})
        self.alchemy:Show()
    else self.jewelry:Show() end
    local labelKey = section == "jewelry" and "jewelrySection"
        or (ns.craftCatalogs[section] and ns.craftCatalogs[section].labelKey) or "craftProfessions"
    self.professionMenu.frame:SetText(ns.T(labelKey))
    self.nav.buy:SetActive(section == "buy")
    self.nav.reagents:SetActive(section == "reagents")
    self.nav.disenchant:SetActive(section == "disenchant")
    self.nav.collections:SetActive(section == "collections")
    self.nav.hidden:SetActive(section == "hidden")
    self.professionMenu.frame:SetActive(section ~= "buy" and section ~= "reagents" and section ~= "disenchant"
        and section ~= "collections" and section ~= "hidden")
    UI.Refresh()
end
function UI.SetProfessionMode(profession, mode)
    if profession ~= "jewelry" and not ns.craftCatalogs[profession] then return end
    if mode ~= "craft" and mode ~= "resale" then return end
    ns.Batch.Stop()
    UI.professionModes[profession] = mode
    UI:ShowSection(profession)
    if mode == "craft" and ns.craftCatalogs[profession] then ns.AlchemyUI:SetProps({view = "list"}) end
end
function UI.OpenProfession(profession)
    UI:ShowSection(profession)
    if UI.professionModes[profession] ~= "resale" and ns.craftCatalogs[profession] then
        ns.AlchemyUI:SetProps({view = "list"})
    end
end
function UI.OpenRecipe(profession, id, fee)
    local catalog = ns.craftCatalogs[profession]
    if not catalog or not catalog.byItem[id] then return end
    UI.professionModes[profession] = "craft"
    UI:ShowSection(profession)
    ns.AlchemyUI:SetProps({recipe = id, id = id, fee = fee})
end
function UI.OpenReagent(id, fee)
    UI:ShowSection("reagents")
    ns.ReagentsUI:SetProps({id = id, fee = fee})
end
function UI.OpenBuy(id)
    if ns.vendorPrices and ns.vendorPrices[id] then ns.say(ns.T("cacheVendor")); return end
    local name = ns.Compat.ItemInfo(id)
    if not name then ns.say(ns.T("tradeUnknownItem")); return end
    UI:ShowSection("buy")
    UI.buyView.query:SetText(name)
    ns.Shopping.Search(name, id)
end
function UI:Render()
    if ns.FamilyUI then ns.FamilyUI:Render() end
    if ns.AlchemyUI then ns.AlchemyUI:Render() end
    if ns.ReagentsUI then ns.ReagentsUI:Render() end
    if ns.ResaleUI then ns.ResaleUI:Render() end
    if ns.DisenchantUI then ns.DisenchantUI:Render() end
    if ns.CollectionsUI then ns.CollectionsUI:Render() end
    if ns.HiddenUI then ns.HiddenUI:Render() end
    if ns.OfferPreview and ns.OfferPreview.frame and ns.OfferPreview.frame:IsShown() then ns.OfferPreview:Render() end
end
function UI:New(parent)
    if not UI.Ready() then return nil end
    if self.frame then return self end
    local K = ns.TradeKit
    local root = ns.NewFrame("Frame", nil, parent)
    self.frame = root
    root:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -44)
    root:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -24, 44)
    root:SetFrameLevel(parent:GetFrameLevel() + 2)
    root:EnableMouse(true)
    self.background = K.Background(root)
    self.footer = ns.NewFrame("Frame", nil, root)
    self.footer:SetPoint("TOPLEFT", root, "BOTTOMLEFT", 170, 0)
    self.footer:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -24, 18)
    K.Background(self.footer)
    root:SetScript("OnShow", function() ns.UI.SetEmbedded(true) end)
    root:SetScript("OnHide", function() ns.UI.SetEmbedded(false) end)
    self.title = K.Label(root, ns.T("tradeTitle"), 0, 0, 460, "heading")
    self.title:ClearAllPoints()
    self.title:SetPoint("TOP", parent, "TOP", 0, -18)
    self.title:SetJustifyH("CENTER")
    local purchase = K.Button(root, ns.T("buySection"), 100, function() self:ShowSection("buy") end, "quiet")
    self.nav.buy = purchase
    purchase:SetPoint("TOPLEFT", root, "TOPLEFT", 6, -2)
    local professions = {{key = "jewelry", labelKey = "jewelrySection"}}
    for _, key in ipairs(ns.Crafting.order) do
        if ns.craftCatalogs[key] then professions[#professions + 1] = {key = key, labelKey = ns.craftCatalogs[key].labelKey} end
    end
    self.professionMenu = K.Menu(root, professions, UI.OpenProfession)
    self.professionMenu.frame:SetPoint("LEFT", purchase, "RIGHT", 6, 0)
    local reagentTab = K.Button(root, ns.T("reagentsSection"), 100, function() self:ShowSection("reagents") end, "quiet")
    self.nav.reagents = reagentTab
    reagentTab:SetPoint("LEFT", self.professionMenu.frame, "RIGHT", 6, 0)
    local disenchantTab = K.Button(root, ns.T("deTitle"), 90, function() self:ShowSection("disenchant") end, "quiet")
    self.nav.disenchant = disenchantTab
    disenchantTab:SetPoint("LEFT", reagentTab, "RIGHT", 6, 0)
    self.nav.collections = K.Button(root, ns.T("collectionTitle"), 90, function() self:ShowSection("collections") end, "quiet")
    self.nav.collections:SetPoint("LEFT", disenchantTab, "RIGHT", 6, 0)
    self.nav.hidden = K.Button(root, ns.T("hiddenSection"), 90, function() self:ShowSection("hidden") end, "quiet")
    self.nav.hidden:SetPoint("LEFT", self.nav.collections, "RIGHT", 6, 0)
    local complete = K.Button(root, ns.T("cacheCompleteAll"), 126, function()
        ns.Batch.All(K.ScanMode()); UI.Refresh()
    end, "main")
    complete.tipFn = function()
        return ns.T("cacheCompleteAllTip") .. "\n\n" .. ns.Batch.PreviewText(ns.Batch.AllSources(), true)
    end
    complete:SetPoint("TOPRIGHT", root, "TOPRIGHT", -6, -2)
    K.Tooltip(complete, ns.T("cacheCompleteAll"), ns.T("cacheCompleteAllTip"))
    local content = ns.NewFrame("Frame", nil, root)
    content:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -30)
    content:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", 0, 0)
    self.buyView = ns.ShoppingUI:New(content)
    local family = ns.FamilyUI:New(content)
    self.jewelry, self.rows, self.status = family.frame, family.rows, family.status
    self.alchemy = ns.AlchemyUI:New(content).frame
    self.reagents = ns.ReagentsUI:New(content).frame
    self.resale = ns.ResaleUI:New(content).frame
    self.disenchant = ns.DisenchantUI:New(content).frame
    self.collections = ns.CollectionsUI:New(content).frame
    self.hiddenView = ns.HiddenUI:New(content).frame
    ns.OfferPreview.New(root)
    self.tab = ns.AuctionPage.Install(root)
    self:ShowSection("buy")
    ns.AuctionWindow.Install(parent)
    root:Hide()
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
