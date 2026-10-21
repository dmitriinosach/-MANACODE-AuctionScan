local _, ns = ...
local E = {mailOpen = false, queue = {}, echo = {}, taken = {}, gifts = {}, arriving = {}}
ns.AccountingEvents = E
local ANSWER = 5
local CAPTURE = 60
local QUIET = 0.6
local ATTACHMENTS = 12
function E.BagCount(itemID, suffix)
    if not GetContainerNumSlots or not GetContainerItemLink or not GetContainerItemInfo then return nil end
    local count = 0
    for bag = 0, 4 do
        for slot = 1, ns.Compat.BagSlots(bag) or 0 do
            local id, random = ns.Lot.FromLink(GetContainerItemLink(bag, slot))
            if id == itemID and random == (suffix or 0) then
                local quantity = select(2, ns.Compat.BagItemIcon(bag, slot))
                if not quantity then return nil end
                count = count + quantity
            end
        end
    end
    return count
end
function E.WonName(text)
    if type(text) ~= "string" or type(ERR_AUCTION_WON_S) ~= "string" then return nil end
    local prefix, suffix = ERR_AUCTION_WON_S:match("^(.-)%%s(.-)$")
    if not prefix or #text <= #prefix + #suffix then return nil end
    if text:sub(1, #prefix) ~= prefix or text:sub(#text - #suffix + 1) ~= suffix then return nil end
    return text:sub(#prefix + 1, #text - #suffix)
end
local refusals
function E.Refusal(text)
    if not refusals then
        refusals = {}
        for _, key in ipairs({"ERR_ITEM_NOT_FOUND", "ERR_AUCTION_HIGHER_BID", "ERR_NOT_ENOUGH_MONEY",
            "ERR_AUCTION_BID_OWN", "ERR_AUCTION_DATABASE_ERROR", "ERR_ITEM_MAX_COUNT"}) do
            if type(_G[key]) == "string" then refusals[_G[key]] = true end
        end
    end
    return text ~= nil and refusals[text] == true
end
local function candidate(itemID, link)
    if not itemID or not ns.Disenchant then return nil end
    return ns.Disenchant.Candidate(itemID, link) or nil
end
function E.Bid(kind, index, amount)
    if not GetAuctionItemInfo or (kind ~= "list" and kind ~= "bidder") then return end
    local name, _, count, _, _, _, _, _, buyout, _, _, owner = GetAuctionItemInfo(kind, index)
    if not name then return end
    local entry = {name = name, buyout = buyout and buyout > 0 and amount and amount >= buyout or false, at = GetTime()}
    if entry.buyout then
        local link = GetAuctionItemLink and GetAuctionItemLink(kind, index)
        local itemID, suffix = ns.Lot.FromLink(link)
        local model = candidate(itemID, link)
        if model then
            entry.event = ns.Accounting.Buy({itemID = itemID, link = link, suffix = suffix, count = count or 1,
                cost = amount, owner = owner, level = model.level, quality = model.quality, band = model.band,
                sent = true}, "auction")
        end
    end
    E.queue[#E.queue + 1] = entry
    E.last = entry
end
function E.Answer(won, name)
    local now = GetTime()
    while E.queue[1] and now - E.queue[1].at > ANSWER do table.remove(E.queue, 1) end
    local index = E.queue[1] and 1 or nil
    if name then
        index = nil
        for i, entry in ipairs(E.queue) do
            if entry.buyout and entry.name == name then index = i; break end
        end
    end
    local entry = index and table.remove(E.queue, index)
    if not entry then return end
    if entry.event then ns.Accounting.Resolve(entry.event, won, "auction") end
    if ns.Buy and ns.Buy.OnAnswer then ns.Buy.OnAnswer(entry, won) end
end
function E.Message(event, text)
    if event == "UI_ERROR_MESSAGE" then
        if E.Refusal(text) then E.Answer(false) end
        if E.posting and text ~= ERR_AUCTION_DATABASE_ERROR and E.Refusal(text) then E.posting = nil end
        return
    end
    if text == ERR_AUCTION_BID_PLACED then
        local first = E.queue[1]
        if first and first.buyout then E.echo[first.name] = (E.echo[first.name] or 0) + 1 end
        E.Answer(true)
    elseif text == ERR_AUCTION_STARTED then
        local posting = E.posting
        if posting and posting.stacks == 1 then E.posting = nil; ns.Accounting.Post(posting) end
    else
        local name = E.WonName(text)
        if not name then return end
        if (E.echo[name] or 0) > 0 then E.echo[name] = E.echo[name] - 1; return end
        E.Answer(true, name)
    end
end
function E.MaterialByName(name)
    if not name then return nil end
    for _, id in ipairs(ns.disenchantMaterials) do
        if ns.Compat.ItemInfo(id) == name then return id end
    end
end
function E.Posting(bid, buyout, runTime, stackSize, numStacks)
    if not GetAuctionSellItemInfo then return end
    local name, _, count = GetAuctionSellItemInfo()
    local itemID = E.MaterialByName(name)
    local m = itemID and ns.Accounting.Project().materials[itemID]
    if not m or m.remaining <= 0 then E.posting = nil; return end
    E.posting = {itemID = itemID, stack = stackSize or count or 1, stacks = numStacks or 1, bid = bid or 0,
        buyout = buyout or 0, hours = ({12, 24, 48})[runTime] or 24, created = 0}
end
function E.Cancelling(index)
    if not GetAuctionItemInfo then return end
    local name, _, count, _, _, _, _, _, buyout = GetAuctionItemInfo("owner", index)
    local itemID = E.MaterialByName(name)
    if not itemID then return end
    for _, post in ipairs(ns.Accounting.Project().posts) do
        if post.active and post.itemID == itemID and post.stack == count and post.buyout == (buyout or 0) then
            ns.Accounting.Unpost(post.id); return
        end
    end
end
function E.Taking(index)
    if not GetInboxInvoiceInfo then return end
    local kind, itemName, _, bid, buyout, deposit, fee, _, _, _, count = GetInboxInvoiceInfo(index)
    if kind ~= "seller" or not itemName or not bid or bid <= 0 then return end
    local daysLeft = GetInboxHeaderInfo and select(7, GetInboxHeaderInfo(index))
    local key = table.concat({itemName, bid, buyout or 0, deposit or 0, fee or 0}, "|")
    if E.taken[key] and GetTime() - E.taken[key] < 30 then return end
    E.taken[key] = GetTime()
    local itemID = E.MaterialByName(itemName)
    local A = ns.Accounting
    local p = itemID and A.Project()
    local m = p and p.materials[itemID]
    if not m or (m.remaining <= 0 and m.posted <= 0) then return end
    local now, post = time(), nil
    for _, candidate in ipairs(p.posts) do
        local open = candidate.sold + candidate.removed < candidate.stacks and candidate.ends + 7200 > now
        local exact = candidate.buyout == bid
        local byBid = candidate.bid <= bid and (candidate.buyout == 0 or bid < candidate.buyout)
        if candidate.itemID == itemID and open and (exact or byBid) and (not post or (exact and post.buyout ~= bid)) then
            post = candidate
        end
    end
    if type(count) ~= "number" or count <= 0 then count = post and post.stack or nil end
    local at = type(daysLeft) == "number" and math.min(now, math.floor(now + (daysLeft - 30) * 86400)) or now
    A.Sell({itemID = itemID, count = count, gross = bid, fee = fee or 0, post = post and post.id, at = at}, "mail")
end
local function awaited()
    local keys = {}
    for _, chain in ipairs(ns.Accounting.Project().chains) do
        if chain.stage == "sent" or chain.stage == "unsure" or chain.stage == "mail" then
            local key = chain.itemID .. ":" .. chain.suffix
            keys[key] = keys[key] or {itemID = chain.itemID, suffix = chain.suffix, chains = {}}
            local list = keys[key].chains
            list[#list + 1] = chain
        end
    end
    return keys
end
function E.CheckMail()
    if not E.mailOpen then return end
    E.mailCounts = E.mailCounts or {}
    for key, info in pairs(awaited()) do
        local count = E.BagCount(info.itemID, info.suffix)
        local before = E.mailCounts[key]
        if count and before and count > before then
            local left = count - before
            local gift = math.min(left, E.arriving[key] or 0)
            E.arriving[key], left = (E.arriving[key] or 0) - gift, left - gift
            for _, chain in ipairs(info.chains) do
                local take = math.min(left, chain.count - chain.received)
                if take > 0 then
                    if chain.state == "sent" then ns.Accounting.Resolve(chain.id, true, "mail") end
                    ns.Accounting.Receive(chain.id, take, "mail")
                    left = left - take
                end
            end
        end
        if count then E.mailCounts[key] = count end
    end
end
function E.Gift(index, attach)
    if not GetInboxHeaderInfo or not GetInboxItemLink then return end
    local _, _, sender, _, _, _, _, items, _, _, _, canReply = GetInboxHeaderInfo(index)
    if not canReply or (items or 0) == 0 or (GetInboxInvoiceInfo and GetInboxInvoiceInfo(index)) then return end
    for a = attach or 1, attach or ATTACHMENTS do
        local link = GetInboxItemLink(index, a)
        local itemID, suffix = ns.Lot.FromLink(link)
        if itemID and candidate(itemID, link) then
            local key = itemID .. ":" .. suffix
            local count = GetInboxItem and select(3, GetInboxItem(index, a)) or 1
            local gift = E.gifts[key] or {count = 0}
            gift.count, gift.from = gift.count + (count or 1), sender
            E.gifts[key] = gift
            E.arriving[key] = (E.arriving[key] or 0) + (count or 1)
        end
    end
    if ns.CollectUI then ns.CollectUI.Refresh() end
end
function E.Untracked()
    local bags = ns.DisenchantLog.BagSnapshot()
    if not bags then return {} end
    local held = {}
    for _, chain in ipairs(ns.Accounting.Project().chains) do
        if chain.state ~= "lost" then
            local key = chain.itemID .. ":" .. chain.suffix
            held[key] = (held[key] or 0) + math.max(0, chain.received - chain.processed)
        end
    end
    local out = {}
    for key, item in pairs(bags) do
        local count = item.count - (held[key] or 0)
        local model = count > 0 and candidate(item.itemID, item.link)
        if model then
            local gift = E.gifts[key]
            out[#out + 1] = {key = key, itemID = item.itemID, suffix = item.suffix, link = item.link, count = count,
                level = model.level, quality = model.quality, band = model.band,
                gift = gift and math.min(gift.count, count) or 0, from = gift and gift.from}
        end
    end
    table.sort(out, function(a, b)
        if (a.gift > 0) ~= (b.gift > 0) then return a.gift > 0 end
        if a.level ~= b.level then return a.level > b.level end
        return a.key < b.key
    end)
    return out
end
function E.GiftCount()
    if not next(E.gifts) then return 0 end
    local total = 0
    for _, item in ipairs(E.Untracked()) do total = total + item.gift end
    return total
end
function E.Add(items, basis, own)
    if #items == 0 then return nil, "acIntakeNone" end
    local A, costs, missing = ns.Accounting, {}, 0
    for index, item in ipairs(items) do
        costs[index] = A.UnitCost(item, basis, own)
        if not costs[index] then missing = missing + 1 end
    end
    if missing > 0 then return nil, basis == "own" and "acInvalid" or "acIntakeNoPrice", missing end
    local added = 0
    for index, item in ipairs(items) do
        local gift = item.gift > 0 and E.gifts[item.key]
        local id = A.Intake({itemID = item.itemID, link = item.link, suffix = item.suffix, count = item.count,
            cost = costs[index] * item.count, basis = basis, from = gift and gift.from or nil, level = item.level,
            quality = item.quality, band = item.band}, gift and "mail" or "bags")
        if id then
            added = added + item.count
            if gift then
                gift.count = gift.count - item.count
                if gift.count <= 0 then E.gifts[item.key] = nil end
            end
        end
    end
    return added
end
local function disenchantable()
    local keys = {}
    for _, chain in ipairs(ns.Accounting.Project().chains) do
        if chain.state ~= "lost" and chain.processed < chain.count then
            local key = chain.itemID .. ":" .. chain.suffix
            keys[key] = keys[key] or {}
            local list = keys[key]
            list[#list + 1] = chain
        end
    end
    return keys
end
function E.Spell(event, unit, spell)
    if unit ~= "player" or not spell or spell ~= ns.Compat.SpellIcon(13262) then return end
    if event == "UNIT_SPELLCAST_START" then
        E.Settle(true)
        local materials = {}
        for _, id in ipairs(ns.disenchantMaterials) do materials[id] = GetItemCount(id, false) end
        E.capture = {bags = ns.DisenchantLog.BagSnapshot(), materials = materials, state = "cast", at = GetTime()}
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local c = E.capture
        if c and c.state == "cast" then c.state, c.deadline, c.changed = "done", GetTime() + CAPTURE, GetTime() end
    elseif E.capture and E.capture.state == "cast" then
        E.capture = nil
    end
end
function E.Vanished(before, after, chains)
    local material, bought, others = {}, nil, {}
    for _, id in ipairs(ns.disenchantMaterials) do material[id] = true end
    for key, item in pairs(before) do
        local left = after[key] and after[key].count or 0
        if item.count - left == 1 and not material[item.itemID] then
            if chains[key] then bought = bought or item
            elseif ns.DisenchantLog.Plausible(item.itemID, item.link) then others[#others + 1] = item end
        end
    end
    if bought then return bought, chains[bought.itemID .. ":" .. bought.suffix] end
    if #others == 1 then return others[1], nil end
end
function E.Settle(force)
    local c = E.capture
    if not c or c.state ~= "done" then return false end
    local now = GetTime()
    if now > c.deadline then E.capture = nil; return false end
    if not force and (now - c.changed < QUIET or c.checked == c.changed) then return false end
    c.checked = c.changed
    local after = c.bags and ns.DisenchantLog.BagSnapshot()
    local target, chains
    if after then target, chains = E.Vanished(c.bags, after, disenchantable()) end
    local outputs = {}
    for _, id in ipairs(ns.disenchantMaterials) do
        local delta = GetItemCount(id, false) - (c.materials[id] or 0)
        if delta > 0 then outputs[#outputs + 1] = {itemID = id, count = delta} end
    end
    if not target or #outputs == 0 then
        if force then E.capture = nil end
        return false
    end
    E.capture = nil
    if not chains then
        return ns.DisenchantLog.Record({itemID = target.itemID, suffix = target.suffix, link = target.link,
            outputs = outputs, bought = false}, "cast") ~= nil
    end
    local chosen
    for _, chain in ipairs(chains) do
        if not chosen or (chain.received > chain.processed and chosen.received <= chosen.processed) then chosen = chain end
    end
    return ns.Accounting.Disenchant(chosen.id, outputs, "cast") ~= nil
end
function E.BagChanged()
    if E.capture and E.capture.state == "done" then E.capture.changed = GetTime() end
    E.dirty = true
end
function E.Update()
    if E.dirty then
        E.dirty = false; E.CheckMail()
        if next(E.gifts) and ns.CollectUI then ns.CollectUI.Refresh() end
    end
    if E.capture then E.Settle() end
end
function E.MailShow()
    E.mailOpen, E.mailCounts, E.arriving = true, {}, {}
    for key, info in pairs(awaited()) do E.mailCounts[key] = E.BagCount(info.itemID, info.suffix) end
end
function E.Install()
    E.hooked = E.hooked or {}
    local function hook(name, fn)
        if type(_G[name]) == "function" and not E.hooked[name] then
            E.hooked[name] = true
            hooksecurefunc(name, fn)
        end
    end
    hook("PlaceAuctionBid", function(kind, index, amount) E.Bid(kind, index, amount) end)
    hook("StartAuction", function(...) E.Posting(...) end)
    hook("CancelAuction", function(index) E.Cancelling(index) end)
    hook("TakeInboxMoney", function(index) E.Taking(index) end)
    hook("AutoLootMailItem", function(index) E.Taking(index); E.Gift(index) end)
    hook("TakeInboxItem", function(index, attach) E.Gift(index, attach) end)
end
E.Install()
local frame = ns.NewFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "MAIL_SHOW", "MAIL_CLOSED", "BAG_UPDATE", "CHAT_MSG_SYSTEM",
    "UI_ERROR_MESSAGE", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_INTERRUPTED",
    "UNIT_SPELLCAST_FAILED", "AUCTION_MULTISELL_UPDATE", "AUCTION_MULTISELL_FAILURE"}) do ns.Listen(frame, event) end
frame:SetScript("OnEvent", function(_, event, first, second)
    if event == "PLAYER_LOGIN" then E.Install()
    elseif event == "MAIL_SHOW" then E.MailShow()
    elseif event == "MAIL_CLOSED" then E.mailOpen, E.mailCounts, E.arriving = false, nil, {}
    elseif event == "BAG_UPDATE" then E.BagChanged()
    elseif event == "CHAT_MSG_SYSTEM" or event == "UI_ERROR_MESSAGE" then E.Message(event, first)
    elseif event == "AUCTION_MULTISELL_UPDATE" then
        local posting = E.posting
        if posting then
            posting.created = first or posting.created
            if second and first and first >= second then
                E.posting = nil; posting.stacks = first; ns.Accounting.Post(posting)
            end
        end
    elseif event == "AUCTION_MULTISELL_FAILURE" then
        local posting = E.posting
        E.posting = nil
        if posting and (posting.created or 0) > 0 then posting.stacks = posting.created; ns.Accounting.Post(posting) end
    else E.Spell(event, first, second) end
end)
frame:SetScript("OnUpdate", function() E.Update() end)
