local ADDON_NAME = ...
local HOLD_MODIFIER = "alt"
-- Page 6 is typically the least used default page and avoids conflicts with common setups.
local SAFE_PAGE = 6
local NORMAL_PAGE = 1

local frame = CreateFrame("Frame")
local pendingRegister = false
local stateTarget = nil
local warnedMissingTarget = false

local indicator = CreateFrame("Frame", nil, UIParent)
indicator:SetSize(180, 28)
indicator:SetPoint("TOP", UIParent, "TOP", 0, -120)

local indicatorBg = indicator:CreateTexture(nil, "BACKGROUND")
indicatorBg:SetAllPoints()
indicatorBg:SetColorTexture(0, 0, 0, 0.55)

local indicatorText = indicator:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
indicatorText:SetPoint("CENTER")

local function BuildDriverPattern()
	return string.format("[mod:alt] %d; %d", SAFE_PAGE, NORMAL_PAGE)
end

local function IsHoldModifierDown()
	return IsAltKeyDown()
end

local function UpdateIndicator()
	if IsHoldModifierDown() then
		indicatorText:SetText("SAFE: BAR " .. SAFE_PAGE)
		indicatorText:SetTextColor(1.0, 0.25, 0.25)
	else
		indicatorText:SetText("ARMED: NORMAL BAR")
		indicatorText:SetTextColor(0.25, 1.0, 0.25)
	end
end

local function RegisterPagingDriver()
	if InCombatLockdown() then
		pendingRegister = true
		return
	end

	local target = _G.ActionBarController or _G.MainMenuBarArtFrame or _G.MainMenuBar
	if not target then
		pendingRegister = true
		if not warnedMissingTarget then
			warnedMissingTarget = true
			print("|cffff5555WoWTicAssist|r no action bar state target found yet; will retry.")
		end
		return
	end

	warnedMissingTarget = false
	pendingRegister = false

	if stateTarget and stateTarget ~= target then
		UnregisterStateDriver(stateTarget, "page")
		UnregisterStateDriver(stateTarget, "actionpage")
	end

	UnregisterStateDriver(target, "page")
	UnregisterStateDriver(target, "actionpage")
	RegisterStateDriver(target, "page", BuildDriverPattern())
	RegisterStateDriver(target, "actionpage", BuildDriverPattern())
	stateTarget = target
end

frame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		RegisterPagingDriver()
		frame:SetScript("OnUpdate", UpdateIndicator)
		if stateTarget and stateTarget.GetName and stateTarget:GetName() then
			print("|cff33ff99WoWTicAssist|r loaded on " .. stateTarget:GetName() .. ": hold " .. HOLD_MODIFIER:upper() .. " to switch to action bar page " .. SAFE_PAGE .. ".")
		else
			print("|cff33ff99WoWTicAssist|r loaded: hold " .. HOLD_MODIFIER:upper() .. " to switch to action bar page " .. SAFE_PAGE .. ".")
		end
	elseif event == "PLAYER_REGEN_ENABLED" and pendingRegister then
		RegisterPagingDriver()
	elseif event == "MODIFIER_STATE_CHANGED" then
		if not InCombatLockdown() then
			if IsHoldModifierDown() then
				ChangeActionBarPage(SAFE_PAGE)
			else
				ChangeActionBarPage(NORMAL_PAGE)
			end
		end
	end
end)

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("MODIFIER_STATE_CHANGED")
