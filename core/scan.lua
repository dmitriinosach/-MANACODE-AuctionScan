local ADDON, ns = ...
local Scan = {}
ns.Scan = Scan
local CHUNK = 400
local PAGE = 50
local GAP = 0.3
local MAX_GAP = 8
local BACKOFF = 5
local STALE_STEP = 0.1
local STALE_POLLS = 50
local SETTLE = 0.3
local REREAD = 3
local ALL_REREAD_GAP = 1
local PAGE_TIMEOUT = 30
local RETRY = 2
local ALL_TIMEOUT = 300
local PAUSE_LIMIT = 1800
local S = {
    phase = "idle", mode = "pages", scan = nil, index = 1, count = 0, page = 0, pages = 0,
    expect = 0, miss = 0, retry = {}, rereads = 0, tries = 0, gap = GAP, errors = 0, sig = "", stale = 0, sentAt = 0, readAt = 0, nextAt = 0,
    startedAt = 0, pausedAt = 0, open = false,
}
Scan.state = S
Scan.onStatus = nil
Scan.onComplete = nil
local sending = false
local hooked = false
local function cooling()
    return math.max(0, (ns.Store.DB().cooldownUntil or 0) - time())
end
function Scan.Trace(what)
    local stack = (debugstack(3, 4, 6) or ""):gsub("Interface\\AddOns\\", ""):gsub("%s*\n%s*", " < ")
    ns.Store.Log(what .. " phase=" .. S.phase .. " page=" .. (S.page + 1) .. "/" .. S.pages
        .. " t=" .. math.floor(GetTime() - S.startedAt) .. " | " .. stack)
end
local function status(key, ...)
    if Scan.onStatus then Scan.onStatus(ns.T(key, ...)) end
end
local function readOne(i)
    local name, _, count, quality, _, _, minBid, _, buyout, bid, _, owner = GetAuctionItemInfo("list", i)
    local item, suffix = ns.Lot.FromLink(GetAuctionItemLink("list", i))
    if not item or not name then return false end
    if S.scan.itemID and item ~= S.scan.itemID then return true end
    if S.scan.scope == "disenchant" then
        local meta = ns.Disenchant.Candidate(item, GetAuctionItemLink("list", i))
        if meta == nil then return false end
        if meta == false then return true end
        local group = ns.Disenchant.Group(S.scan.deGroup)
        if not ns.Disenchant.Accepts(group, meta)
            or meta.level < ((S.scan.deOptions and S.scan.deOptions.minItemLevel) or 0)
            or (meta.required and (meta.required < group.minLevel or meta.required > group.maxLevel)) then return true end
        S.scan.disenchantItems[item] = meta
    end
    ns.Store.Item(item, name, quality)
    local lots = S.scan.lots
    lots[#lots + 1] = ns.Lot.Encode({
        item = item, suffix = suffix, count = count or 1, minBid = minBid or 0,
        buyout = buyout or 0, bid = bid or 0,
        timeLeft = GetAuctionItemTimeLeft("list", i) or 0, owner = owner,
    })
    return true
end
local function signature(count)
    local parts = {}
    local uniform = count > 0
    for i = 1, count do
        local _, _, n, _, _, _, minBid, _, buyout, bid, _, owner = GetAuctionItemInfo("list", i)
        parts[i] = tostring(GetAuctionItemLink("list", i)) .. ":" .. tostring(n) .. ":" .. tostring(minBid)
            .. ":" .. tostring(buyout) .. ":" .. tostring(bid) .. ":" .. tostring(owner)
        if i > 1 and parts[i] ~= parts[i - 1] then uniform = false end
    end
    return table.concat(parts, ";"), uniform
end
local function pageReady(count)
    for i = 1, count do
        local link = GetAuctionItemLink("list", i)
        if not GetAuctionItemInfo("list", i) or not link then return false end
        if S.scan.scope == "disenchant" and not ns.Compat.ItemInfo(link) then return false end
    end
    return true
end
local function finish()
    local scan = S.scan
    if ns.Disenchant then ns.Disenchant.RestoreSort(scan) end
    scan.total = #scan.lots
    scan.expect = S.expect
    scan.miss = S.miss
    scan.secs = time() - scan.t
    local dropped = ns.Store.Commit(scan)
    ns.Store.Log("done " .. S.mode .. " lots=" .. scan.total .. " expect=" .. S.expect .. " miss=" .. S.miss
        .. " secs=" .. scan.secs .. " errors=" .. S.errors .. " gap=" .. S.gap)
    S.phase, S.scan = "idle", nil
    status("stDone", scan.total)
    ns.say(ns.T("sayDone", scan.total, scan.secs))
    if scan.deCutStopped then ns.say(ns.T("deCutStopped", ns.T("deCutReason" .. scan.deCutStopped))) end
    if S.miss > 0 then ns.say(ns.T("sayMiss", S.miss)) end
    if S.mode == "all" and S.expect > scan.total + S.miss then
        ns.say(ns.T("sayCut", scan.total + S.miss, S.expect))
    end
    if dropped > 0 then ns.say(ns.T("sayDropped", dropped)) end
    if Scan.onComplete then Scan.onComplete(scan) end
end
local function fail(key)
    if ns.Disenchant then ns.Disenchant.RestoreSort(S.scan) end
    ns.Store.Log("fail " .. key .. " phase=" .. S.phase .. " page=" .. (S.page + 1) .. "/" .. S.pages)
    S.phase, S.scan = "idle", nil
    if Scan.onAbort then Scan.onAbort() end
    status(key)
    ns.say(ns.T(key))
end
local function pause(key)
    ns.Store.Log("pause " .. key .. " phase=" .. S.phase .. " page=" .. (S.page + 1) .. "/" .. S.pages)
    S.phase, S.pausedAt = "paused", GetTime()
    status("stPaused", S.page + 1, math.max(S.pages, 1))
    ns.say(ns.T(key, S.page + 1, math.max(S.pages, 1)))
end
local function onForeign()
    if sending or S.phase == "idle" or S.phase == "paused" then return end
    Scan.Trace("foreign query")
    if S.mode == "all" then return fail("stForeignAll") end
    pause("sayForeign")
end
local function send()
    sending = true
    local sent = ns.Query.Send(S.scan.query or "", S.page, false, S.scan)
    sending = false
    if not sent then return end
    S.phase, S.sentAt, S.rereads = "wait", GetTime(), 0
end
local function refused(now, why)
    S.errors, S.tries = S.errors + 1, S.tries + 1
    S.gap = math.min(S.gap * 2, MAX_GAP)
    ns.Store.DB().scanGap = S.gap
    ns.Store.Log("refused " .. why .. " page=" .. (S.page + 1) .. "/" .. S.pages .. " try=" .. S.tries .. " gap=" .. S.gap)
    if why == "error" or S.tries > RETRY then
        ns.Store.DB().cooldownUntil = time() + 120
        return pause("sayRefused")
    end
    S.phase, S.nextAt = "send", now + BACKOFF * S.tries
    status("stBackoff", BACKOFF * S.tries)
end
local function readPage(now)
    local batch, total = GetNumAuctionItems("list")
    batch, total = batch or 0, total or 0
    if batch == 0 and (total > S.page * PAGE or (S.page > 0 and total == 0)) then
        return refused(now, "empty")
    end
    local sig, uniform = signature(batch)
    if S.page > 0 and sig == S.sig then
        if S.stale < STALE_POLLS then
            S.stale, S.readAt = S.stale + 1, now + STALE_STEP
            return
        end
        S.stale = 0
        if not uniform then
            ns.Store.Log("unchanged page=" .. (S.page + 1) .. " wait=" .. string.format("%.2f", now - S.sentAt))
            return pause("sayPageUnchanged")
        end
        ns.Store.Log("identical stacks page=" .. (S.page + 1) .. " lots=" .. batch)
    end
    if not pageReady(batch) and S.rereads < REREAD then
        S.rereads = S.rereads + 1
        S.readAt = now + SETTLE
        return
    end
    for i = 1, batch do
        if not readOne(i) then S.miss = S.miss + 1 end
    end
    if S.page == 0 then S.expect = total end
    ns.Store.Log("page read=" .. (S.page + 1) .. " lots=" .. batch .. " total=" .. total
        .. " response=" .. string.format("%.2f", now - S.sentAt))
    S.sig, S.stale = sig, 0
    S.pages = math.ceil(total / PAGE)
    S.page, S.tries = S.page + 1, 0
    if S.scan.scope == "disenchant" then
        S.scan.miss = S.miss
        local cut = ns.Disenchant.CheckTail(S.scan, batch)
        local blocked = S.scan.deOptions and S.scan.deOptions.cut and S.scan.deCutDisabled
        if (cut or blocked) and S.page < S.pages then
            S.scan.truncated, S.scan.deCut, S.scan.deReadPages = true, cut or nil, S.page
            S.scan.deCutStopped = blocked or nil
            return finish()
        end
    end
    if S.page >= S.pages then return finish() end
    S.phase, S.nextAt = "send", math.max(now, S.sentAt + S.gap)
    local left = math.ceil((now - S.startedAt) / S.page * (S.pages - S.page) / 60)
    status("stPageEta", S.page + 1, S.pages, left)
end
local function readChunk(now)
    local last = math.min(S.index + CHUNK - 1, S.count)
    for i = S.index, last do
        if not readOne(i) then S.retry[#S.retry + 1] = i end
    end
    S.index = last + 1
    status("stRead", last, S.count)
    if S.index <= S.count then return end
    if #S.retry == 0 then return finish() end
    S.phase, S.readAt, S.rereads = "reread", now + ALL_REREAD_GAP, 0
end
local function reread(now)
    local left = {}
    for _, i in ipairs(S.retry) do
        if not readOne(i) then left[#left + 1] = i end
    end
    S.retry, S.rereads = left, S.rereads + 1
    if #left == 0 or S.rereads >= REREAD then
        S.miss = #left
        return finish()
    end
    S.readAt = now + ALL_REREAD_GAP
end
function Scan.Start(mode, target)
    if ns.Buy and ns.Buy.Active() then ns.say(ns.T("sayBusy")); return false end
    if not hooked then
        hooksecurefunc("QueryAuctionItems", onForeign)
        hooked = true
    end
    if cooling() > 0 then
        ns.say(ns.T("tradeCooling", math.ceil(cooling())))
        return false
    end
    if S.phase == "paused" then
        if target and (S.scan.itemID ~= target.itemID or S.scan.query ~= target.query or S.scan.family ~= target.family) then
            ns.say(ns.T("tradeOtherScan"))
            return false
        end
        if not S.open then
            ns.say(ns.T("sayNoAuction"))
            return false
        end
        if GetTime() - S.pausedAt <= PAUSE_LIMIT then
            ns.Store.Log("resume page=" .. (S.page + 1) .. "/" .. S.pages)
            S.phase, S.nextAt, S.tries = "send", GetTime(), 0
            status("stPage", S.page + 1, tostring(math.max(S.pages, 1)))
            return true
        end
        if ns.Disenchant then ns.Disenchant.RestoreSort(S.scan) end
        S.phase, S.scan = "idle", nil
        ns.say(ns.T("sayStale"))
    end
    if S.phase ~= "idle" then
        ns.say(ns.T("sayBusy"))
        return false
    end
    if not S.open then
        ns.say(ns.T("sayNoAuction"))
        return false
    end
    local _, canMass = CanSendAuctionQuery("list")
    if mode == "all" and not canMass then
        status("stMassWait")
        ns.say(ns.T("sayMassWait"))
        return false
    end
    if mode == "all" and not ns.Query.Ready(true) then ns.say(ns.T("sayBusy")); return false end
    S.mode, S.scan, S.index, S.count = mode, ns.Store.Begin(mode), 1, 0
    if target then
        S.scan.scope, S.scan.itemID, S.scan.query = target.itemID and "item" or "query", target.itemID, ns.Query.Name(target.query)
        S.scan.family = target.family
        S.scan.classIndex, S.scan.subClassIndex = ns.Compat.AuctionFilter(target.itemID or target.family)
        if target.family then S.scan.scope = "family" end
        if target.scope == "disenchant" then
            S.scan.scope, S.scan.deGroup, S.scan.disenchantItems = "disenchant", target.deGroup, {}
            S.scan.classIndex, S.scan.minLevel, S.scan.maxLevel, S.scan.minQuality = target.classIndex,
                target.minLevel, target.maxLevel, target.minQuality
            S.scan.deOptions = target.deOptions
            S.scan.deTarget = ns.Disenchant.Group(target.deGroup).targetID
            ns.Disenchant.Prepare(S.scan)
        end
    end
    S.page, S.pages, S.expect, S.miss, S.retry = 0, 0, 0, 0, {}
    S.tries, S.rereads, S.shownSecs, S.startedAt = 0, 0, nil, GetTime()
    S.gap, S.errors, S.sig, S.stale = ns.Query.Gap(), 0, "", 0
    ns.Store.Log("start " .. mode .. " item=" .. tostring(S.scan.itemID or 0))
    if mode == "all" then
        sending = true
        ns.Query.Send("", nil, true)
        sending = false
        S.phase, S.sentAt = "wait", GetTime()
        status("stAllWait")
    else
        S.phase, S.nextAt = "send", 0
        status("stPage", 1, "?")
    end
    return true
end
function Scan.OnListUpdate()
    if S.phase ~= "wait" and S.phase ~= "settle" then return end
    local now = GetTime()
    ns.Store.Log("event page=" .. (S.page + 1) .. " response=" .. string.format("%.2f", now - S.sentAt))
    S.phase, S.readAt = "settle", now + SETTLE
end
function Scan.OnUpdate(elapsed)
    local phase = S.phase
    if phase == "idle" or phase == "paused" then return end
    local now = GetTime()
    if phase == "send" then
        if cooling() <= 0 and now >= S.nextAt and ns.Query.Ready() then send() end
    elseif phase == "settle" then
        if now < S.readAt then return end
        if S.mode == "pages" then return readPage(now) end
        local batch, total = GetNumAuctionItems("list")
        S.count, S.expect, S.index, S.phase = batch or 0, total or 0, 1, "read"
        status("stRead", 0, S.count)
    elseif phase == "read" then
        readChunk(now)
    elseif phase == "reread" then
        if now >= S.readAt then reread(now) end
    elseif phase == "wait" then
        local waited = now - S.sentAt
        if S.mode == "pages" then
            if waited <= PAGE_TIMEOUT then return end
            ns.Store.Log("no response page=" .. (S.page + 1) .. " wait=" .. math.floor(waited))
            return pause("sayNoAnswer")
        elseif waited > ALL_TIMEOUT then
            fail("stAllTimeout")
        else
            local secs = math.floor(waited)
            if secs ~= S.shownSecs then
                S.shownSecs = secs
                status("stAllWaitSecs", secs, ALL_TIMEOUT)
            end
        end
    end
end
function Scan.Stop()
    if S.phase == "idle" then return false end
    fail("stStopped")
    return true
end
function Scan.ResetPace(silent)
    if S.phase ~= "idle" or (ns.Buy and ns.Buy.Active()) then ns.say(ns.T("sayBusy")); return false end
    if cooling() > 0 then ns.say(ns.T("tradeCooling", math.ceil(cooling()))); return false end
    ns.Store.DB().scanGap = nil
    S.gap = ns.Query.Gap()
    ns.Store.Log("pace reset gap=" .. S.gap)
    if not silent then ns.say(ns.T("sayPace", S.gap)) end
    return true
end
function Scan.OnAfk()
    if not UnitIsAFK("player") or S.mode ~= "pages" then return end
    if S.phase == "idle" or S.phase == "paused" then return end
    pause("sayAfk")
end
function Scan.OnMessage(event, text)
    if S.phase == "idle" or not text then return end
    ns.Store.Log(event .. " page=" .. (S.page + 1) .. "/" .. S.pages .. " t=" .. math.floor(GetTime() - S.startedAt) .. " " .. text)
    if event ~= "UI_ERROR_MESSAGE" or text ~= ERR_AUCTION_DATABASE_ERROR then return end
    if S.mode == "pages" and S.phase ~= "paused" then refused(GetTime(), "error") end
end
function Scan.Save()
    local db = ns.Store.DB()
    db.pending = nil
    if S.phase == "idle" or S.mode ~= "pages" or not S.scan then return end
    local now = GetTime()
    local idle = S.phase == "paused" and math.floor(now - S.pausedAt) or 0
    db.pending = {
        scan = S.scan, page = S.page, pages = S.pages, expect = S.expect, miss = S.miss,
        at = time() - idle, ran = math.floor(now - S.startedAt),
    }
    ns.Store.Log("saved page=" .. (S.page + 1) .. "/" .. S.pages .. " lots=" .. #S.scan.lots)
end
function Scan.Restore()
    local db = ns.Store.DB()
    local p = db.pending
    db.pending = nil
    if type(p) ~= "table" or type(p.scan) ~= "table" or type(p.scan.lots) ~= "table" then return end
    local age = time() - (p.at or 0)
    if age > PAUSE_LIMIT then
        ns.Store.Log("pending stale age=" .. age)
        return
    end
    local now = GetTime()
    S.mode, S.scan, S.page, S.pages = "pages", p.scan, p.page or 0, p.pages or 0
    S.expect, S.miss, S.retry, S.tries, S.rereads = p.expect or 0, p.miss or 0, {}, 0, 0
    S.gap, S.errors = ns.Query.Gap(), 0
    S.phase, S.pausedAt, S.startedAt = "paused", now - age, now - (p.ran or 0)
    ns.Store.Log("restored page=" .. (S.page + 1) .. "/" .. S.pages .. " lots=" .. #S.scan.lots)
    ns.say(ns.T("sayRestored", S.page + 1, math.max(S.pages, 1)))
end
function Scan.OnShow()
    S.open = true
end
function Scan.OnClose()
    S.open = false
    if S.phase == "idle" or S.phase == "paused" then return end
    Scan.Trace("AUCTION_HOUSE_CLOSED")
    if S.mode == "pages" then return pause("sayClosed") end
    fail("stClosed")
end
