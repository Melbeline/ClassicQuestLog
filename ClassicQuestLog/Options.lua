-- ClassicQuestLog - its page in the game's options (Esc > Options > AddOns > ClassicQuestLog): the double pane (on by
-- default, as the window's own radio), its first size and place back, what opens it.

local ADDON, ns = ...
local Q = ns
local L = ns.L

local page = CreateFrame("Frame")
page:Hide()
page.name = "ClassicQuestLog"

local title = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("ClassicQuestLog")
local about = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
about:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
about:SetPoint("RIGHT", page, "RIGHT", -16, 0)
about:SetJustifyH("LEFT")
about:SetWordWrap(true)
about:SetText(L.ABOUT)

local dual = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
dual:SetPoint("TOPLEFT", about, "BOTTOMLEFT", -2, -14)
local dualText = dual.Text or dual.text
if dualText then dualText:SetText(L.QL_SW_DUAL) end
dual:SetScript("OnClick", function(self)
  local on = self:GetChecked() and true or false
  PlaySound(on and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
  Q.Store().dual = on
  if Q.SetDual then Q.SetDual(on) end
end)

local reset = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
reset:SetSize(220, 24)
reset:SetPoint("TOPLEFT", dual, "BOTTOMLEFT", 2, -12)
reset:SetText(L.RESET_PLACE)
reset:SetScript("OnClick", function() if Q.ResetPlace then Q.ResetPlace() end end)

local hint = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
hint:SetPoint("TOPLEFT", reset, "BOTTOMLEFT", 0, -14)
hint:SetPoint("RIGHT", page, "RIGHT", -16, 0)
hint:SetJustifyH("LEFT")
hint:SetWordWrap(true)
hint:SetTextColor(.7, .7, .75)
hint:SetText(L.HINT)

local claras = page:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
claras:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -14)
claras:SetPoint("RIGHT", page, "RIGHT", -16, 0)
claras:SetJustifyH("LEFT")
claras:SetWordWrap(true)

function Q.RefreshOptions()
  dual:SetChecked(Q.IsDual())
  claras:SetText(Q.off and L.CLARA or "")
end
page:SetScript("OnShow", Q.RefreshOptions)

local category
if Settings and Settings.RegisterCanvasLayoutCategory then
  category = Settings.RegisterCanvasLayoutCategory(page, "ClassicQuestLog")
  if category and Settings.RegisterAddOnCategory then Settings.RegisterAddOnCategory(category) end
end
Q.optionsPage, Q.optionsDual, Q.optionsReset = page, dual, reset -- (for the tests)

function Q.OpenOptions()
  if InCombatLockdown() or not (category and Settings and Settings.OpenToCategory) then return end
  Settings.OpenToCategory(category.GetID and category:GetID() or category)
end
