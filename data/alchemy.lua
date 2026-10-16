local _, ns = ...
ns.vendorPrices = {[18256] = 4000, [40411] = 10000, [38426] = 30000}
ns.alchemyRecipes = {
    {raw = 46376, spell = 53901, count = 2, category = "alchemyFlasks",
        inputs = {{36908, 1}, {36905, 5}, {36906, 5}, {40411, 1}}},
    {raw = 46377, spell = 53903, count = 2, category = "alchemyFlasks",
        inputs = {{36908, 1}, {36905, 7}, {36901, 3}, {40411, 1}}},
    {raw = 46379, spell = 53902, count = 2, category = "alchemyFlasks",
        inputs = {{36908, 1}, {36905, 7}, {37704, 3}, {40411, 1}}},
    {raw = 46378, spell = 54213, count = 2, category = "alchemyFlasks",
        inputs = {{36908, 1}, {36906, 7}, {40195, 3}, {40411, 1}}},
    {raw = 40211, spell = 54221, count = 1, category = "alchemyPotions",
        inputs = {{36903, 2}, {40195, 1}, {18256, 1}}},
    {raw = 40212, spell = 54222, count = 1, category = "alchemyPotions",
        inputs = {{36905, 2}, {40195, 1}, {18256, 1}}},
    {raw = 33448, spell = 53837, count = 1, category = "alchemyPotions",
        inputs = {{36905, 2}, {36901, 1}, {18256, 1}}},
    {raw = 33447, spell = 53836, count = 1, category = "alchemyPotions",
        inputs = {{36906, 2}, {36901, 1}, {18256, 1}}},
    {raw = 44331, spell = 60366, count = 1, category = "alchemyElixirs",
        inputs = {{37704, 1}, {37921, 1}, {18256, 1}}},
    {raw = 44330, spell = 60365, count = 1, category = "alchemyElixirs",
        inputs = {{36904, 2}, {18256, 1}}},
}
ns.alchemyByItem = {}
ns.alchemyItems = {}
for _, recipe in ipairs(ns.alchemyRecipes) do
    ns.alchemyByItem[recipe.raw] = recipe
    ns.alchemyItems[recipe.raw] = true
    for _, input in ipairs(recipe.inputs) do ns.alchemyItems[input[1]] = true end
end
