-- ClassicQuestLog - the quest log's detail pane: the picked quest's text and rewards down the parchment.

local ADDON, ns = ...
local Q = ns
local QL = Q.QL

local TEXT_W = 285
-- Two reward buttons and the gap between them span the text's width
local REWARD_GAP = 3
local REWARD_SCALE = (TEXT_W - REWARD_GAP) / 2 / 147

local function FirstFont(...)
  for i = 1, select("#", ...) do
    local name = select(i, ...)
    if _G[name] then return name end
  end
  return "GameFontNormal"
end

local FONT_TITLE = FirstFont("QuestTitleFont", "QuestFont_Large", "GameFontNormalLarge")
local FONT_BODY = FirstFont("QuestFont", "QuestFontNormalSmall", "GameFontNormal")
local FONT_SMALL = FirstFont("QuestFontNormalSmall", "GameFontNormalSmall")
local INK_R, INK_G, INK_B = 0.18, 0.12, 0.06 -- (the parchment's ink)
local DONE_R, DONE_G, DONE_B = 0.2, 0.2, 0.2 -- (a finished objective)

-- The log window; FillDetail sets it before any piece is made
local frame

-- Font strings and reward buttons, kept and used again, stacked down the parchment
local detailStrings, detailUsed = {}, 0
local rewardButtons, rewardsUsed = {}, 0

local function DetailString(font, width, x, y, anchor, relPoint)
  detailUsed = detailUsed + 1
  local fs = detailStrings[detailUsed]
  if not fs then
    fs = frame.detailChild:CreateFontString(nil, "ARTWORK")
    detailStrings[detailUsed] = fs
  end
  fs:SetFontObject(font)
  fs:SetJustifyH("LEFT")
  fs:SetWidth(width)
  Q.SetPointOnce(fs, "TOPLEFT", anchor or frame.detailChild, relPoint or "TOPLEFT", x or 0, y or 0)
  fs:SetTextColor(INK_R, INK_G, INK_B)
  fs:Show()
  return fs
end

local function RewardEnter(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  pcall(GameTooltip.SetQuestLogItem, GameTooltip, self.rewardType, self.index, QL.SelectedID())
  GameTooltip:Show()
end

local function RewardClick(self)
  if IsModifiedClick("CHATLINK") and ChatFrameUtil and ChatFrameUtil.InsertLink then
    local ok, link = pcall(GetQuestLogItemLink, self.rewardType, self.index, QL.SelectedID())
    if ok and link then ChatFrameUtil.InsertLink(link) end
  end
end

-- The 1.x reward button at its own 147x41, scaled so two fit across the page
local function RewardButton()
  rewardsUsed = rewardsUsed + 1
  local button = rewardButtons[rewardsUsed]
  if not button then
    button = Q.RewardSlot(frame.detailChild, RewardEnter, RewardClick)
    button:SetScale(REWARD_SCALE)
    rewardButtons[rewardsUsed] = button
  end
  button:Show()
  return button
end

function QL.DetailPieces() return detailStrings, detailUsed, rewardButtons, rewardsUsed end -- (for the tests)

function QL.ResetDetail()
  for i = 1, detailUsed do detailStrings[i]:Hide() end
  for i = 1, rewardsUsed do rewardButtons[i]:Hide() end
  detailUsed, rewardsUsed = 0, 0
end

-- Rewards under `last`, two a row, the money after the header (money alone has one too)
local function RewardGrid(questID, last, kind, count, header, coins)
  if count <= 0 and not coins then return last end
  local label = DetailString(FONT_SMALL, TEXT_W, 0, -5, last, "BOTTOMLEFT")
  label:SetText(header)
  last = label
  if coins then
    local line = DetailString(FONT_SMALL, TEXT_W, 0, 0, label, "TOPLEFT")
    Q.SetPointOnce(line, "LEFT", label, "LEFT", (label:GetStringWidth() or 0) + 15, 0)
    line:SetText(coins)
  end
  local rowAnchor = last
  for i = 1, count do
    local button = RewardButton()
    button.rewardType, button.index = kind, i
    local name, texture, number, _, itemID
    if kind == "choice" then
      name, texture, number, _, _, itemID = GetQuestLogChoiceInfo(i, questID)
    else
      name, texture, number, _, _, itemID = GetQuestLogRewardInfo(i, questID)
    end
    button.icon:SetTexture(texture)
    button.count:SetText((number or 0) > 1 and number or "")
    button.name:SetText(name or (itemID and ("item " .. itemID)) or "")
    button.name:SetTextColor(1, 1, 1) -- (1.x: reward names in white, whatever their quality)
    button:ClearAllPoints()
    -- (offsets in the button's scaled units)
    if i % 2 == 1 then
      button:SetPoint("TOPLEFT", rowAnchor, "BOTTOMLEFT", 0, -4 / REWARD_SCALE)
      rowAnchor = button
      last = button
    else
      button:SetPoint("TOPLEFT", rowAnchor, "TOPRIGHT", REWARD_GAP / REWARD_SCALE, 0)
    end
  end
  return last
end

-- Rewards after `last`: the choices, the items with the money, then the experience
local function LayoutRewards(last, questID)
  local numChoices = GetNumQuestLogChoices(questID, true) or 0
  local numRewards = GetNumQuestLogRewards(questID) or 0
  local money = GetQuestLogRewardMoney(questID) or 0
  local xp = GetQuestLogRewardXP and GetQuestLogRewardXP(questID) or 0
  if numChoices + numRewards + money + xp <= 0 then return last end

  local title = DetailString(FONT_TITLE, TEXT_W, 0, -10, last, "BOTTOMLEFT")
  title:SetText(QUEST_REWARDS or "Rewards")
  last = title
  last = RewardGrid(questID, last, "choice", numChoices, REWARD_CHOICES or "Choose one of the following rewards:")
  last = RewardGrid(questID, last, "reward", numRewards,
    numChoices > 0 and (REWARD_ITEMS or "You will also receive:") or (REWARD_ITEMS_ONLY or "You will receive:"),
    money > 0 and Q.CoinText(money) or nil)
  if xp > 0 then
    local line = DetailString(FONT_SMALL, TEXT_W, 0, -4, last, "BOTTOMLEFT")
    line:SetText(string.format("%s: %s", REWARD_XP or "Experience", BreakUpLargeNumbers and BreakUpLargeNumbers(xp) or xp))
    last = line
  end
  return last
end

-- Writes the page of info, a quest in the log; setHasTimer: the window's timer switch, set where the timer is read
function QL.FillDetail(window, info, detailH, setHasTimer)
  frame = window
  local child = frame.detailChild
  local questID = info.questID
  C_QuestLog.SetSelectedQuest(questID)
  local questIndex = info.questLogIndex

  local titleText = info.title or ""
  if C_QuestLog.IsFailed and C_QuestLog.IsFailed(questID) then
    titleText = titleText .. " - (" .. (FAILED or "Failed") .. ")"
  end
  local title = DetailString(FONT_TITLE, TEXT_W, 5, -5)
  title:SetText(titleText)
  local last = title

  local description, objectivesText = GetQuestLogQuestText(questIndex)
  if objectivesText and objectivesText ~= "" then
    local objectives = DetailString(FONT_BODY, TEXT_W - 10, 0, -5, last, "BOTTOMLEFT")
    objectives:SetText(objectivesText)
    last = objectives
  end

  local timeLeft = GetQuestLogTimeLeft and GetQuestLogTimeLeft()
  setHasTimer(timeLeft ~= nil)
  if timeLeft then
    local timer = DetailString(FONT_SMALL, TEXT_W, 0, -10, last, "BOTTOMLEFT")
    timer:SetText((TIME_REMAINING or "Time Remaining:") .. " " .. SecondsToTime(timeLeft))
    last = timer
  end

  local numObjectives = GetNumQuestLeaderBoards(questIndex) or 0
  for i = 1, numObjectives do
    local text, kind, finished = GetQuestLogLeaderBoard(i, questIndex)
    if not text or text == "" then text = kind end
    local line = DetailString(FONT_SMALL, TEXT_W, 0, i == 1 and -10 or -2, last, "BOTTOMLEFT")
    if finished then
      line:SetTextColor(DONE_R, DONE_G, DONE_B)
      text = text .. " (" .. (COMPLETE or "Complete") .. ")"
    end
    line:SetText(text)
    last = line
  end

  local required = C_QuestLog.GetRequiredMoney and C_QuestLog.GetRequiredMoney(questID) or 0
  if required > 0 then
    local line = DetailString(FONT_SMALL, TEXT_W, 0, numObjectives > 0 and -4 or -10, last, "BOTTOMLEFT")
    line:SetText((REQUIRED_MONEY or "Required Money:") .. " " .. Q.CoinText(required))
    if required > GetMoney() then line:SetTextColor(1, 0.1, 0.1) else line:SetTextColor(DONE_R, DONE_G, DONE_B) end
    last = line
  end

  if description and description ~= "" then
    local header = DetailString(FONT_TITLE, TEXT_W, 0, -10, last, "BOTTOMLEFT")
    header:SetText(QUEST_DESCRIPTION or "Description")
    local body = DetailString(FONT_BODY, TEXT_W - 10, 0, -5, header, "BOTTOMLEFT")
    body:SetText(description)
    last = body
  end

  last = LayoutRewards(last, questID)

  -- The scroll child spans the pane's top to the last piece
  local top, bottom = child:GetTop(), last:GetBottom()
  local height = (top and bottom) and (top - bottom + 12) or detailH
  child:SetHeight(math.max(height, detailH))
  frame.detailBar:SetRange(math.max(0, height - detailH), 20)
end
