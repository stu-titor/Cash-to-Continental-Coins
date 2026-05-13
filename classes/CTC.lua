CTC = {}

-- How many spending cash each Continental Coin costs
CTC.coinCost = 1000000

-- Coin amounts the player can buy at once
CTC.options = {
    {text = "1 Coin  ($1,000,000)",    amount = 1},
    {text = "2 Coins ($2,000,000)",    amount = 2},
    {text = "5 Coins ($5,000,000)",    amount = 5},
    {text = "10 Coins ($10,000,000)",  amount = 10},
    {text = "25 Coins ($25,000,000)",  amount = 25},
    {text = "50 Coins ($50,000,000)",  amount = 50},
    {text = "100 Coins ($100,000,000)", amount = 100},
    {text = "200 Coins ($200,000,000)", amount = 200},
    {text = "500 Coins ($500,000,000)", amount = 500},
}

CTC.menu = CustomMenuClass:new({
    panelGaps  = 0,
    hasLoading = false,
    hasBorder  = false,
})

CTC.menuLoaded = false

-- ── Helpers ──────────────────────────────────────────────────────────────────

function CTC.getSpending()
    return managers.money:total() or 0
end

function CTC.getCoins()
    if managers.custom_safehouse then
        return math.floor(managers.custom_safehouse:coins()) or 0
    end
    return 0
end

function CTC.costForAmount(amount)
    return amount * CTC.coinCost
end

function CTC.canAfford(amount)
    return CTC.getSpending() >= CTC.costForAmount(amount)
end

-- ── Conversion ───────────────────────────────────────────────────────────────

function CTC.convert(amount)
    if not CTC.canAfford(amount) then
        return
    end

    local cost = CTC.costForAmount(amount)

    -- Deduct spending cash
    managers.money:deduct_from_spending(cost)

    -- Award continental coins
    managers.custom_safehouse:add_coins(amount)

    -- Persist and refresh
    CTC.saveAndRefresh()
end

function CTC.saveAndRefresh()
    if managers.savefile then
        managers.savefile:save_progress()
    end
    if managers.menu_component then
        managers.menu_component:refresh_player_profile_gui()
    end
    CTC.loadMenu()
    CTC.menu:refreshMenu()
end

-- ── Menu ─────────────────────────────────────────────────────────────────────

function CTC.loadMenu()
    CTC.menu:addMainMenu("main_menu", {title = "Cash to Coins"})

    local spending = CTC.getSpending()
    local coins    = CTC.getCoins()

    
    -- Current balance info
    CTC.menu:addInformationOption("main_menu",
        "Spending Cash : $" .. string.format("%d", spending))
    CTC.menu:addInformationOption("main_menu",
        "Continental Coins : " .. tostring(coins))

    CTC.menu:addGap("main_menu")
    CTC.menu:addInformationOption("main_menu",
        "Rate : $" .. string.format("%d", CTC.coinCost) .. " per coin",
        {textColor = Color.yellow})
    CTC.menu:addGap("main_menu")

    -- One button per option; grey out if unaffordable
    for _, option in pairs(CTC.options) do
        local cost = CTC.costForAmount(option.amount)
        if spending >= cost then
            CTC.menu:addOption("main_menu", option.text, {
                help     = "Spend $" .. string.format("%d", cost) ..
                           " to receive " .. option.amount .. " Continental Coin(s).",
                callback     = CTC.convert,
                callbackData = option.amount,
            })
        else
            -- Show as red / unaffordable
            CTC.menu:addInformationOption("main_menu", option.text,
                {textColor = Color.red})
        end
    end

    CTC.menuLoaded = true
end
