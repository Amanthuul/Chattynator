---@class addonTableChattynator
local addonTable = select(2, ...)

---@class ButtonsBarMixin: Frame
addonTable.Display.ButtonsBarMixin = {}

function addonTable.Display.ButtonsBarMixin:OnLoad()
  self.buttons = {}

  self.socialAnchor1 = {"TOPRIGHT", self:GetParent().ScrollingMessages, "TOPLEFT", -5, 20}

  addonTable.CallbackRegistry:RegisterCallback("SkinLoaded", self.Update, self)

  self:GetParent().ScrollingMessages.scrollCallback = function(destination)
    if self.ScrollToBottomButton then
      self.ScrollToBottomButton:SetShown(destination ~= 0)
    end
    if self.ScrollToEndFrame then
      local ScrollToEndFrameShown = addonTable.Config.Get(addonTable.Config.Options.SHOW_SCROLL_TO_END_FRAME)
      self.ScrollToEndFrame:SetShown(destination ~= 0 and ScrollToEndFrameShown)
    end
  end

  self.hookedButtons = false
  self.active = false

  self.fadeInterpolator = CreateInterpolator(InterpolatorUtil.InterpolateEaseIn)
end

function addonTable.Display.ButtonsBarMixin:AddBlizzardButtons()
  if addonTable.Data.BlizzardButtonsAssigned then
    return
  end

  addonTable.Data.BlizzardButtonsAssigned = true

  if QuickJoinToastButton then
    QuickJoinToastButton:SetParent(self)
    QuickJoinToastButton:SetScript("OnMouseDown", nil)
    QuickJoinToastButton:SetScript("OnMouseUp", nil)
    QuickJoinToastButton:ClearAllPoints()
    QuickJoinToastButton:SetPoint(unpack(self.socialAnchor1))
    QuickJoinToastButton:SetFrameStrata("HIGH")
    local SetPoint = QuickJoinToastButton.SetPoint
    hooksecurefunc(QuickJoinToastButton, "SetPoint", function(_, _, frame)
      if frame ~= self.socialAnchor1[2] then
        QuickJoinToastButton:SetParent(self)
        QuickJoinToastButton:ClearAllPoints()
        SetPoint(QuickJoinToastButton, unpack(self.socialAnchor1))
      end
    end)
    addonTable.Skins.AddFrame("ChatButton", QuickJoinToastButton, {"toasts"})
    table.insert(self.buttons, QuickJoinToastButton)
  end

  if FriendsMicroButton then
    FriendsMicroButton:SetParent(self)
    FriendsMicroButton:SetScript("OnMouseDown", nil)
    FriendsMicroButton:SetScript("OnMouseUp", nil)
    FriendsMicroButton:ClearAllPoints()
    FriendsMicroButton:SetPoint(unpack(self.socialAnchor1))
    FriendsMicroButton:SetFrameStrata("HIGH")
    local SetPoint = FriendsMicroButton.SetPoint
    hooksecurefunc(FriendsMicroButton, "SetPoint", function(_, _, frame)
      if frame ~= self.socialAnchor1[2] then
        FriendsMicroButton:SetParent(self)
        FriendsMicroButton:ClearAllPoints()
        SetPoint(FriendsMicroButton, unpack(self.socialAnchor1))
      end
    end)
    addonTable.Skins.AddFrame("ChatButton", FriendsMicroButton, {"toasts"})
    table.insert(self.buttons, FriendsMicroButton)
  end

  if ChatFrameChannelButton then
    ChatFrameChannelButton:SetParent(self)
    ChatFrameChannelButton:ClearAllPoints()
    ChatFrameChannelButton:SetScript("OnMouseDown", nil)
    ChatFrameChannelButton:SetScript("OnMouseUp", nil)
    addonTable.Skins.AddFrame("ChatButton", ChatFrameChannelButton, {"channels"})
    table.insert(self.buttons, ChatFrameChannelButton)
  end

  if ChatFrameToggleVoiceDeafenButton then
    ChatFrameToggleVoiceDeafenButton:SetParent(self)
    ChatFrameToggleVoiceDeafenButton:ClearAllPoints()
    ChatFrameToggleVoiceDeafenButton:SetPoint("LEFT", ChatFrameChannelButton, "RIGHT", 2, 0)
    addonTable.Skins.AddFrame("ChatButton", ChatFrameToggleVoiceDeafenButton, {"voiceChatNoAudio"})
    addonTable.Skins.AddFrame("ChatButton", ChatFrameToggleVoiceMuteButton, {"voiceChatMuteMic"})
  end

  ChatFrameMenuButton:SetParent(self)
  ChatFrameMenuButton:ClearAllPoints()
  ChatFrameMenuButton:SetScript("OnMouseDown", nil)
  ChatFrameMenuButton:SetScript("OnMouseUp", nil)
  addonTable.Skins.AddFrame("ChatButton", ChatFrameMenuButton, {"menu"})
  table.insert(self.buttons, ChatFrameMenuButton)

  ChatFrameMenuButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(ChatFrameMenuButton, "ANCHOR_RIGHT")
    GameTooltip:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.QUICK_CHAT))
    GameTooltip:Show()
  end)
  ChatFrameMenuButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  addonTable.Skins.AddFrame("ChatButton", ChatFrameMenuButton, {"menu"})
end

local searchMarkup = CreateTextureMarkup("Interface/AddOns/Chattynator/Assets/Search.png", 64, 64, 12, 12, 0, 1, 0, 1)
local function RunSearch(info, text, isPattern)
  local window = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[info.window]
  local tab = window.tabs[info.tab]

  local newTab = CopyTable(tab)
  text = text:lower()
  if isPattern then
    table.insert(newTab.filters, function(data)
      return data.text:lower():match(text) ~= nil
    end)
  else
    table.insert(newTab.filters, function(data)
      return data.text:lower():find(text, nil, true) ~= nil
    end)
  end
  newTab.name = searchMarkup
  newTab.isTemporary = true

  local newIndex = info.tab + 1

  for index, otherTab in ipairs(window.tabs) do
    if otherTab.name == newTab.name and otherTab.isTemporary then
      table.remove(window.tabs, index)
      if index < newIndex then
        newIndex = newIndex - 1
      end
      break
    end
  end

  table.insert(window.tabs, newIndex, newTab)
  addonTable.allChatFrames[info.window].tabIndex = newIndex
  addonTable.CallbackRegistry:TriggerEvent("RefreshStateChange", {[addonTable.Constants.RefreshReason.Tabs] = true})
end

local searchDialog = "Chattynator_SearchDialog"
StaticPopupDialogs[searchDialog] = {
  text = "",
  button1 = SEARCH,
  button3 = CANCEL,
  hasEditBox = 1,
  OnAccept = function(self, data)
    RunSearch(data, self.editBox:GetText(), IsShiftKeyDown())
  end,
  EditBoxOnEnterPressed = function(self, data)
    RunSearch(data, self:GetText(), IsShiftKeyDown())
    self:GetParent():Hide()
  end,
  EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
  hideOnEscape = 1,
}

function addonTable.Display.ButtonsBarMixin:AddButtons()
  if self.madeButtons then
    return
  end

  self.madeButtons = true

  local function MakeButton(tooltipText)
    local button = CreateFrame("Button", nil, self)
    button:SetScript("OnEnter", function()
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText(WHITE_FONT_COLOR:WrapTextInColorCode(tooltipText))
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    return button
  end

  self.SearchButton = MakeButton(SEARCH)
  self.SearchButton:SetScript("OnClick", function()
    local tab = addonTable.Config.Get(addonTable.Config.Options.WINDOWS)[self:GetParent():GetID()].tabs[self:GetParent().tabIndex]
    StaticPopupDialogs[searchDialog].text = addonTable.Locales.SEARCH_IN_X_MESSAGE:format(_G[tab.name] or tab.name)
    StaticPopup_Show(searchDialog, nil, nil, {window = self:GetParent():GetID(), tab = self:GetParent().tabIndex})
  end)
  table.insert(self.buttons, self.SearchButton)
  addonTable.Skins.AddFrame("ChatButton", self.SearchButton, {"search"})
  self.CopyButton = MakeButton(addonTable.Locales.COPY_CHAT)
  self.CopyButton:SetScript("OnClick", function()
    if addonTable.CopyFrame:IsShown() then
      addonTable.CopyFrame:Hide()
    else
      addonTable.CopyFrame:LoadMessages(self:GetParent().ScrollingMessages.filterFunc, self:GetParent().ScrollingMessages.startingIndex)
    end
  end)
  table.insert(self.buttons, self.CopyButton)
  addonTable.Skins.AddFrame("ChatButton", self.CopyButton, {"copy"})
  self.SettingsButton = MakeButton(addonTable.Locales.GLOBAL_SETTINGS)
  self.SettingsButton:SetScript("OnClick", function()
    addonTable.CustomiseDialog.Toggle()
  end)
  table.insert(self.buttons, self.SettingsButton)
  addonTable.Skins.AddFrame("ChatButton", self.SettingsButton, {"settings"})

  self.ScrollToBottomButton = MakeButton(addonTable.Locales.SCROLL_TO_END)
  self.ScrollToBottomButton:SetScript("OnClick", function()
    self:GetParent().ScrollingMessages:ScrollToEnd()
  end)
  self.ScrollToBottomButton:Hide()
  addonTable.Skins.AddFrame("ChatButton", self.ScrollToBottomButton, {"scrollToEnd"})
  self.ScrollToEndFrame = CreateFrame("Frame", nil, self)
  self.ScrollToEndFrame:ClearAllPoints()
  self.ScrollToEndFrame.line = self.ScrollToEndFrame:CreateTexture("line")
  self.ScrollToEndFrame.line:SetPoint("BOTTOMLEFT", self.ScrollToEndFrame)
  self.ScrollToEndFrame.line:SetPoint("BOTTOMRIGHT", self.ScrollToEndFrame)
  self.ScrollToEndFrame.line:SetAtlas("Headhunter_LineHeader")
  self.ScrollToEndFrame.line:SetHeight(1)
  self.ScrollToEndFrame.line:SetDesaturated(true)
  self.ScrollToEndFrame.gradient = self.ScrollToEndFrame:CreateTexture("gradient")
  self.ScrollToEndFrame.gradient:SetAllPoints(self.ScrollToEndFrame, true)
  self.ScrollToEndFrame.gradient:SetTexture("Interface/Buttons/WHITE8x8")
  self.ScrollToEndFrame.gradient:SetHeight(20)
  self.ScrollToEndFrame:SetScript("OnMouseDown", function()
    self:GetParent().ScrollingMessages:ScrollToEnd()
  end)
  self.ScrollToEndFrame:Hide()
  self.ScrollToEndFrame:SetPoint("BOTTOMLEFT", self:GetParent().ScrollingMessages, "BOTTOMLEFT", 0, -5)
  addonTable.Skins.AddFrame("ScrollToEndFrame", self.ScrollToEndFrame, {"scrollToEndFrame"})
end

function addonTable.Display.ButtonsBarMixin:OnEnter()
  for _, b in ipairs(self.buttons) do
    b:SetShown(b.fitsSize)
  end
  if self.hideTimer then
    self.hideTimer:Cancel()
  end
  self.active = true
  self.fadeInterpolator:Interpolate(self.buttons[1]:GetAlpha(), 1, 0.15, function(value)
    for _, b in ipairs(self.buttons) do
      b:SetAlpha(value)
    end
  end)
end

function addonTable.Display.ButtonsBarMixin:OnLeave()
  if self:IsMouseOver() then
    return
  end
  if self.hideTimer then
    self.hideTimer:Cancel()
  end
  self.hideTimer = C_Timer.NewTimer(2, function()
    self.fadeInterpolator:Interpolate(self.buttons[1]:GetAlpha(), 0, 0.15, function(value)
      for _, b in ipairs(self.buttons) do
        b:SetAlpha(value)
      end
    end, function()
      for _, b in ipairs(self.buttons) do
        b:Hide()
      end
    end)
    self.active = false
  end)
end

function addonTable.Display.ButtonsBarMixin:UpdateScrollToEndFrame()
  self.ScrollToEndFrame:SetSize(self:GetParent().ScrollingMessages:GetWidth(), 20)
end

function addonTable.Display.ButtonsBarMixin:Update()
  local position = addonTable.Config.Get(addonTable.Config.Options.BUTTON_POSITION)
  local ScrollToEndFrameShown = addonTable.Config.Get(addonTable.Config.Options.SHOW_SCROLL_TO_END_FRAME)

  if addonTable.Config.Get(addonTable.Config.Options.SHOW_BUTTONS_ON_HOVER) then
    self.lockActive = false
    self:SetScript("OnEnter", self.OnEnter)
    self:SetScript("OnLeave", self.OnLeave)
    if not self.hookedButtons then
      self.hookedButtons = true
      for _, b in ipairs(self.buttons) do
        b:HookScript("OnEnter", function()
          if not self.lockActive then
            self:OnEnter()
          end
        end)
        b:HookScript("OnLeave", function()
          if not self.lockActive then
            self:OnLeave()
          end
        end)
        b:Hide()
        b:SetAlpha(0)
      end
      self.active = false
    end
    if self.active then
      self:OnLeave() -- Hide if necessary
    end
  else
    self.active = true
    self.lockActive = true -- Prevent hooked stuff hiding the buttons
    self:SetScript("OnEnter", nil)
    self:SetScript("OnLeave", nil)
    if self.hideTimer then
      self.hideTimer:Cancel()
      self.hideTimer = nil
    end
    for _, b in ipairs(self.buttons) do
      b:SetAlpha(1)
    end
  end

  if position:match("left") then
    local offsetX, offsetY = -5, 20
    self.ScrollToBottomButton:ClearAllPoints()
    if not addonTable.Config.Get(addonTable.Config.Options.SHOW_TABS) then
      offsetY = -2
    end
    if position:match("inside") then
      offsetX, offsetY = 26 + 2, -2
      self.ScrollToBottomButton:SetPoint("BOTTOMLEFT", self:GetParent().ScrollingMessages, "BOTTOMLEFT", 2, 5)
    else
      self.ScrollToBottomButton:SetPoint("BOTTOMRIGHT", self:GetParent().ScrollingMessages, "BOTTOMLEFT", -5, 5)
    end
    local startingOffsetY = offsetY
    self:ClearAllPoints()
    self:SetPoint("TOPRIGHT", self:GetParent().ScrollingMessages, "TOPLEFT", offsetX, offsetY)
    for _, b in ipairs(self.buttons) do
      local anchor = {"TOPRIGHT", self:GetParent().ScrollingMessages, "TOPLEFT", offsetX, offsetY}
      if b == QuickJoinToastButton or b == FriendsMicroButton then
        self.socialAnchor1 = anchor
      end
      b:ClearAllPoints()
      b:SetPoint(unpack(anchor))
      offsetY = offsetY - b:GetHeight() - 5
    end

    local heightAvailable = self:GetParent().ScrollingMessages:GetHeight() - 2 - self.ScrollToBottomButton:GetHeight() + startingOffsetY
    local currentHeight = 0
    for _, b in ipairs(self.buttons) do
      currentHeight = currentHeight + b:GetHeight() + 5
      b.fitsSize = currentHeight <= heightAvailable
      b:SetShown(self.active and b.fitsSize)
    end
    self:SetSize(22, math.min(heightAvailable, currentHeight))
  elseif position:match("tabs") then
    local offsetX, offsetY = 2, -2
    if position:match("outside") then
      offsetY = 27 + 28 + 2
      if not addonTable.Config.Get(addonTable.Config.Options.SHOW_TABS) then
        offsetY = offsetY - 23
      end
    end
    self.ScrollToBottomButton:ClearAllPoints()
    self.ScrollToBottomButton:SetPoint("BOTTOMLEFT", self:GetParent().ScrollingMessages, "BOTTOMLEFT", 2, 5)
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", self:GetParent().ScrollingMessages, "TOPLEFT", offsetX, offsetY)
    for _, b in ipairs(self.buttons) do
      local anchor = {"TOPLEFT", self:GetParent().ScrollingMessages, "TOPLEFT", offsetX, offsetY}
      if b == QuickJoinToastButton or b == FriendsMicroButton then
        self.socialAnchor1 = anchor
      end
      b:ClearAllPoints()
      b:SetPoint(unpack(anchor))
      offsetX = offsetX + b:GetWidth() + 5
    end

    local widthAvailable = self:GetParent().ScrollingMessages:GetWidth() - 2
    local currentWidth = 0
    for _, b in ipairs(self.buttons) do
      currentWidth = currentWidth + b:GetWidth() + 5
      b.fitsSize = currentWidth <= widthAvailable
      b:SetShown(self.active and b.fitsSize)
    end
    self:SetSize(math.min(widthAvailable, currentWidth), 26)
  end
  self:UpdateScrollToEndFrame()
  self.ScrollToEndFrame:SetShown(self:GetParent().ScrollingMessages.destination ~= 0 and ScrollToEndFrameShown)
end
