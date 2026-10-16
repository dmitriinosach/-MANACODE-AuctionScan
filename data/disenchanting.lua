local _, ns = ...
ns.disenchantBands = {
    {key = "bcRareLow", expansion = "bc", kind = "any", quality = 3,
        minLevel = 66, maxLevel = 99, skill = 225, lootId = 50, outputs = {
            {itemID = 22448, chance = 0.995, minCount = 1, maxCount = 1},
            {itemID = 20725, chance = 0.005, minCount = 1, maxCount = 1},
        }},
    {key = "bcRareHigh", expansion = "bc", kind = "any", quality = 3,
        minLevel = 100, maxLevel = 120, skill = 275, lootId = 52, outputs = {
            {itemID = 22449, chance = 0.995, minCount = 1, maxCount = 1},
            {itemID = 22450, chance = 0.005, minCount = 1, maxCount = 1},
        }},
    {key = "wrathRareLow", expansion = "wrath", kind = "any", quality = 3,
        minLevel = 121, maxLevel = 164, skill = 325, lootId = 53, outputs = {
            {itemID = 34053, chance = 0.995, minCount = 1, maxCount = 1},
            {itemID = 34057, chance = 0.005, minCount = 1, maxCount = 1},
        }},
    {key = "wrathRareHigh", expansion = "wrath", kind = "any", quality = 3,
        minLevel = 165, maxLevel = 284, skill = 325, lootId = 54, outputs = {
            {itemID = 34052, chance = 0.995, minCount = 1, maxCount = 1},
            {itemID = 34057, chance = 0.005, minCount = 1, maxCount = 1},
        }},
    {key = "bcEpic", expansion = "bc", kind = "any", quality = 4,
        minLevel = 95, maxLevel = 164, skill = 300, lootId = 66, outputs = {
            {itemID = 22450, chance = 1, minCount = 1, maxCount = 2},
        }},
    {key = "wrathEpic", expansion = "wrath", kind = "any", quality = 4,
        minLevel = 165, maxLevel = 284, skill = 375, lootId = 68, outputs = {
            {itemID = 34057, chance = 1, minCount = 1, maxCount = 1},
        }},
    {key = "bcArmorLow", expansion = "bc", kind = "armor", minLevel = 66, maxLevel = 80,
        skill = 225, lootId = 12, outputs = {
            {itemID = 22445, chance = 0.75, minCount = 1, maxCount = 3},
            {itemID = 22447, chance = 0.22, minCount = 1, maxCount = 3},
            {itemID = 22448, chance = 0.03, minCount = 1, maxCount = 1},
        }},
    {key = "bcArmorMiddle", expansion = "bc", kind = "armor", minLevel = 81, maxLevel = 99,
        skill = 225, lootId = 13, outputs = {
            {itemID = 22445, chance = 0.75, minCount = 2, maxCount = 3},
            {itemID = 22447, chance = 0.22, minCount = 2, maxCount = 3},
            {itemID = 22448, chance = 0.03, minCount = 1, maxCount = 1},
        }},
    {key = "bcArmorHigh", expansion = "bc", kind = "armor", minLevel = 100, maxLevel = 120,
        skill = 275, lootId = 14, outputs = {
            {itemID = 22445, chance = 0.75, minCount = 2, maxCount = 5},
            {itemID = 22446, chance = 0.22, minCount = 1, maxCount = 2},
            {itemID = 22449, chance = 0.03, minCount = 1, maxCount = 1},
        }},
    {key = "bcWeaponLow", expansion = "bc", kind = "weapon", minLevel = 66, maxLevel = 80,
        skill = 225, lootId = 32, outputs = {
            {itemID = 22445, chance = 0.22, minCount = 2, maxCount = 3},
            {itemID = 22447, chance = 0.75, minCount = 2, maxCount = 3},
            {itemID = 22448, chance = 0.03, minCount = 1, maxCount = 1},
        }},
    {key = "bcWeaponMiddle", expansion = "bc", kind = "weapon", minLevel = 81, maxLevel = 99,
        skill = 225, lootId = 32, outputs = {
            {itemID = 22445, chance = 0.22, minCount = 2, maxCount = 3},
            {itemID = 22447, chance = 0.75, minCount = 2, maxCount = 3},
            {itemID = 22448, chance = 0.03, minCount = 1, maxCount = 1},
        }},
    {key = "bcWeaponHigh", expansion = "bc", kind = "weapon", minLevel = 100, maxLevel = 120,
        skill = 275, lootId = 33, outputs = {
            {itemID = 22445, chance = 0.22, minCount = 2, maxCount = 5},
            {itemID = 22446, chance = 0.75, minCount = 1, maxCount = 2},
            {itemID = 22449, chance = 0.03, minCount = 1, maxCount = 1},
        }},
    {key = "wrathArmorLow", expansion = "wrath", kind = "armor", minLevel = 121, maxLevel = 151,
        skill = 325, lootId = 15, outputs = {
            {itemID = 34054, chance = 0.75, minCount = 1, maxCount = 3},
            {itemID = 34056, chance = 0.22, minCount = 1, maxCount = 2},
            {itemID = 34053, chance = 0.03, minCount = 1, maxCount = 1},
        }},
    {key = "wrathArmorHigh", expansion = "wrath", kind = "armor", minLevel = 152, maxLevel = 200,
        skill = 350, lootId = 16, outputs = {
            {itemID = 34054, chance = 0.75, minCount = 4, maxCount = 7},
            {itemID = 34055, chance = 0.22, minCount = 1, maxCount = 2},
            {itemID = 34052, chance = 0.03, minCount = 1, maxCount = 1},
        }},
    {key = "wrathWeaponLow", expansion = "wrath", kind = "weapon", minLevel = 121, maxLevel = 151,
        skill = 325, lootId = 34, outputs = {
            {itemID = 34054, chance = 0.22, minCount = 1, maxCount = 3},
            {itemID = 34056, chance = 0.75, minCount = 1, maxCount = 2},
            {itemID = 34053, chance = 0.03, minCount = 1, maxCount = 1},
        }},
    {key = "wrathWeaponHigh", expansion = "wrath", kind = "weapon", minLevel = 152, maxLevel = 200,
        skill = 350, lootId = 35, outputs = {
            {itemID = 34054, chance = 0.22, minCount = 4, maxCount = 7},
            {itemID = 34055, chance = 0.75, minCount = 1, maxCount = 2},
            {itemID = 34052, chance = 0.03, minCount = 1, maxCount = 1},
        }},
}
ns.disenchantMaterials = {20725, 22445, 22446, 22447, 22448, 22449, 22450, 34052, 34053, 34054, 34055, 34056, 34057}
ns.disenchantOverrides = {
    [25084] = {kind = "weapon", skill = 275, lootId = 33},
    [25099] = {kind = "weapon", skill = 275, lootId = 33},
    [36450] = {kind = "weapon", skill = 325, lootId = 34},
    [36460] = {kind = "weapon", skill = 325, lootId = 34},
    [36468] = {kind = "weapon", skill = 350, lootId = 35},
}
ns.disenchantMetadata = {
    model = "wotlk-335",
    qualities = {2, 3, 4},
    circleVerified = false,
    source = "azerothcore/azerothcore-wotlk",
    lootRevision = "4d9d1d4b5723e819c5c390f6ca1177283dbfb8e3",
    genericEligibilityVerified = false,
    genericMinimumLevelVerified = 81,
    wrathMinimumObservedLevel = 130,
}
