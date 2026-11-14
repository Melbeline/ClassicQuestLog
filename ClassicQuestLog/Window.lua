-- ClassicQuestLog - the window: the 1.x quest log on the game's quest API, or the 3.x double pane (on by default;
-- its radio, or its box in the options). Moved by its top; Escape closes it; a quest giver's window closes it, as in 1.x.

local ADDON, ns = ...
local Q = ns
local L = ns.L

local QL = Q.QL
local CollectEntries, SetAllCollapsed, ToggleHeader = QL.CollectEntries, QL.SetAllCollapsed, QL.ToggleHeader
local QuestInLog, FirstQuest, TagFor, LevelColor = QL.QuestInLog, QL.FirstQuest, QL.TagFor, QL.LevelColor
local IsWatched, SetWatched, PartyOnQuest = QL.IsWatched, QL.SetWatched, QL.PartyOnQuest
local ART = Q.ART

local WIDTH, HEIGHT = 384, 512
local ROWS, ROW_H, ROW_GAP = 6, 15, 0.6 -- (six rows fill the 93px track exactly)
local LIST_X, LIST_Y, LIST_W = 19, -75, 300
local LIST_H = 93 -- (the art's list track; the rows are clipped to it)
local DETAIL_GAP, DETAIL_H = 7, 260
local TITLE_TAG_ROOM = 275
-- The X's top right from the window's (the double pane's own x), and its size
local CLOSE_X, DUAL_CLOSE_X, CLOSE_Y, CLOSE_SIZE = -30, 3, -8, 32
-- The 3.x double pane, measured on its two sheets; the frame is their opaque extent
local DUAL = { WIDTH = 680, HEIGHT = 440, LIST_X = 20, LIST_Y = -76, LIST_W = 296, LIST_H = 332, ROWS = 21,
  DETAIL_X = 352, DETAIL_Y = -80, DETAIL_W = 292, DETAIL_H = 328 }
local MAX_ROWS = DUAL.ROWS
-- Where it opens until moved (from the screen's top left), as the game's windows on the left
local HOME_X, HOME_Y = 20, -104
-- The size grip's centre on the art's bottom right corner (from the window's bottom right), one pane or two
local GRIP_SINGLE, GRIP_DUAL = { -34, 47 }, { 0, 1 }

local FRAME_NAME = "ClassicQuestLogFrame" -- (named: Escape closes it, UISpecialFrames)

local frame
local countdown -- (a timed quest's page written again each second)
local rows = {}
local selectedID

local function Rows() return (frame and frame.dual) and DUAL.ROWS or ROWS end
local function DetailHeight() return (frame and frame.dual) and DUAL.DETAIL_H or DETAIL_H end

local CHECK_MARK = ART.CHECK .. "Check"
local RADIO = "Interface\\Buttons\\UI-RadioButton"
local INPUT = "Interface\\Common\\Common-Input-Border"
local MAP_BUTTON = "Interface\\QuestFrame\\UI-QuestMap_Button"

local SINGLE_ART = {
  { key = "questLogTopLeft", layer = "BACKGROUND", w = 256, h = 256, point = "TOPLEFT" },
  { key = "questLogTopRight", layer = "BACKGROUND", w = 128, h = 256, point = "TOPRIGHT" },
  { key = "questLogBotLeft", layer = "BACKGROUND", w = 256, h = 256, point = "BOTTOMLEFT" },
  { key = "questLogBotRight", layer = "BACKGROUND", w = 128, h = 256, point = "BOTTOMRIGHT" },
}
local DUAL_ART = {
  { key = "questLogDualLeft", layer = "BACKGROUND", w = 512, h = 512, point = "TOPLEFT" },
  { key = "questLogDualRight", layer = "BACKGROUND", w = 256, h = 512, point = "TOPLEFT", x = 512 },
}
local EMPTY_ART = {
  { key = "questLogEmptyTopLeft", layer = "BACKGROUND", w = 256, h = 256, point = "TOPLEFT" },
  { key = "questLogEmptyTopRight", layer = "BACKGROUND", w = 64, h = 256, point = "TOPRIGHT", x = -64 },
  { key = "questLogEmptyBotLeft", layer = "BACKGROUND", w = 256, h = 128, point = "BOTTOMLEFT", y = 128 },
  { key = "questLogEmptyBotRight", layer = "BACKGROUND", w = 64, h = 128, point = "BOTTOMRIGHT", x = -64, y = 128 },
}
-- Under the window's art, as Era's: its ring covers the picture's edge
local BOOK = { { key = "questLogBook", layer = "BACKGROUND", sublevel = -8, w = 64, h = 64, point = "TOPLEFT", x = 4, y = -4 } }
-- Built right to left; the middle is sized to the text in UpdateList
local COUNT_BOX = {
  { key = INPUT, layer = "ARTWORK", coords = { 0.9375, 1, 0, 0.625 }, w = 8, h = 20, point = "TOPRIGHT", x = -47, y = -41 },
  { key = INPUT, layer = "ARTWORK", coords = { 0.0625, 0.9375, 0, 0.625 }, w = 100, h = 20,
    point = "RIGHT", relPoint = "LEFT", chain = true },
  { key = INPUT, layer = "ARTWORK", coords = { 0, 0.0625, 0, 0.625 }, w = 8, h = 20,
    point = "RIGHT", relPoint = "LEFT", chain = true },
}
-- All three under the ARTWORK minus icon
local ALL_TAB = {
  { key = "questLogTabLeft", layer = "BACKGROUND", w = 8, h = 32, point = "TOPLEFT", x = -6, y = 8 },
  { key = "questLogTabMiddle", layer = "BACKGROUND", w = 38, h = 32, point = "LEFT", relPoint = "RIGHT", chain = true },
  { key = "questLogTabRight", layer = "BACKGROUND", w = 8, h = 32, point = "LEFT", relPoint = "RIGHT", chain = true },
}

-- The log, the watched quests, the group and the money: the window filled again
local LOG_EVENTS = { "QUEST_LOG_UPDATE", "QUEST_WATCH_LIST_CHANGED", "UNIT_QUEST_LOG_CHANGED", "GROUP_ROSTER_UPDATE",
  "PLAYER_MONEY", "GET_ITEM_INFO_RECEIVED" }
-- The party's changes: the rows; a quest giver's window closes the log
local PARTY_EVENTS = { "PARTY_MEMBER_ENABLE", "PARTY_MEMBER_DISABLE" }
local GIVER_EVENTS = { "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_GREETING", "GOSSIP_SHOW" }
local PARTY, GIVER = {}, {}
for i = 1, #PARTY_EVENTS do PARTY[PARTY_EVENTS[i]] = true end
for i = 1, #GIVER_EVENTS do GIVER[GIVER_EVENTS[i]] = true end

local UpdateAll, Layout, FillRow

local function CloseLog() if frame then frame:Hide() end end

local function CheckSound(button)
  PlaySound(button:GetChecked() and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
end

local function HideTipIfOwned(owner)
  if GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end

-- The quest levels before the titles: the game's own setting (its map's filter changes it too)
local function ShowLevels()
  return GetCVarBool and GetCVarBool("showQuestLevel") or false
end

---------------------------------------------------------------------------
-- The list's rows
---------------------------------------------------------------------------
local function RowClick(row)
  local info = row.info
  if not info then return end
  if info.isHeader then
    PlaySound(ToggleHeader(info) and SOUNDKIT.IG_QUEST_LIST_CLOSE or SOUNDKIT.IG_QUEST_LIST_OPEN)
    UpdateAll()
    return
  end
  if IsModifiedClick("CHATLINK") and ChatFrameUtil and ChatFrameUtil.InsertLink then
    local link = GetQuestLink(info.questID)
    if link and ChatFrameUtil.InsertLink(link) then return end
  end
  if IsShiftKeyDown() then
    SetWatched(info.questID, not IsWatched(info.questID))
  end
  selectedID = info.questID
  C_QuestLog.SetSelectedQuest(info.questID)
  PlaySound(SOUNDKIT.IG_QUEST_LIST_SELECT)
  UpdateAll()
end

-- Filled again first, for the party's names; UpdateList runs it again for the row with the tooltip
local function RowEnter(self)
  local info = self.info
  if not info then
    HideTipIfOwned(self)
    return
  end
  if not info.isHeader then FillRow(self, info) end
  self.text:SetTextColor(1, 1, 1)
  if not info.isHeader then self.tag:SetTextColor(1, 1, 1) end
  if info.isHeader then
    HideTipIfOwned(self) -- (a header scrolled under the pointer: the quest's tooltip goes)
    return
  end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(info.title, 1, 1, 1)
  if self.tagText then GameTooltip:AddLine(self.tagText, 0.8, 0.8, 0.8) end
  if self.party and #self.party > 0 then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(PARTY_QUEST_STATUS_ON or "Party members that are on this quest:", 1, 0.82, 0)
    for _, name in ipairs(self.party) do GameTooltip:AddLine(name, 1, 1, 1) end
  end
  GameTooltip:Show()
end

-- The picked quest stays white, as in 1.x; the others go back to their level's color
local function RowLeave(self)
  local info = self.info
  if info and not (not info.isHeader and info.questID == selectedID) then
    local r, g, b = LevelColor(info)
    self.text:SetTextColor(r, g, b)
    if not info.isHeader then self.tag:SetTextColor(r, g, b) end
  end
  GameTooltip:Hide()
end

local function MakeRow(index)
  local row = CreateFrame("Button", nil, frame.listArea)
  row:SetSize(LIST_W, ROW_H)
  if index == 1 then
    row:SetPoint("TOPLEFT", frame.listArea, "TOPLEFT", 0, 0)
  else
    row:SetPoint("TOPLEFT", rows[index - 1], "BOTTOMLEFT", 0, -ROW_GAP)
  end
  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(16, 16)
  row.icon:SetPoint("LEFT", row, "LEFT", 3, 0)
  row.text = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  row.text:SetJustifyH("LEFT")
  row.text:SetWordWrap(false)
  row.text:SetPoint("LEFT", row, "LEFT", 20, 0)
  row.tag = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  row.tag:SetJustifyH("RIGHT")
  row.tag:SetPoint("RIGHT", row, "RIGHT", -2, 0)
  row.check = row:CreateTexture(nil, "OVERLAY")
  row.check:SetTexture(CHECK_MARK)
  row.check:SetSize(16, 16)
  row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
  row.highlight:SetBlendMode("ADD")
  row:SetScript("OnClick", RowClick)
  row:SetScript("OnEnter", RowEnter)
  row:SetScript("OnLeave", RowLeave)
  row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  return row
end

-- A header: its fold icon and its name. A quest: "[n]" the party on it, its title, its tag, a check if watched.
function FillRow(row, info)
  row.info = info
  if not info then
    row:Hide()
    return
  end
  row:Show()
  local r, g, b = LevelColor(info)
  row.text:SetTextColor(r, g, b)
  row.tag:SetTextColor(r, g, b)
  row.highlight:ClearAllPoints()
  if info.isHeader then
    row.icon:Show()
    Q.SetCollapseIcon(row.icon, info.isCollapsed)
    row.text:SetText(info.title or "")
    row.text:SetWidth(0)
    row.tag:SetText("")
    row.tagText = nil
    row.check:Hide()
    row.highlight:SetTexture(ART.PLUS_GLOW)
    row.highlight:SetSize(16, 16)
    row.highlight:SetPoint("LEFT", row, "LEFT", 3, 0)
    row.highlight:SetAlpha(1)
    row:UnlockHighlight()
    return
  end
  row.icon:Hide()
  local party = PartyOnQuest(info.questID)
  row.party = party
  local level = ShowLevels() and tonumber(info.difficultyLevel or info.level)
  row.text:SetText("  " .. (level and level > 0 and ("[" .. level .. "] ") or "")
    .. (#party > 0 and ("[" .. #party .. "] ") or "") .. (info.title or ""))
  local tag = TagFor(info)
  row.tagText = tag
  row.tag:SetText(tag and ("(" .. tag .. ")") or "")
  -- The title makes room for the tag; the check follows the title
  row.text:SetWidth(0)
  local natural = row.text:GetStringWidth()
  local room = TITLE_TAG_ROOM - (tag and (row.tag:GetStringWidth() + 15) or 0)
  local width = math.min(natural, room)
  row.text:SetWidth(width)
  Q.SetPointOnce(row.check, "LEFT", row, "LEFT", 20 + width + 4, 0)
  row.check:SetShown(IsWatched(info.questID))
  Q.SetTex(row.highlight, "questLogHighlight")
  row.highlight:SetAllPoints(row)
  -- 1.x: the picked quest alone has a bar, in its level's color, and white text; a hover only whitens the text
  if info.questID == selectedID then
    row.highlight:SetVertexColor(r, g, b)
    row.highlight:SetAlpha(1)
    row.text:SetTextColor(1, 1, 1)
    row.tag:SetTextColor(1, 1, 1)
    row:LockHighlight()
  else
    row.highlight:SetAlpha(0)
    row:UnlockHighlight()
  end
end

-- fresh: the entries UpdateAll has just read; the other callers read their own
local function UpdateList(fresh)
  local entries = fresh or CollectEntries()
  local n = Rows()
  local offset = math.floor(frame.listBar:GetValue() + 0.5)
  frame.listBar:SetRange(#entries - n)
  offset = math.min(offset, math.max(0, #entries - n))
  for i = 1, MAX_ROWS do
    FillRow(rows[i], i <= n and entries[i + offset] or nil)
  end
  for i = 1, MAX_ROWS do
    if rows[i]:IsShown() and GameTooltip:IsOwned(rows[i]) then RowEnter(rows[i]) end
  end
  -- The All tab: minus while any header is open, plus once all are shut
  local headers, closed = 0, 0
  for _, info in ipairs(entries) do
    if info.isHeader then
      headers = headers + 1
      if info.isCollapsed then closed = closed + 1 end
    end
  end
  frame.allCollapsed = headers > 0 and closed == headers
  Q.SetCollapseIcon(frame.allIcon, frame.allCollapsed)
  local _, numQuests = C_QuestLog.GetNumQuestLogEntries()
  local max = (C_QuestLog.GetMaxNumQuestsCanAccept and C_QuestLog.GetMaxNumQuestsCanAccept()) or MAX_QUESTS or 20
  -- Era's: the label in the font's gold, the numbers white
  frame.count:SetText(string.format("%s: |cffffffff%d/%d|r", QUESTS or "Quests", numQuests or 0, max))
  frame.countMiddle:SetWidth(math.max(20, frame.count:GetStringWidth()))
end

---------------------------------------------------------------------------
-- The detail pane (QuestLogDetail.lua writes the page)
---------------------------------------------------------------------------
-- The page of a timed quest written again each second, while the log shows
local function SetHasTimer(on)
  frame.hasTimer = on
  if on and frame:IsShown() then
    if not countdown then
      countdown = C_Timer.NewTicker(1, function()
        if frame:IsShown() and frame.hasTimer then Q.Soon("questlog.detail", QL.UpdateDetail) end
      end)
    end
  elseif countdown then
    countdown:Cancel()
    countdown = nil
  end
end

-- The foot's buttons follow the pick
local function UpdateDetail()
  if not frame then return end
  QL.ResetDetail()
  local child = frame.detailChild
  local info = selectedID and QuestInLog(selectedID)
  frame.abandon:SetEnabled(info ~= nil)
  -- Share lit as the game's: shareable, not off this session, in a group
  local pushable = false
  if info and IsInGroup and IsInGroup() and C_QuestLog.IsPushableQuest then
    local ok, can = pcall(C_QuestLog.IsPushableQuest, info.questID)
    local off = C_QuestLog.IsQuestDisabledForSession and C_QuestLog.IsQuestDisabledForSession(info.questID)
    pushable = ok and can == true and not off
  end
  frame.share:SetEnabled(pushable)
  -- Now, not at the pad's next look: a quick click after picking a quest would share the one before
  QL.PointShare()
  frame.trackButton:SetEnabled(info ~= nil)
  frame.track:SetChecked(info ~= nil and IsWatched(selectedID))
  frame.track:SetEnabled(info ~= nil)
  if not info then
    SetHasTimer(false)
    child:SetHeight(1)
    frame.detailBar:SetRange(0)
    return
  end
  QL.FillDetail(frame, info, DetailHeight(), SetHasTimer)
end
QL.UpdateDetail = UpdateDetail

-- The entries read once, and handed to UpdateList
function UpdateAll()
  if not frame or not frame:IsShown() then return end
  local entries = CollectEntries()
  local current = C_QuestLog.GetSelectedQuest()
  if selectedID and not QuestInLog(selectedID) then selectedID = nil end
  if not selectedID and current and current > 0 and QuestInLog(current) then selectedID = current end
  if not selectedID then selectedID = FirstQuest() end
  local empty = #entries == 0
  frame.empty:SetShown(empty)
  frame.detail:SetShown(not empty)
  frame.detailBar:SetShown(not empty)
  frame.listBar:SetShown(not empty)
  frame.allTab:SetShown(not empty and not frame.dual)
  UpdateList(entries)
  UpdateDetail()
end

---------------------------------------------------------------------------
-- Its controls
---------------------------------------------------------------------------
local function PanelButton(parent, text, width)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 22)
  button:SetText(text)
  return button
end

local function CountBox(parent)
  local pieces = Q.Pieces(parent, COUNT_BOX)
  local right, middle = pieces[1], pieces[2]
  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("RIGHT", right, "RIGHT", -6, 0)
  return text, middle, right
end

-- Reached with the pad away (in combat): the map's own key opens it
local function ShowMapClick()
  if InCombatLockdown() then Q.SayNotInCombat() end
end

-- The 3.x Show Map button: the map's icon, its label to the left. A secure pad presses the game's own map button
-- (the minimap's zone text): the map opened by our code would be in our name (its pins, its key in combat).
local function ShowMapButton(parent)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(110, 24)
  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(MAP_BUTTON)
  icon:SetTexCoord(0.125, 0.875, 0, 0.5)
  icon:SetSize(36, 24)
  icon:SetPoint("RIGHT", button, "RIGHT", 0, 0)
  local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  label:SetPoint("RIGHT", icon, "LEFT", -2, 0)
  label:SetText(SHOW_MAP or "Show Map")
  label:SetTextColor(Q.QuestYellow())
  local glow = button:CreateTexture(nil, "HIGHLIGHT")
  glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
  glow:SetBlendMode("ADD")
  glow:SetAllPoints(icon)
  button:SetScript("OnClick", ShowMapClick)
  local target = MinimapCluster and MinimapCluster.ZoneTextButton
  if target then button.pad = Q.Pad(button, { secure = true, target = target, strata = "DIALOG", after = CloseLog }) end
  return button
end

local function AllClick()
  if frame.allCollapsed then
    SetAllCollapsed(false)
    PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN)
  else
    SetAllCollapsed(true)
    PlaySound(SOUNDKIT.IG_QUEST_LIST_CLOSE)
  end
  UpdateAll()
end

local function AllTab(parent)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetSize(54, 32)
  holder:SetPoint("TOPLEFT", parent, "TOPLEFT", 70, -48)
  local button = CreateFrame("Button", nil, holder)
  button:SetSize(40, 22)
  button:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -2)
  Q.Pieces(button, ALL_TAB)
  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetSize(16, 16)
  icon:SetPoint("LEFT", button, "LEFT", 3, 0)
  icon:SetTexture(ART.MINUS)
  local glow = button:CreateTexture(nil, "HIGHLIGHT")
  glow:SetTexture(ART.PLUS_GLOW)
  glow:SetBlendMode("ADD")
  glow:SetAllPoints(icon)
  local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  text:SetPoint("LEFT", button, "LEFT", 20, 0)
  text:SetText(ALL or "All")
  text:SetTextColor(Q.QuestYellow())
  button:SetScript("OnClick", AllClick)
  holder.icon, holder.button = icon, button
  return holder
end

-- A radio beside the All tab (Track Quest, the double pane)
local function RadioCheck(parent, anchor, y, text)
  local button = CreateFrame("CheckButton", nil, parent)
  button:SetSize(20, 20)
  button:SetPoint("LEFT", anchor, "RIGHT", 5, y)
  button:SetNormalTexture(RADIO)
  button:GetNormalTexture():SetTexCoord(0, 0.25, 0, 1)
  button:SetHighlightTexture(RADIO)
  button:GetHighlightTexture():SetTexCoord(0.5, 0.75, 0, 1)
  button:GetHighlightTexture():SetBlendMode("ADD")
  button:SetCheckedTexture(RADIO)
  button:GetCheckedTexture():SetTexCoord(0.25, 0.5, 0, 1)
  local label = button:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  label:SetPoint("LEFT", button, "RIGHT", 0, 0)
  label:SetText(text)
  return button
end

local function TrackClick(self)
  if not selectedID then self:SetChecked(false) return end
  SetWatched(selectedID, self:GetChecked())
  CheckSound(self)
  UpdateAll()
end

-- The same setting as its box in the options
local function DualClick(self)
  CheckSound(self)
  local on = self:GetChecked() and true or false
  Q.Store().dual = on
  Q.SetDual(on)
  if Q.RefreshOptions then Q.RefreshOptions() end
end

local function EmptyPane(parent)
  local empty = CreateFrame("Frame", nil, parent)
  empty:SetSize(WIDTH, HEIGHT)
  empty:SetPoint("TOPLEFT", parent, "TOPLEFT", LIST_X, -73)
  empty.pieces = Q.Pieces(empty, EMPTY_ART)
  local text = empty:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  text:SetWidth(200)
  text:SetPoint("TOP", parent, "TOP", -20, -105)
  empty.text = text
  text:SetText(QUESTLOG_NO_QUESTS_TEXT or "You have no quests. Look for exclamation marks over the heads of characters to find quests.")
  empty:Hide()
  return empty
end

local function AbandonClick() QL.AbandonPrompt(selectedID) end

local function TrackButtonClick()
  if not selectedID then return end
  SetWatched(selectedID, not IsWatched(selectedID))
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  UpdateAll()
end

---------------------------------------------------------------------------
-- Its shape: one pane (the list over the page) or two (side by side); the rows, bars and page are the same
---------------------------------------------------------------------------
function Layout()
  local dual = frame.dual
  for _, tex in ipairs(frame.singleArt) do tex:SetShown(not dual) end
  for _, tex in ipairs(frame.dualArt) do tex:SetShown(dual) end
  frame:SetSize(dual and DUAL.WIDTH or WIDTH, dual and DUAL.HEIGHT or HEIGHT)
  frame:SetHitRectInsets(0, dual and 0 or 35, 0, dual and 0 or 75)
  local listW = dual and DUAL.LIST_W or LIST_W
  frame.listArea:ClearAllPoints()
  if dual then
    frame.listArea:SetPoint("TOPLEFT", frame, "TOPLEFT", DUAL.LIST_X, DUAL.LIST_Y)
    frame.listArea:SetSize(DUAL.LIST_W, DUAL.LIST_H)
  else
    frame.listArea:SetPoint("TOPLEFT", frame, "TOPLEFT", LIST_X, LIST_Y)
    frame.listArea:SetSize(LIST_W, LIST_H)
  end
  for i = 1, MAX_ROWS do rows[i]:SetWidth(listW) end
  frame.detail:ClearAllPoints()
  if dual then
    frame.detail:SetPoint("TOPLEFT", frame, "TOPLEFT", DUAL.DETAIL_X, DUAL.DETAIL_Y)
    frame.detail:SetSize(DUAL.DETAIL_W, DUAL.DETAIL_H)
    frame.detailChild:SetWidth(DUAL.DETAIL_W)
  else
    frame.detail:SetPoint("TOPLEFT", frame.listArea, "BOTTOMLEFT", 0, -DETAIL_GAP)
    frame.detail:SetSize(LIST_W, DETAIL_H)
    frame.detailChild:SetWidth(LIST_W)
  end
  -- The bars on the tracks drawn in the art
  frame.detailBar:ClearAllPoints()
  frame.listBar:ClearAllPoints()
  if dual then
    frame.detailBar:SetPoint("TOPLEFT", frame.detail, "TOPRIGHT", 12, -10)
    frame.detailBar:SetPoint("BOTTOMLEFT", frame.detail, "BOTTOMRIGHT", 12, 14)
    frame.listBar:SetPoint("TOPLEFT", frame.listArea, "TOPRIGHT", 10, -14)
    frame.listBar:SetPoint("BOTTOMLEFT", frame.listArea, "BOTTOMRIGHT", 10, 14)
  else
    frame.detailBar:SetPoint("TOPLEFT", frame.detail, "TOPRIGHT", 7, -16)
    frame.detailBar:SetPoint("BOTTOMLEFT", frame.detail, "BOTTOMRIGHT", 7, 16)
    frame.listBar:SetPoint("TOPLEFT", frame.listArea, "TOPRIGHT", 7, -16)
    frame.listBar:SetPoint("BOTTOMLEFT", frame.listArea, "BOTTOMRIGHT", 7, 16)
  end
  Q.SetPointOnce(frame.book, "TOPLEFT", frame, "TOPLEFT", dual and 6 or 4, dual and -6 or -4)
  Q.SetPointOnce(frame.title, "TOP", frame, "TOP", 0, dual and -19 or -17)
  Q.SetPointOnce(frame.close, "TOPRIGHT", frame, "TOPRIGHT", dual and DUAL_CLOSE_X or CLOSE_X, CLOSE_Y)
  local spot = dual and GRIP_DUAL or GRIP_SINGLE
  Q.SetPointOnce(frame.grip, "CENTER", frame, "BOTTOMRIGHT", spot[1], spot[2])
  frame.countRight:ClearAllPoints()
  if dual then
    frame.countRight:SetPoint("TOPLEFT", frame, "TOPLEFT", 190, -40)
  else
    frame.countRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -47, -41)
  end
  frame.allTab:SetShown(not dual)
  frame.track:SetShown(not dual)
  -- The switch under Track Quest in one pane, beside the count in two
  frame.dualToggle:SetChecked(dual)
  frame.dualToggle:ClearAllPoints()
  if dual then
    frame.dualToggle:SetPoint("LEFT", frame.countRight, "RIGHT", 8, 0)
  else
    frame.dualToggle:SetPoint("LEFT", frame.allTab, "RIGHT", 5, 0)
  end
  frame.showMap:SetShown(dual)
  frame.trackButton:SetShown(dual)
  frame.abandon:ClearAllPoints()
  frame.exit:ClearAllPoints()
  frame.share:ClearAllPoints()
  if dual then
    -- Three buttons of a width across the foot's left box
    local bw = 104
    frame.abandon:SetWidth(bw)
    frame.abandon:SetText(ABANDON_QUEST_ABBREV or "Abandon")
    frame.abandon:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 8)
    frame.share:SetWidth(bw)
    frame.share:SetText(SHARE_QUEST_ABBREV or "Share")
    frame.share:SetPoint("LEFT", frame.abandon, "RIGHT", -4, 0)
    frame.trackButton:SetWidth(bw)
    Q.SetPointOnce(frame.trackButton, "LEFT", frame.share, "RIGHT", 2, 0)
    frame.exit:SetWidth(80)
    frame.exit:SetText(CLOSE or "Close")
    frame.exit:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)
  else
    frame.abandon:SetWidth(125)
    frame.abandon:SetText(ABANDON_QUEST or "Abandon Quest")
    frame.abandon:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 17, 54)
    frame.exit:SetWidth(77)
    frame.exit:SetText(EXIT or "Exit")
    frame.exit:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -43, 54)
    frame.share:SetWidth(123)
    frame.share:SetText(SHARE_QUEST or "Share Quest")
    frame.share:SetPoint("RIGHT", frame.exit, "LEFT", 0, 0)
  end
  -- An empty log: the 1.x empty parchment in one pane; the text alone in the double pane's well
  for _, tex in ipairs(frame.empty.pieces) do tex:SetShown(not dual) end
  frame.empty.text:ClearAllPoints()
  if dual then
    frame.empty.text:SetPoint("TOP", frame.listArea, "TOP", 0, -30)
  else
    frame.empty.text:SetPoint("TOP", frame, "TOP", -20, -105)
  end
end

-- One pane or two (its radio, its box in the options); the window filled again if shown
function Q.SetDual(on)
  on = on and true or false
  if not (frame and frame.dualArt) then return end
  if frame.dual ~= on then
    frame.dual = on
    Layout()
  end
  if frame:IsShown() then UpdateAll() end
end

---------------------------------------------------------------------------
-- Its place and its size: moved by its top, made bigger or smaller by the grip on its bottom right corner (the whole
-- window scaled: the art keeps its shape); both kept (its top left in the screen's units, its scale)
---------------------------------------------------------------------------
local MIN_SCALE, MAX_SCALE = 0.6, 2
local function SavedScale()
  local scale = tonumber(Q.Store().scale)
  return scale and math.max(MIN_SCALE, math.min(MAX_SCALE, scale)) or 1
end

local function PlaceWindow()
  local pos = Q.Store().pos
  local x, y = HOME_X, HOME_Y
  if type(pos) == "table" and type(pos[1]) == "number" and type(pos[2]) == "number" then x, y = pos[1], pos[2] end
  local scale = SavedScale()
  frame:SetScale(scale)
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x / scale, y / scale) -- (offsets in its own, scaled, units)
end

-- Its top left in the screen's units
local function TopLeft()
  local left, top = frame:GetLeft(), frame:GetTop()
  if not (left and top) then return end
  local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
  return left * scale, top * scale - UIParent:GetHeight()
end

local function KeepPlace()
  local x, y = TopLeft()
  if not x then return end
  Q.Store().pos = { math.floor(x + 0.5), math.floor(y + 0.5) }
  PlaceWindow()
end

local function GripSpot() return frame.dual and GRIP_DUAL or GRIP_SINGLE end
-- The corner from the window's top left, in its own units
local function Corner()
  local spot = GripSpot()
  return frame:GetWidth() + spot[1], frame:GetHeight() - spot[2]
end

-- While dragged: the scale that puts the corner under the mouse (the axis it went furthest on), its top left held
local sizing
local function Cursor()
  local x, y = GetCursorPosition()
  local ui = UIParent:GetEffectiveScale()
  return x / ui, y / ui - UIParent:GetHeight()
end
local function SizeStep()
  if not sizing then return end
  local cx, cy = Cursor()
  local cornerX, cornerY = Corner()
  local scale = math.max((cx - sizing.x) / cornerX, (sizing.y - cy) / cornerY)
  -- (never bigger than the screen)
  local fit = math.min(UIParent:GetWidth() / cornerX, UIParent:GetHeight() / cornerY)
  scale = math.max(MIN_SCALE, math.min(MAX_SCALE, fit, scale))
  frame:SetScale(scale)
  frame:ClearAllPoints()
  frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", sizing.x / scale, sizing.y / scale)
end
local function StartSizing()
  local x, y = TopLeft()
  if not x then return end
  sizing = { x = x, y = y }
  frame.grip:SetScript("OnUpdate", SizeStep)
end
local function StopSizing()
  if not sizing then return end
  SizeStep()
  sizing = nil
  frame.grip:SetScript("OnUpdate", nil)
  local scale = math.floor(frame:GetScale() * 100 + 0.5) / 100
  Q.Store().scale = math.abs(scale - 1) >= 0.01 and scale or nil
  KeepPlace()
  Q.PlacePads()
end
local function ResetSize()
  KeepPlace()
  Q.Store().scale = nil
  PlaceWindow()
  Q.PlacePads()
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
end

-- Its first size, at its first place (the options' button)
function Q.ResetPlace()
  local store = Q.Store()
  store.pos, store.scale = nil, nil
  if frame then PlaceWindow() Q.PlacePads() end
end

local GRIP_TEX = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-"
local function Grip()
  local grip = CreateFrame("Button", nil, frame)
  grip:SetSize(16, 16)
  grip:SetFrameLevel(frame:GetFrameLevel() + 20) -- (over the foot's buttons)
  grip:SetNormalTexture(GRIP_TEX .. "Up")
  grip:SetPushedTexture(GRIP_TEX .. "Down")
  grip:SetHighlightTexture(GRIP_TEX .. "Highlight")
  grip:RegisterForClicks("RightButtonUp")
  grip:SetScript("OnMouseDown", function(_, mouse) if mouse == "LeftButton" then StartSizing() end end)
  grip:SetScript("OnMouseUp", function(_, mouse) if mouse == "LeftButton" then StopSizing() end end)
  grip:SetScript("OnHide", StopSizing)
  grip:SetScript("OnClick", function(_, mouse) if mouse == "RightButton" then ResetSize() end end)
  grip:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.QL_GRIP, 1, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return grip
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
-- A burst of the party's log changes: the rows filled again once, next frame
local function FlushParty()
  if not frame.partyDirty then return end
  frame.partyDirty = nil
  if frame:IsShown() then UpdateList() end
end

local function OnLogEvent(self, event, unit)
  if event == "CVAR_UPDATE" then
    if unit == "showQuestLevel" and self:IsShown() then Q.Soon("questlog.update", UpdateAll) end
    return
  end
  if GIVER[event] then
    if self:IsShown() then self:Hide() end
    return
  end
  -- The party's logs: only the rows' party counts and names
  if (event == "UNIT_QUEST_LOG_CHANGED" and unit ~= "player") or PARTY[event] then
    if self:IsShown() then
      self.partyDirty = true
      Q.Soon("questlog.party", FlushParty)
    end
    return
  end
  if not self:IsShown() then return end
  -- A reward's item data arriving late: the page alone; one rebuild a frame, however many events
  if event == "GET_ITEM_INFO_RECEIVED" then Q.Soon("questlog.detail", UpdateDetail) else Q.Soon("questlog.update", UpdateAll) end
end

local function LogShown()
  PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN)
  UpdateAll()
  Q.PlacePads()
end

local function LogHidden()
  PlaySound(SOUNDKIT.IG_QUEST_LOG_CLOSE)
  GameTooltip:Hide()
  SetHasTimer(false)
  -- The share pad disarmed at once, and the window's pads put away (out of combat; in combat they are away)
  QL.PointShare()
  Q.PlacePads()
end

local function Build()
  frame = CreateFrame("Frame", FRAME_NAME, UIParent)
  frame:SetSize(WIDTH, HEIGHT)
  frame:SetToplevel(true)
  frame:EnableMouse(true)
  frame:SetFrameStrata("HIGH")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  PlaceWindow()
  frame:Hide()
  tinsert(UISpecialFrames, FRAME_NAME) -- (Escape closes it)

  frame.singleArt = Q.Pieces(frame, SINGLE_ART)
  frame.dualArt = Q.Pieces(frame, DUAL_ART)
  frame.book = Q.Pieces(frame, BOOK)[1]

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  title:SetPoint("TOP", frame, "TOP", 0, -17)
  title:SetText(QUEST_LOG or "Quest Log")
  frame.title = title

  -- Moved by its top band
  local drag = CreateFrame("Frame", nil, frame)
  drag:SetPoint("TOPLEFT", frame, "TOPLEFT", 70, -10)
  drag:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -70, -10)
  drag:SetHeight(26)
  drag:EnableMouse(true)
  drag:RegisterForDrag("LeftButton")
  drag:SetScript("OnDragStart", function() frame:StartMoving() end)
  drag:SetScript("OnDragStop", function() frame:StopMovingOrSizing() KeepPlace() end)
  frame.drag = drag

  frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  frame.close:SetSize(CLOSE_SIZE, CLOSE_SIZE)
  frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", CLOSE_X, CLOSE_Y)
  frame.close:SetScript("OnClick", CloseLog)
  frame.grip = Grip()

  frame.count, frame.countMiddle, frame.countRight = CountBox(frame)
  frame.allTab = AllTab(frame)
  frame.allIcon = frame.allTab.icon
  frame.track = RadioCheck(frame, frame.allTab, 17, TRACK_QUEST or "Track Quest")
  frame.track:SetScript("OnClick", TrackClick)
  frame.dualToggle = RadioCheck(frame, frame.allTab, 0, L.QL_DUAL)
  frame.dualToggle:SetScript("OnClick", DualClick)
  frame.showMap = ShowMapButton(frame)
  frame.showMap:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -40)

  local listArea = CreateFrame("Frame", nil, frame)
  listArea:SetPoint("TOPLEFT", frame, "TOPLEFT", LIST_X, LIST_Y)
  listArea:SetSize(LIST_W, LIST_H)
  listArea:SetClipsChildren(true)
  frame.listArea = listArea
  for i = 1, MAX_ROWS do rows[i] = MakeRow(i) end
  frame.rows = rows -- (for the tests)
  listArea:EnableMouseWheel(true)
  listArea:SetScript("OnMouseWheel", function(_, delta) frame.listBar:SetValue(frame.listBar:GetValue() - delta) end)
  frame.listBar = Q.ScrollBar(frame, listArea, function() UpdateList() end)

  local detail = CreateFrame("ScrollFrame", nil, frame)
  detail:SetPoint("TOPLEFT", listArea, "BOTTOMLEFT", 0, -DETAIL_GAP)
  detail:SetSize(LIST_W, DETAIL_H)
  detail:SetClipsChildren(true)
  local child = CreateFrame("Frame", nil, detail)
  child:SetSize(LIST_W, DETAIL_H)
  detail:SetScrollChild(child)
  detail:EnableMouseWheel(true)
  detail:SetScript("OnMouseWheel", function(_, delta) frame.detailBar:SetValue(frame.detailBar:GetValue() - delta * 20) end)
  frame.detail, frame.detailChild = detail, child
  frame.detailBar = Q.ScrollBar(frame, detail, function(value) detail:SetVerticalScroll(value) end)

  frame.empty = EmptyPane(frame)

  frame.abandon = PanelButton(frame, ABANDON_QUEST or "Abandon Quest", 125)
  frame.abandon:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 17, 54)
  frame.abandon:SetScript("OnClick", AbandonClick)
  frame.exit = PanelButton(frame, EXIT or "Exit", 77)
  frame.exit:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -43, 54)
  frame.exit:SetScript("OnClick", CloseLog)
  frame.share = PanelButton(frame, SHARE_QUEST or "Share Quest", 123)
  frame.share:SetPoint("RIGHT", frame.exit, "LEFT", 0, 0)
  frame.share:SetScript("OnClick", QL.ShareClick)
  -- (DIALOG: over the HIGH log, as the Show Map pad)
  frame.share.pad = Q.Pad(frame.share, { secure = true, macro = QL.ShareMacro, strata = "DIALOG", after = QL.SharePadAfter })
  -- The double pane's Track foot button, as in 3.x
  frame.trackButton = PanelButton(frame, TRACK_QUEST_ABBREV or "Track", 76)
  frame.trackButton:SetScript("OnClick", TrackButtonClick)

  Q.RegisterEvents(frame, LOG_EVENTS)
  Q.RegisterEvents(frame, PARTY_EVENTS) -- (a party member on or offline: who is on a quest)
  Q.RegisterEvents(frame, GIVER_EVENTS) -- (a quest giver's window closes the log, as in 1.x)
  Q.RegisterEvents(frame, { "CVAR_UPDATE" }) -- (the quest levels' setting)
  frame:SetScript("OnEvent", OnLogEvent)
  frame:HookScript("OnShow", LogShown)
  frame:HookScript("OnHide", LogHidden)
  frame.dual = Q.IsDual()
  Layout()
end

function Q.Show(questID)
  if not frame then Build() end
  if questID then
    selectedID = questID
    C_QuestLog.SetSelectedQuest(questID)
  end
  if frame:IsShown() then UpdateAll() else frame:Show() end
end

function Q.Hide() if frame then frame:Hide() end end

function Q.Toggle()
  if frame and frame:IsShown() then Q.Hide() else Q.Show() end
end

-- nil until the first show builds it
function QL.Frame() return frame end
-- The quest the page shows; the reward buttons read it then
function QL.SelectedID() return selectedID end
