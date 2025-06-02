--MyGoldOnServerLua
--by LQI
local addonName = ...
-- get metadata version addon
local version = GetAddOnMetadata(addonName, "Version")
-- init the local texts commands
local cmd = {"/goldstat"}
local cmdInfos = {"Ouvre l'addon."}

-- display in print console the addon informations
print(color("green",addonName) .. " v" .. version)
for i = #cmd, 1, -1 do
    print(" |-> " .. color("yellow",cmd[i]) .. " : " .. cmdInfos[i])
end

-- === Sauvegarde or perso ===
-- Création du cadre pour les événements
local frame = CreateFrame("Frame")

-- === Création de l'affichage flottant ===
local goldFrame = CreateFrame("Frame", "MyGoldDisplayFrame", UIParent)
goldFrame:SetSize(120, 20)
goldFrame:SetPoint("CENTER")
goldFrame:SetMovable(true)
goldFrame:EnableMouse(true)
goldFrame:RegisterForDrag("LeftButton")
goldFrame:SetScript("OnDragStart", goldFrame.StartMoving)
goldFrame:SetScript("OnDragStop", goldFrame.StopMovingOrSizing)

goldFrame.text = goldFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
goldFrame.text:SetPoint("CENTER")
-- Ombre portée noir : 
goldFrame.text:SetShadowColor(0, 0, 0, 1)
goldFrame.text:SetShadowOffset(1, -1)

-- Arrière-plan discret derrière le texte
goldFrame.bg = goldFrame:CreateTexture(nil, "BACKGROUND")
goldFrame.bg:SetColorTexture(0, 0, 0, 0.4)  -- noir transparent
goldFrame.bg:SetPoint("TOPLEFT", -2, 2)
goldFrame.bg:SetPoint("BOTTOMRIGHT", 2, -2)

-- Tooltip au survol
goldFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    GameTooltip:AddLine(addonName .. " " .. version, 1, 1, 1)
    GameTooltip:AddLine(" ")

    local realm = GetRealmName()
    local faction = UnitFactionGroup("player")
    if MyGoldOnServerDB[realm] and MyGoldOnServerDB[realm][faction] then
        GameTooltip:AddLine("Détail de l'or :")
        for name, gold in pairs(MyGoldOnServerDB[realm][faction]) do
            local g = floor(gold / 10000)
            local s = floor((gold % 10000) / 100)
            local c = gold % 100
            GameTooltip:AddDoubleLine(name, g.."|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t "..s.."|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "..c.."|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t")
        end
    else
        GameTooltip:AddLine("Aucune donnée.")
    end
    GameTooltip:Show()
end)

goldFrame:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- === refresh when there is a money modification on player ===
local function UpdatePlayerGold()
    local name = UnitName("player")
    local realm = GetRealmName()
    local faction = UnitFactionGroup("player")
    local gold = GetMoney()

    if not MyGoldOnServerDB then return end
    if not MyGoldOnServerDB[realm] or not MyGoldOnServerDB[realm][faction] then return end

    -- update only if different of
    if MyGoldOnServerDB[realm][faction][name] ~= gold then
        -- change the color when there is + or - money
        goldFrame.text:SetTextColor(1, 1, 0) -- yellow holy color
        C_Timer.After(0.5, function()
            goldFrame.text:SetTextColor(1, 0.82, 0) -- back to normaly color
        end)
        
        -- update the gold
        MyGoldOnServerDB[realm][faction][name] = gold
        UpdateGoldDisplay()
    end
end

-- === update the general display ===
function UpdateGoldDisplay()
    local realm = GetRealmName()
    local faction = UnitFactionGroup("player")
    local total = 0
    if MyGoldOnServerDB[realm] and MyGoldOnServerDB[realm][faction] then
        for _, gold in pairs(MyGoldOnServerDB[realm][faction]) do
            total = total + gold
        end
    end
    local g = floor(total / 10000)
    local s = floor((total % 10000) / 100)
    local c = total % 100
    goldFrame.text:SetText(g.."|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t "..s.."|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t "..c.."|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t")
end


-- initialisation Event
frame:RegisterEvent("PLAYER_MONEY")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if not MyGoldOnServerDB then MyGoldOnServerDB = {} end

        local name = UnitName("player")
        local realm = GetRealmName()
        local faction = UnitFactionGroup("player")
        local gold = GetMoney()

        MyGoldOnServerDB[realm] = MyGoldOnServerDB[realm] or {}
        MyGoldOnServerDB[realm][faction] = MyGoldOnServerDB[realm][faction] or {}
        MyGoldOnServerDB[realm][faction][name] = gold

        UpdateGoldDisplay()
    elseif event == "PLAYER_MONEY" then
        UpdatePlayerGold()
    end
end)

-- function for display/hide addon
SLASH_GOLDSERVERSHOW1 = cmd[1]
SlashCmdList["GOLDSERVERSHOW"] = function()
    if goldFrame:IsShown() then
        goldFrame:SetShown(false)
    else
        RefreshItemDisplay()
        goldFrame:SetShown(true)
    end
end
