-- ClassicQuestLog - the 1.x quest log (ClassicUI Forever's, as in Clara Combo Points) on the game's quest API, or the
-- 3.x double pane (on by default), opened by the quest log key and the quest log micro button in place of the map's
-- quest panel. This file: its shared table, its art (Era's own sheets, bundled: the client's are near-black stand-ins),
-- the unseen pads over buttons, the scroll bars and reward slots, the log's data and its Share Quest.

local ADDON, ns = ...
local L = ns.L
local Q = ns

-- Its settings (ClassicQuestLogDB, for the account): the window's place and size, the double pane
function Q.Store()
  if type(ClassicQuestLogDB) ~= "table" then ClassicQuestLogDB = {} end
  return ClassicQuestLogDB
end
-- The double pane: on unless turned off
function Q.IsDual() return Q.Store().dual ~= false end

local issecret = issecretvalue or function() return false end
function Q.IsSecret(v) return issecret(v) end
function Q.Safe(v, fallback)
  if v == nil or issecret(v) then return fallback end
  return v
end

function Q.SayNotInCombat()
  if UIErrorsFrame and ERR_NOT_IN_COMBAT then UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1, 0.1, 0.1) end
end

---------------------------------------------------------------------------
-- Art
---------------------------------------------------------------------------
local MEDIA = "Interface\\AddOns\\ClassicQuestLog\\media\\"
local TEX = {
  questLogTopLeft = "UI-QuestLog-TopLeft", questLogTopRight = "UI-QuestLog-TopRight",
  questLogBotLeft = "UI-QuestLog-BotLeft", questLogBotRight = "UI-QuestLog-BotRight",
  questLogDualLeft = "UI-QuestLogDualPane-Left", questLogDualRight = "UI-QuestLogDualPane-Right",
  questLogEmptyTopLeft = "UI-QuestLog-Empty-TopLeft", questLogEmptyTopRight = "UI-QuestLog-Empty-TopRight",
  questLogEmptyBotLeft = "UI-QuestLog-Empty-BotLeft", questLogEmptyBotRight = "UI-QuestLog-Empty-BotRight",
  questLogBook = "UI-QuestLog-BookIcon",
  questLogTabLeft = "UI-QuestLogSortTab-Left", questLogTabMiddle = "UI-QuestLogSortTab-Middle",
  questLogTabRight = "UI-QuestLogSortTab-Right",
  questLogHighlight = "UI-QuestLogTitleHighlight",
  lootNameFrame = "UI-QuestItemNameFrame",
  scrollKnob = "UI-ScrollBar-Knob",
  scrollUpButtonUp = "UI-ScrollBar-ScrollUpButton-Up", scrollUpButtonDown = "UI-ScrollBar-ScrollUpButton-Down",
  scrollUpButtonDisabled = "UI-ScrollBar-ScrollUpButton-Disabled",
  scrollUpButtonHighlight = "UI-ScrollBar-ScrollUpButton-Highlight",
  scrollDownButtonUp = "UI-ScrollBar-ScrollDownButton-Up", scrollDownButtonDown = "UI-ScrollBar-ScrollDownButton-Down",
  scrollDownButtonDisabled = "UI-ScrollBar-ScrollDownButton-Disabled",
  scrollDownButtonHighlight = "UI-ScrollBar-ScrollDownButton-Highlight",
}
Q.ART = {
  CHECK = "Interface\\Buttons\\UI-CheckBox-",
  PLUS = "Interface\\Buttons\\UI-PlusButton-Up",
  MINUS = "Interface\\Buttons\\UI-MinusButton-Up",
  PLUS_GLOW = "Interface\\Buttons\\UI-PlusButton-Hilight",
}

-- A key's file: one of the bundled sheets, else the path as given (the game's own)
function Q.TexPath(key)
  local file = TEX[key]
  return file and (MEDIA .. file) or key
end
function Q.SetTex(texture, key) return texture:SetTexture(Q.TexPath(key)) end

function Q.SetPointOnce(region, point, rel, relPoint, x, y)
  region:ClearAllPoints()
  region:SetPoint(point, rel, relPoint, x or 0, y or 0)
end

-- Textures from specs: { key, layer, sublevel, w, h, point, relPoint, x, y, coords, chain (from the piece before) }
function Q.Pieces(parent, specs)
  local made, last = {}, nil
  for _, spec in ipairs(specs) do
    local tex = parent:CreateTexture(nil, spec.layer or "ARTWORK", nil, spec.sublevel)
    tex:SetTexture(Q.TexPath(spec.key))
    if spec.coords then tex:SetTexCoord(unpack(spec.coords)) end
    tex:SetSize(spec.w, spec.h)
    local rel = (spec.chain and last) or parent
    tex:SetPoint(spec.point or "TOPLEFT", rel, spec.relPoint or spec.point or "TOPLEFT", spec.x or 0, spec.y or 0)
    made[#made + 1] = tex
    last = tex
  end
  return made
end

function Q.SetCollapseIcon(tex, collapsed) tex:SetTexture(collapsed and Q.ART.PLUS or Q.ART.MINUS) end

-- 1.x quest difficulty colours; the client's gold yellow reads orange on the old art
local QUEST_COLOURS = {
  impossible = { 1, 0.1, 0.1 }, verydifficult = { 1, 0.5, 0.25 }, difficult = { 1, 0.92, 0 },
  standard = { 0.25, 0.75, 0.25 }, trivial = { 0.5, 0.5, 0.5 },
}
function Q.QuestYellow()
  local c = QUEST_COLOURS.difficult
  return c[1], c[2], c[3]
end
function Q.QuestLevelColor(level)
  level = tonumber(level) or 0
  local player = UnitLevel("player") or 1
  local diff = level - player
  local key
  if level <= 0 then
    key = "difficult"
  elseif diff >= 5 then
    key = "impossible"
  elseif diff >= 3 then
    key = "verydifficult"
  elseif diff >= -2 then
    key = "difficult"
  else
    local range = 5
    if UnitQuestTrivialLevelRange then
      local ok, r = pcall(UnitQuestTrivialLevelRange, "player")
      if ok and tonumber(r) then range = r end
    elseif GetQuestGreenRange then
      local ok, r = pcall(GetQuestGreenRange)
      if ok and tonumber(r) then range = r end
    end
    key = (-diff <= range) and "standard" or "trivial"
  end
  local c = QUEST_COLOURS[key]
  return c[1], c[2], c[3]
end

-- Money as text with its coins (the game's own)
function Q.CoinText(copper)
  copper = tonumber(copper) or 0
  if GetMoneyString then return GetMoneyString(copper) end
  if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then return C_CurrencyInfo.GetCoinTextureString(copper) end
  return tostring(copper)
end

---------------------------------------------------------------------------
-- Work put off to the next frame, once however many times asked
---------------------------------------------------------------------------
local soon = {}
function Q.Soon(name, fn)
  if soon[name] then return end
  soon[name] = true
  C_Timer.After(0, function()
    soon[name] = nil
    fn()
  end)
end

function Q.RegisterEvents(frame, list)
  for _, event in ipairs(list) do pcall(frame.RegisterEvent, frame, event) end
end

function Q.SetAttributeIf(frame, name, value)
  if frame:GetAttribute(name) ~= value then frame:SetAttribute(name, value) end
end

---------------------------------------------------------------------------
-- Pads: an unseen button over one of ours (or over the game's micro button), hung from UIParent and placed by measure
-- (never anchored to the button: no anchor tie between our frames and the game's), looked at again every fifth of a
-- second while its button shows. A secure one presses a game button or runs a macro for the player (made and placed
-- out of combat; a window's hides as a fight starts); a plain one takes the click for our own code.
---------------------------------------------------------------------------
local pads = {}
local padTicker
local function PlaceAll()
  for _, place in ipairs(pads) do pcall(place) end
end

-- opts: secure (with target: a button to click, or macro: function giving the text now, nil: no pad); after(): ours
-- after the press; when(): wanted now; strata; onClick (plain pads)
function Q.Pad(button, opts)
  if not button then return end
  opts = opts or {}
  if opts.secure and InCombatLockdown() then
    local wait = CreateFrame("Frame")
    wait:RegisterEvent("PLAYER_REGEN_ENABLED")
    wait:SetScript("OnEvent", function(self) self:UnregisterAllEvents() Q.Pad(button, opts) end)
    return
  end
  local pad
  if opts.secure then
    pad = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
    if opts.macro then
      pad:SetAttribute("type", "macro")
      pad:SetAttribute("macrotext", "")
    else
      pad:SetAttribute("type", "click")
      pad:SetAttribute("clickbutton", opts.target)
    end
    pad:SetAttribute("useOnKeyDown", false)
    pad:RegisterForClicks("AnyUp", "AnyDown")
  else
    pad = CreateFrame("Button", nil, UIParent)
    pad:RegisterForClicks("AnyUp")
    pad:SetScript("OnClick", function(_, mouse) if opts.onClick then opts.onClick(mouse) end end)
  end
  pad:SetFrameStrata(opts.strata or button:GetFrameStrata() or "MEDIUM")
  pad:Hide()
  -- The button under it shows the press and its glow, its tooltip (a game button's: ours, its own script left alone)
  pad:SetScript("OnMouseDown", function() button:SetButtonState("PUSHED") end)
  pad:SetScript("OnMouseUp", function() button:SetButtonState("NORMAL") end)
  pad:SetScript("OnEnter", function()
    button:LockHighlight()
    if opts.enter then return opts.enter(pad) end
    local enter = button:GetScript("OnEnter")
    if enter then pcall(enter, button) end
  end)
  pad:SetScript("OnLeave", function()
    button:UnlockHighlight()
    if opts.leave then opts.leave(pad) else
      local leave = button:GetScript("OnLeave")
      if leave then pcall(leave, button) end
    end
    if GameTooltip:IsOwned(button) or GameTooltip:IsOwned(pad) then GameTooltip:Hide() end
  end)
  local function Hide() if pad:IsShown() then pad:Hide() end end
  local function Place()
    if opts.secure and InCombatLockdown() then return end
    local left, bottom = button:GetLeft(), button:GetBottom()
    if not button:IsVisible() or not left or not bottom or issecret(left) or issecret(bottom)
      or (opts.when and not opts.when()) then
      Hide()
      return
    end
    if opts.secure and opts.macro then
      local text = opts.macro()
      if not text then Hide() return end
      Q.SetAttributeIf(pad, "macrotext", text)
    end
    local ratio = button:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local x, y, w, h = left * ratio, bottom * ratio, button:GetWidth() * ratio, button:GetHeight() * ratio
    if not pad:IsShown() or math.abs((pad.x or -1) - x) > 0.5 or math.abs((pad.y or -1) - y) > 0.5
      or math.abs((pad.w or -1) - w) > 0.5 or pad:GetFrameLevel() <= button:GetFrameLevel()
      or (not opts.strata and pad:GetFrameStrata() ~= button:GetFrameStrata()) then
      pad.x, pad.y, pad.w = x, y, w
      pad:ClearAllPoints()
      pad:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
      pad:SetSize(w, h)
      if not opts.strata then pad:SetFrameStrata(button:GetFrameStrata()) end
      pad:SetFrameLevel(button:GetFrameLevel() + 5)
      pad:Show()
    end
  end
  if opts.secure then
    pad:SetScript("PostClick", function(_, _, down)
      if down then return end
      if opts.after then opts.after() end
      Place()
    end)
    -- A window's pad goes as a fight starts (a window shut mid-fight would leave it, unseen, pressing on world clicks)
    local guard = CreateFrame("Frame")
    guard:RegisterEvent("PLAYER_REGEN_DISABLED")
    guard:SetScript("OnEvent", Hide)
  end
  pads[#pads + 1] = Place
  if not padTicker then padTicker = C_Timer.NewTicker(0.2, PlaceAll) end
  Place()
  return pad
end
Q.PlacePads = PlaceAll

-- A named secure button a pad's macro runs with /click, pressing its clickbutton; sized and placed off screen (a
-- button with neither is never clicked). Made out of combat.
function Q.ClickProxy(name)
  local proxy = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
  proxy:SetSize(1, 1)
  proxy:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -500, 500)
  proxy:EnableMouse(false)
  proxy:RegisterForClicks("AnyUp", "AnyDown")
  proxy:SetAttribute("useOnKeyDown", false)
  proxy:SetAttribute("type", "click")
  return proxy
end

---------------------------------------------------------------------------
-- Old scroll bars: a slider with the old knob and arrows
---------------------------------------------------------------------------
local KNOB_COORDS = { 0.2, 0.8, 0.125, 0.875 }
local ARROW_COORDS = { 0.25, 0.75, 0.25, 0.75 }
function Q.ScrollBar(parent, anchorTo, onValue)
  local bar = CreateFrame("Slider", nil, parent)
  bar:SetOrientation("VERTICAL")
  bar:SetWidth(16)
  bar:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 6, -16)
  bar:SetPoint("BOTTOMLEFT", anchorTo, "BOTTOMRIGHT", 6, 16)
  local knob = bar:CreateTexture(nil, "ARTWORK")
  Q.SetTex(knob, "scrollKnob")
  knob:SetTexCoord(unpack(KNOB_COORDS))
  knob:SetSize(18, 24)
  bar:SetThumbTexture(knob)
  bar:SetValueStep(1)
  bar:SetObeyStepOnDrag(true)
  bar:SetMinMaxValues(0, 0)
  bar:SetValue(0)
  local function Arrow(kind, point, relPoint)
    local button = CreateFrame("Button", nil, bar)
    button:SetSize(16, 16)
    button:SetPoint(point, bar, relPoint, 0, 0)
    local key = "scroll" .. kind .. "Button"
    for _, part in ipairs({ { "SetNormalTexture", "Up" }, { "SetPushedTexture", "Down" },
      { "SetDisabledTexture", "Disabled" }, { "SetHighlightTexture", "Highlight" } }) do
      button[part[1]](button, Q.TexPath(key .. part[2]))
    end
    for _, get in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
      local tex = button[get] and button[get](button)
      if tex then tex:SetTexCoord(unpack(ARROW_COORDS)) end
    end
    local glow = button:GetHighlightTexture()
    if glow then glow:SetBlendMode("ADD") end
    return button
  end
  bar.up = Arrow("Up", "BOTTOM", "TOP")
  bar.down = Arrow("Down", "TOP", "BOTTOM")
  bar.step = 1
  bar.up:SetScript("OnClick", function() bar:SetValue(bar:GetValue() - bar.step) PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON) end)
  bar.down:SetScript("OnClick", function() bar:SetValue(bar:GetValue() + bar.step) PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON) end)
  function bar:SetRange(max, step)
    self.step = step or 1
    max = math.max(0, max)
    local value = self:GetValue()
    self:SetMinMaxValues(0, max)
    self:SetValue(math.min(value, max))
    local thumb = self:GetThumbTexture()
    if thumb then thumb:SetShown(max > 0) end
    self:Refresh()
  end
  function bar:Refresh()
    local _, max = self:GetMinMaxValues()
    local value = self:GetValue()
    self.up:SetEnabled(value > 0)
    self.down:SetEnabled(value < max)
  end
  bar:SetScript("OnValueChanged", function(self, value)
    self:Refresh()
    onValue(value)
  end)
  return bar
end

-- The 1.x reward button at its own 147x41: the item's icon, its count, its name on the name frame
function Q.RewardSlot(parent, onEnter, onClick)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(147, 41)
  button.icon = button:CreateTexture(nil, "BACKGROUND")
  button.icon:SetSize(39, 39)
  button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
  button.nameBox = button:CreateTexture(nil, "BACKGROUND", nil, 1)
  Q.SetTex(button.nameBox, "lootNameFrame")
  button.nameBox:SetSize(128, 64)
  button.nameBox:SetPoint("LEFT", button.icon, "RIGHT", -10, 0)
  button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  button.count:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", -1, 1)
  button.name = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  button.name:SetSize(90, 36)
  button.name:SetPoint("LEFT", button.nameBox, "LEFT", 15, 0)
  button.name:SetJustifyH("LEFT")
  button.name:SetWordWrap(true)
  button.name:SetMaxLines(3)
  button:SetScript("OnEnter", onEnter)
  button:SetScript("OnLeave", function() GameTooltip:Hide() end)
  button:SetScript("OnClick", onClick)
  return button
end

---------------------------------------------------------------------------
-- The log's data
---------------------------------------------------------------------------
local QL = {}
Q.QL = QL
local EMPTY = {}

local entries = {}       -- visible headers and quests, in log order
local collapsed = {}     -- header key -> true while shut in our list

local function HeaderKey(info)
  return info.headerSortKey or info.title or info.questLogIndex
end

-- Count read again each pass: ExpandQuestHeader grows the log mid-walk
function QL.CollectEntries()
  wipe(entries)
  local skipping = false
  local i = 1
  while i <= (C_QuestLog.GetNumQuestLogEntries() or 0) do
    local info = C_QuestLog.GetInfo(i)
    if info and info.isHeader then
      -- A header the game has shut hides its quests: opened, shut in our list instead
      if info.isCollapsed and ExpandQuestHeader then ExpandQuestHeader(info.questLogIndex) end
      skipping = collapsed[HeaderKey(info)] == true
      info.isCollapsed = skipping
      entries[#entries + 1] = info
    elseif info and not skipping and not info.isHidden and not info.isTask and not info.isBounty then
      entries[#entries + 1] = info
    end
    i = i + 1
  end
  return entries
end

function QL.SetAllCollapsed(shut)
  wipe(collapsed)
  if shut then
    for _, info in ipairs(entries) do
      if info.isHeader then collapsed[HeaderKey(info)] = true end
    end
  end
end

-- True when the header is now shut
function QL.ToggleHeader(info)
  local key = HeaderKey(info)
  if collapsed[key] then
    collapsed[key] = nil
    return false
  end
  collapsed[key] = true
  return true
end

function QL.QuestInLog(questID)
  for _, info in ipairs(entries) do
    if not info.isHeader and info.questID == questID then return info end
  end
end

function QL.FirstQuest()
  for _, info in ipairs(entries) do
    if not info.isHeader then return info.questID end
  end
end

function QL.TagFor(info)
  if C_QuestLog.IsFailed and C_QuestLog.IsFailed(info.questID) then return FAILED or "Failed" end
  if C_QuestLog.IsComplete(info.questID) then return COMPLETE or "Complete" end
  if Enum.QuestFrequency then
    if info.frequency == Enum.QuestFrequency.Daily then return DAILY or "Daily" end
    if info.frequency == Enum.QuestFrequency.Weekly then return WEEKLY or "Weekly" end
  end
  local tag = C_QuestLog.GetQuestTagInfo and C_QuestLog.GetQuestTagInfo(info.questID)
  if tag and tag.tagName and tag.tagName ~= "" then return tag.tagName end
  if info.suggestedGroup and info.suggestedGroup > 0 then return (GROUP or "Group") end
  return nil
end

-- Headers: the client's header colour or grey; quests: the 1.x difficulty colour
function QL.LevelColor(info)
  if info.isHeader then
    local header = QuestDifficultyColors and QuestDifficultyColors["header"]
    if header then return header.r, header.g, header.b end
    return 0.7, 0.7, 0.7
  end
  return Q.QuestLevelColor(info.difficultyLevel or info.level or 0)
end

function QL.IsWatched(questID)
  return C_QuestLog.GetQuestWatchType(questID) ~= nil
end

function QL.SetWatched(questID, watched)
  if watched then
    C_QuestLog.AddQuestWatch(questID, Enum.QuestWatchType and Enum.QuestWatchType.Manual)
  elseif not QuestUtil or not QuestUtil.CanRemoveQuestWatch or QuestUtil.CanRemoveQuestWatch() then
    C_QuestLog.RemoveQuestWatch(questID)
  end
end

-- The game's own abandon prompt for a quest in the log, naming the items it takes with it
function QL.AbandonPrompt(questID)
  if not questID then return end
  C_QuestLog.SetSelectedQuest(questID)
  C_QuestLog.SetAbandonQuest()
  local info = QL.QuestInLog(questID)
  local name = C_QuestLog.GetAbandonQuestName and C_QuestLog.GetAbandonQuestName() or info and info.title or ""
  local items = C_QuestLog.GetAbandonQuestItems and C_QuestLog.GetAbandonQuestItems() or {}
  if #items > 0 then
    local names = {}
    for _, item in ipairs(items) do
      local itemName = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(item)
      names[#names + 1] = itemName or tostring(item)
    end
    StaticPopup_Hide("ABANDON_QUEST")
    StaticPopup_Show("ABANDON_QUEST_WITH_ITEMS", name, table.concat(names, ", "))
  else
    StaticPopup_Hide("ABANDON_QUEST_WITH_ITEMS")
    StaticPopup_Show("ABANDON_QUEST", name)
  end
  PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST)
end

-- Party members on the quest (solo: none)
function QL.PartyOnQuest(questID)
  if not questID or not IsInGroup or not IsInGroup() then return EMPTY end
  if not (C_QuestLog and C_QuestLog.IsUnitOnQuest) then return EMPTY end
  local names = {}
  for i = 1, (GetNumSubgroupMembers and GetNumSubgroupMembers() or 0) do
    local unit = "party" .. i
    local ok, on = pcall(C_QuestLog.IsUnitOnQuest, unit, questID)
    if ok and on == true then
      -- (names are secret in dungeons: the unit's token then)
      names[#names + 1] = Q.Safe(UnitName(unit), unit)
    end
  end
  return names
end

---------------------------------------------------------------------------
-- Share Quest: a secure pad presses the game's own Share (QuestLogPushQuest is protected), our click only explains.
-- The map's Share reads its quest off a row the game fills only as its quest pane shows: one press, in one script
-- run, opens the map, its pane and the quest's header, presses the row, Share and Back, and shuts what was opened.
-- The Aim steps are ours: each points the next clicks at what the game has just built.
---------------------------------------------------------------------------
-- The map shut at the end by its own close button (the game's toggle does not always shut it: with its quest panel
-- not as the player keeps it, it only hides that panel, and the map stayed open). The game puts the map back on the
-- player's zone each time it opens. All in one press, in one script run: the map is never drawn.
local STEPS = { "Open", "AimPane", "Pane", "AimHeader", "Header", "AimRow", "Row", "Share", "Back", "AimShut", "Shut",
  "AimClose", "Close" }
local ORDER = STEPS
local AIMED = { "Pane", "Header", "Row", "Share", "Back", "Shut", "Close" }
local proxies, macro
local armedID
local openedPane
local pressed, shared

local function Aim(step, target)
  Q.SetAttributeIf(proxies[step], "clickbutton", target or nil)
end

local function Disarm()
  for _, step in ipairs(AIMED) do Aim(step, nil) end
end

local function MapUp()
  return armedID ~= nil and not InCombatLockdown() and WorldMapFrame:IsShown()
end

local function AimPane()
  pressed, shared, openedPane = not IsModifierKeyDown(), false, false
  Disarm()
  if not MapUp() then return end
  local toggle = WorldMapFrame.SidePanelToggle
  openedPane = not QuestMapFrame:IsShown() and toggle ~= nil and toggle.OpenButton ~= nil
  Aim("Pane", openedPane and toggle.OpenButton or nil)
end

local function FoldedHeader(questID)
  local header, found
  for i = 1, C_QuestLog.GetNumQuestLogEntries() do
    local info = C_QuestLog.GetInfo(i)
    if info and info.isHeader then
      header = info.isCollapsed and i or nil
    elseif info and info.questID == questID then
      found = true
      break
    end
  end
  local pool = found and header and QuestScrollFrame and QuestScrollFrame.headerFramePool
  if not pool then return nil end
  for button in pool:EnumerateActive() do
    if button.questLogIndex == header then return button end
  end
end

local function AimHeader()
  if MapUp() and QuestMapFrame:IsShown() then Aim("Header", FoldedHeader(armedID)) end
end

-- The quest's row, its questID one only the game's code wrote; read only
local function AimRow()
  if not (MapUp() and QuestMapFrame:IsShown()) then return end
  local find = _G.QuestLogQuests_GetQuestButton
  local row = find and find(armedID)
  local details = QuestMapFrame.DetailsFrame
  local back = details and details.BackFrame and details.BackFrame.BackButton
  if not (row and issecurevariable(row, "questID") and details and details.ShareButton and back) then return end
  shared = true
  Aim("Row", row)
  Aim("Share", details.ShareButton)
  Aim("Back", back)
end

local function AimShut()
  local toggle = WorldMapFrame.SidePanelToggle
  if MapUp() and openedPane and toggle then Aim("Shut", toggle.CloseButton) end
end

-- The map, opened by this press, shut by its own close button
local function AimClose()
  local border = WorldMapFrame.BorderFrame
  if MapUp() then Aim("Close", border and border.CloseButton or nil) end
end

local AIMS = { AimPane = AimPane, AimHeader = AimHeader, AimRow = AimRow, AimShut = AimShut, AimClose = AimClose }

local function BuildShare()
  if proxies then return end
  proxies = {}
  local lines = {}
  for i, step in ipairs(STEPS) do
    proxies[step] = Q.ClickProxy("CQLS" .. i)
    if AIMS[step] then proxies[step]:SetScript("PreClick", AIMS[step]) end
  end
  -- [nomod] on the map's own two: shift on a map row toggles tracking and the chat-link modifier links it
  for i, step in ipairs(ORDER) do
    lines[i] = string.format(step == "Open" and "/click [nomod] %s" or "/click %s", proxies[step]:GetName())
  end
  macro = table.concat(lines, "\n")
end

-- The quest to share while the pad may act: our Share lit, the world map shut, the game's pieces there
local function Wanted()
  local frame, selectedID = QL.Frame and QL.Frame(), QL.SelectedID and QL.SelectedID()
  if not (frame and selectedID and frame.share:IsVisible() and frame.share:IsEnabled()) then return nil end
  if not (WorldMapFrame and QuestMapFrame and MinimapCluster and MinimapCluster.ZoneTextButton) then return nil end
  if WorldMapFrame:IsShown() then return nil end
  return selectedID
end

-- Arms the pad for the picked quest out of combat, or disarms it so a stale pad presses nothing
function QL.PointShare()
  if InCombatLockdown() then return nil end
  local questID = Wanted()
  if not questID and not proxies then return nil end
  BuildShare()
  armedID = questID
  Aim("Open", questID and MinimapCluster.ZoneTextButton or nil)
  Disarm()
  return questID
end

-- The pad's macro; nil hides the pad so our own click explains
function QL.ShareMacro()
  return QL.PointShare() and macro or nil
end

-- After each press: nothing stays aimed, and a press that found no row says where to share instead
function QL.SharePadAfter()
  if not pressed then return end
  pressed = false
  if not InCombatLockdown() then Disarm() end
  if not shared then UIErrorsFrame:AddMessage(L.QL_SHARE_FROM_MAP, 1, 0.1, 0.1) end
end

-- Reached only with the pad away: in combat, or with the map open
function QL.ShareClick()
  local selectedID = QL.SelectedID()
  local info = selectedID and QL.QuestInLog(selectedID)
  if not info then return end
  if not IsInGroup() then
    UIErrorsFrame:AddMessage(L.QL_NOT_IN_GROUP, 1, 0.1, 0.1)
    return
  end
  if InCombatLockdown() then
    Q.SayNotInCombat()
  elseif WorldMapFrame and WorldMapFrame:IsShown() then
    UIErrorsFrame:AddMessage(L.QL_CLOSE_MAP, 1, 0.1, 0.1)
  end
end
