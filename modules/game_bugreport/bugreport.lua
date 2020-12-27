_G.GameBugReport = { }



local maximumXYValue     = 9999
local maximumZValue      = 15
local minimumCommentSize = 50
local textPattern     = "[^%w%s!?%+-*/=@%(%)%[%]%{%}.,]+" -- Find symbols that are NOT letters, numbers, spaces and !?+-*/=@()[]{}.,

local REPORT_MODE_NEWREPORT    = 0
local REPORT_MODE_UPDATESEARCH = 1
local REPORT_MODE_UPDATESTATE  = 2
local REPORT_MODE_REMOVEROW    = 3

bugReportWindow             = nil
bugLabel                    = nil
bugReportButton             = nil
bugCommentMultilineTextEdit = nil
bugCategoryComboBox         = nil
bugPositionX                = nil
bugPositionY                = nil
bugPositionZ                = nil
bugOkButton                 = nil
bugCancelButton             = nil

local REPORT_CATEGORY_ALL       = 255
local REPORT_CATEGORY_MAP       = 0
local REPORT_CATEGORY_TYPO      = 1
local REPORT_CATEGORY_TECHNICAL = 2
local REPORT_CATEGORY_OTHER     = 3

local categories =
{
  [REPORT_CATEGORY_ALL]       = 'All',
  [REPORT_CATEGORY_MAP]       = 'Map',
  [REPORT_CATEGORY_TYPO]      = 'Typo',
  [REPORT_CATEGORY_TECHNICAL] = 'Technical',
  [REPORT_CATEGORY_OTHER]     = 'Other'
}

local bugCategory = REPORT_CATEGORY_MAP

local function sendNewReport(category, comment, position)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  position = position or { x = 0, y = 0, z = 0 }

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeBugReport)
  msg:addString(string.format("%d;%d;%s;%d;%d;%d", REPORT_MODE_NEWREPORT, category, comment:trim(), position.x, position.y, position.z))
  protocolGame:send(msg)
end

local function sendUpdateSearch(category, page, rowsPerPage, state)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeBugReport)
  msg:addString(string.format("%d;%d;%d;%d;%d", REPORT_MODE_UPDATESEARCH, category, page, rowsPerPage, state))
  protocolGame:send(msg)
end

local function sendUpdateState(row)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeBugReport)
  msg:addString(string.format("%d;%d;%d", REPORT_MODE_UPDATESTATE, row.state, row.id))
  protocolGame:send(msg)
end

local function sendRemoveRow(row)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeBugReport)
  msg:addString(string.format("%d;%d", REPORT_MODE_REMOVEROW, row.id))
  protocolGame:send(msg)
end

local function clearBugReportWindow()
  bugCategoryComboBox:setOption('Map')
  bugCategoryComboBox:setEnabled(true)
  bugPositionX:setText(0)
  bugPositionY:setText(0)
  bugPositionZ:setText(0)
  bugPositionX:setEnabled(true)
  bugPositionY:setEnabled(true)
  bugPositionZ:setEnabled(true)
  bugCommentMultilineTextEdit:setText('')
  bugCommentMultilineTextEdit:setEditable(true)
  bugLabel:setText('Use this dialog to only report bug or idea!\nONLY IN ENGLISH!\n\n[Bad Example] :(\nFound a fucking bug! msg me! fast!!!\n\n[Nice Example] :)\nGood morning!\nI found a map bug on my actual position.\nHere is the details: ...')
  bugOkButton:show()
  bugOkButton.onClick = GameBugReport.doReport
  bugCancelButton:setText('Cancel')
  bugCancelButton.onClick = GameBugReport.hideReportWindow
  bugReportWindow.onEscape = bugCancelButton.onClick
  bugCommentMultilineTextEdit:focus()
end

local function onPositionTextChange(self, maxValue)
  local text = self:getText()
  if text:match("[^0-9]+") or (tonumber(text) or 0) > maxValue then
    self:setText(maxValue)
  end
end



function GameBugReport.init()
  -- Alias
  GameBugReport.m = modules.game_bugreport

  g_ui.importStyle('bugreport')

  bugReportButton = ClientTopMenu.addLeftGameButton('bugReportButton', tr('Report Bug/Problem/Idea') .. ' (Ctrl+,)', '/images/ui/top_menu/bugreport', GameBugReport.toggle, true)

  bugReportWindow = g_ui.createWidget('BugReportWindow', rootWidget)
  bugReportWindow:hide()
  bugLabel = bugReportWindow:getChildById('bugLabel')
  bugPositionX = bugReportWindow:getChildById('bugPositionX')
  bugPositionY = bugReportWindow:getChildById('bugPositionY')
  bugPositionZ = bugReportWindow:getChildById('bugPositionZ')
  bugOkButton = bugReportWindow:getChildById('bugOkButton')
  bugCancelButton = bugReportWindow:getChildById('bugCancelButton')
  bugCategoryComboBox = bugReportWindow:recursiveGetChildById('bugCategoryComboBox')
  bugCategoryComboBox:addOption('Map')
  bugCategoryComboBox:addOption('Typo')
  bugCategoryComboBox:addOption('Technical')
  bugCategoryComboBox:addOption('Other')
  bugCategoryComboBox.onOptionChange = GameBugReport.onChangeCategory
  GameBugReport.onChangeCategory(bugCategoryComboBox, 'map') -- For update the tooltip when init the window
  bugCommentMultilineTextEdit = bugReportWindow:getChildById('bugCommentMultilineTextEdit')

  g_keyboard.bindKeyDown('Ctrl+,', GameBugReport.toggle)
  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeBugReport, GameBugReport.parseBugReports) -- View List
end

function GameBugReport.terminate()
  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeBugReport) -- View List
  g_keyboard.unbindKeyDown('Ctrl+,')

  GameBugReport.destroyBugReportWindow()
  GameBugReport.destroyBugReportViewWindow()

  _G.GameBugReport = nil
end



function GameBugReport.destroyBugReportWindow()
  if bugReportWindow then
    bugReportWindow:destroy()
  end

  bugReportWindow             = nil
  bugLabel                    = nil
  bugReportButton             = nil
  bugCommentMultilineTextEdit = nil
  bugCategoryComboBox         = nil
  bugPositionX                = nil
  bugPositionY                = nil
  bugPositionZ                = nil
  bugOkButton                 = nil
  bugCancelButton             = nil
end

function GameBugReport.showReportWindow()
  if not g_game.isOnline() then
    return
  end

  clearBugReportWindow()
  bugReportWindow:show()
  bugReportWindow:raise()
  bugReportWindow:focus()
  bugReportButton:setOn(true)
end

function GameBugReport.hideReportWindow()
  clearBugReportWindow()
  bugReportWindow:hide()
  bugReportButton:setOn(false)
end

function GameBugReport.toggle()
  if not bugReportWindow:isVisible() then
    GameBugReport.showReportWindow()
  else
    GameBugReport.hideReportWindow()
  end
end



function GameBugReport.onChangeCategory(comboBox, option)
  local newCategory = nil
  for k, v in pairs(categories) do
    if v == option then
      newCategory = k
      break
    end
  end

  if not newCategory then
    return
  end

  bugCategory = newCategory

  local isMap = bugCategory == REPORT_CATEGORY_MAP
  if not isMap then
    bugPositionX:setText(0)
    bugPositionY:setText(0)
    bugPositionZ:setText(0)
  end
  bugOkButton:setTooltip(isMap and 'Do not enter your actual player position.\nLeave the default position in blank,\nif you are at the bug position.' or '')
  bugPositionX:setEnabled(isMap)
  bugPositionY:setEnabled(isMap)
  bugPositionZ:setEnabled(isMap)
end

function GameBugReport.onPositionXTextChange(self)
  onPositionTextChange(self, maximumXYValue)
end

function GameBugReport.onPositionYTextChange(self)
  onPositionTextChange(self, maximumXYValue)
end

function GameBugReport.onPositionZTextChange(self)
  onPositionTextChange(self, maximumZValue)
end



function GameBugReport.doReport()
  if not g_game.canPerformGameAction() then
    return
  end

  local position =
  {
    x = tonumber(bugPositionX:getText()) or 0,
    y = tonumber(bugPositionY:getText()) or 0,
    z = tonumber(bugPositionZ:getText()) or 0
  }

  local err
  local comment = bugCommentMultilineTextEdit:getText()
  if #comment < minimumCommentSize then
    err = 'You should write at least ' .. minimumCommentSize .. ' chars on \'Comment\' field.'
  elseif comment:match(textPattern) then
    err = 'The \'Comment\' field should contains only letters, numbers, spaces and !?+-*/=@()[]{}.,.'
  end
  if err then
    displayErrorBox('Error', err)
    return
  end

  sendNewReport(bugCategory, comment, position)
  GameBugReport.hideReportWindow()
end










-- View window

local bugReportViewWindow               = nil
local bugViewList                       = nil
local bugViewPage                       = nil
local bugViewRowsPerPageLabel           = nil
local bugViewRowsPerPageOptionScrollbar = nil
local bugViewStateComboBox              = nil
local bugViewCategoryComboBox           = nil

local REPORT_STATE_UNDONE  = 255
local REPORT_STATE_NEW     = 0
local REPORT_STATE_WORKING = 1
local REPORT_STATE_DONE    = 2

local states =
{
  [REPORT_STATE_UNDONE]  = 'Undone',
  [REPORT_STATE_NEW]     = 'New',
  [REPORT_STATE_WORKING] = 'Working',
  [REPORT_STATE_DONE]    = 'Done'
}

local viewPage     = 1
local maxPages     = 1
local viewState    = REPORT_STATE_UNDONE -- New + Working
local viewCategory = REPORT_CATEGORY_ALL

local function hasViewAccess()
  return g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER
end

local function getWindowState()
  return g_game.isOnline() and bugReportViewWindow and hasViewAccess()
end

local function clearBugReportViewWindow(row)
  bugPositionX:setText(row.mapposx)
  bugPositionY:setText(row.mapposy)
  bugPositionZ:setText(row.mapposz)

  bugCategoryComboBox:setEnabled(false)
  bugPositionX:setEnabled(false)
  bugPositionY:setEnabled(false)
  bugPositionZ:setEnabled(false)
  bugCommentMultilineTextEdit:setText(row.comment)
  bugCommentMultilineTextEdit:setTextAlign(AlignTopLeft)
  bugCommentMultilineTextEdit:setEditable(false)
  bugOkButton:hide()
  bugCancelButton:setText('Close')
  bugCancelButton.onClick = function()
    bugReportWindow:unlock()
    GameBugReport.hideReportWindow()
    bugReportViewWindow:show()
    bugReportViewWindow:lock()
    GameBugReport.listOnChildFocusChange(bugViewList, bugViewList:getFocusedChild())
  end
  bugReportWindow.onEscape = bugCancelButton.onClick
end

local function updateReportRowTitle(row)
  row:setText(row.id .. '. [' .. states[row.state] .. ' | ' .. categories[row.category] .. '] ' .. row.comment:sub(0, 35) .. (#row.comment > 35 and "..." or ""))
end



function GameBugReport.listOnChildFocusChange(textList, focusedChild)
  if not textList then
    return
  end

  -- Update Report Rows Style
  local children = bugViewList:getChildren()
  for i = 1, #children do
    if children[i].state == REPORT_STATE_WORKING then
      children[i]:setColor("#3264c8")
    elseif children[i].state == REPORT_STATE_DONE then
      children[i]:setOn(true)
    end
  end
  if not focusedChild then
    return
  end
end

function GameBugReport.showViewWindow()
  if not g_game.isOnline() or not hasViewAccess() then
    return
  end

  viewPage     = viewPage or 1
  maxPages     = maxPages or 1
  viewState    = viewState or REPORT_STATE_UNDONE
  viewCategory = viewCategory or REPORT_CATEGORY_ALL

  g_ui.importStyle('bugreportview')
  bugReportViewWindow = g_ui.createWidget('BugReportViewWindow', rootWidget)
  bugReportViewWindow:raise()
  bugReportViewWindow:lock()
  bugViewList = bugReportViewWindow:getChildById('bugViewList')
  bugViewPage = bugReportViewWindow:getChildById('bugViewPage')
  bugViewRowsPerPageLabel = bugReportViewWindow:getChildById('bugViewRowsPerPageLabel')
  bugViewRowsPerPageOptionScrollbar = bugReportViewWindow:getChildById('bugViewRowsPerPageOptionScrollbar')
  bugViewStateComboBox = bugReportViewWindow:getChildById('bugViewStateComboBox')
  bugViewCategoryComboBox = bugReportViewWindow:getChildById('bugViewCategoryComboBox')

  bugViewList.onChildFocusChange = GameBugReport.listOnChildFocusChange
  GameBugReport.updateRowsPerPageLabel(GameBugReport.getRowsPerPage())

  bugViewStateComboBox:addOption(states[REPORT_STATE_UNDONE])
  for state = REPORT_STATE_NEW, REPORT_STATE_DONE do
    bugViewStateComboBox:addOption(states[state])
  end
  bugViewStateComboBox.onOptionChange = GameBugReport.onViewChangeState

  bugViewCategoryComboBox:addOption(categories[REPORT_CATEGORY_ALL])
  for category = REPORT_CATEGORY_MAP, REPORT_CATEGORY_OTHER do
    bugViewCategoryComboBox:addOption(categories[category])
  end
  bugViewCategoryComboBox.onOptionChange = GameBugReport.onViewChangeCategory

  GameBugReport.updatePage() -- Fill list
end

function GameBugReport.destroyBugReportViewWindow()
  if bugReportViewWindow then
    bugReportViewWindow:destroy()
  end

  bugReportViewWindow               = nil
  bugViewList                       = nil
  bugViewPage                       = nil
  bugViewRowsPerPageLabel           = nil
  bugViewRowsPerPageOptionScrollbar = nil
  bugViewStateComboBox              = nil
  bugViewCategoryComboBox           = nil
end

function GameBugReport.clearViewWindow()
  viewPage     = 1
  maxPages     = 1
  viewState    = REPORT_STATE_UNDONE
  viewCategory = REPORT_CATEGORY_ALL

  bugViewPage:setText('1')
  GameBugReport.updateRowsPerPageLabel(GameBugReport.getRowsPerPage())

  bugViewStateComboBox:setOption(states[viewState])
  bugViewCategoryComboBox:setOption(categories[viewCategory])

  GameBugReport.updatePage() -- Fill list
end

function GameBugReport.openRow(row)
  if not g_game.isOnline() or not hasViewAccess() then
    return
  end

  if bugReportWindow and bugReportWindow:isVisible() then
    displayErrorBox('Error', 'You should close the \'Report Bug/Problem/Idea\' window before do this.')
    return
  end

  GameBugReport.showReportWindow()
  if bugReportWindow then
    bugReportViewWindow:unlock()
    bugReportViewWindow:hide()

    bugReportWindow:lock()
    clearBugReportViewWindow(row)

    bugLabel:setText(string.format('%s\n- Time: %s\n- Player name: %s\n- Player pos: [ X: %d | Y: %d | Z: %d ]', row:getText(), os.date('%Y %b %d %H:%M:%S', row.time), row.playername, row.playerposx, row.playerposy, row.playerposz))

    if categories[row.category] then
      bugCategoryComboBox:setOption(categories[row.category])
    end
  end
end



function GameBugReport.onBugViewPageChange(self)
  local text   = self:getText()
  local number = tonumber(text) or 0
  if text:match('[^0-9]+') or number > maxPages then -- Pattern: Cannot have non numbers (Correct: '7', '777' | Wrong: 'A7', '-7')
    return self:setText(maxPages)
  elseif text:match('^[0]+[1-9]*') then -- Pattern: Cannot start with 0, except 0 itself (Correct: '0', '70' | Wrong: '00', '07')
    return self:setText(1)
  end
end

function GameBugReport.getRowsPerPage()
  return bugViewRowsPerPageOptionScrollbar and bugViewRowsPerPageOptionScrollbar:getValue() or 1
end

function GameBugReport.updateRowsPerPageLabel(value)
  if not bugViewRowsPerPageLabel then
    return
  end
  bugViewRowsPerPageLabel:setText('Rows per page: ' .. value)
end

function GameBugReport.onViewChangeCategory(comboBox, option)
  local newViewCategory = nil
  for k, v in pairs(categories) do
    if v == option then
      newViewCategory = k
      break
    end
  end

  if not newViewCategory then
    return
  end

  viewCategory = newViewCategory
end

function GameBugReport.onViewChangeState(comboBox, option)
  local newViewState = nil
  for k, v in pairs(states) do
    if v == option then
      newViewState = k
      break
    end
  end

  if not newViewState then
    return
  end

  viewState = newViewState
end

function GameBugReport.bugViewUpdatePage()
  local page = tonumber(bugViewPage:getText()) or 1
  if page < 1 or page > maxPages then
    return
  end

  viewPage = page
  GameBugReport.updatePage()
end

function GameBugReport.bugViewPreviousPage()
  viewPage = math.max(1, viewPage - 1)
  bugViewPage:setText(viewPage)
  GameBugReport.updatePage()
end

function GameBugReport.bugViewNextPage()
  viewPage = math.min(viewPage + 1, maxPages)
  bugViewPage:setText(viewPage)
  GameBugReport.updatePage()
end

function GameBugReport.updatePage()
  if not g_game.canPerformGameAction() or not getWindowState() then
    return
  end

  sendUpdateSearch(viewCategory, viewPage, GameBugReport.getRowsPerPage(), viewState)
end



function GameBugReport.parseBugReports(protocolGame, opcode, msg)
  local buffer = msg:getString()

  if not getWindowState() then
    return
  end

  -- Clear list
  local children = bugViewList:getChildren()
  for i = 1, #children do
    bugViewList:removeChild(children[i])
    children[i]:destroy()
  end

  local _buffer = string.split(buffer, ';:')
  if #_buffer ~= 2 then
    return
  end

  maxPages = tonumber(_buffer[1]) or 1
  maxPages = math.ceil(maxPages / GameBugReport.getRowsPerPage())

  local reports = string.split(_buffer[2], ';')
  for _, report in ipairs(reports) do
    local data = string.split(report, ':')
    local row = g_ui.createWidget('BRVRowLabel', bugViewList)
    row.id         = tonumber(data[1])
    row.state      = tonumber(data[2])
    row.time       = tonumber(data[3])
    row.playername = data[4]
    row.category   = tonumber(data[5])
    row.mapposx    = tonumber(data[6])
    row.mapposy    = tonumber(data[7])
    row.mapposz    = tonumber(data[8])
    row.playerposx = tonumber(data[9])
    row.playerposy = tonumber(data[10])
    row.playerposz = tonumber(data[11])
    row.comment    = string.format('%s', data[12])
    updateReportRowTitle(row)
    row.onDoubleClick = GameBugReport.openRow
  end

  GameBugReport.listOnChildFocusChange(bugViewList, bugViewList:getFocusedChild())
end



-- For avoid multiple remove row confirm windows
local removeConfirmWindowLock = false
function GameBugReport.setRemoveConfirmWindowLock(lock)
  removeConfirmWindowLock = lock
end

function GameBugReport.removeRow(bugViewList, row) -- After confirm button
  if not g_game.canPerformGameAction() or not getWindowState() then
    return
  end

  -- Ignored fields
  local _bugCategory = 255
  local _position    = {}
  local _comment     = ''
  local _page        = 65535
  local _rowsPerPage = 65535
  local _state       = 255

  sendRemoveRow(row)
  bugViewList:removeChild(row)
  row:destroy()

  GameBugReport.listOnChildFocusChange(bugViewList, bugViewList:getFocusedChild())
end

function GameBugReport.bugViewRemoveRow()
  if not getWindowState() then
    return
  end

  local row = bugViewList:getFocusedChild()
  if not row then
    displayErrorBox('Error', 'No row selected.')
    return
  end

  if not removeConfirmWindowLock then
    local buttonCallback = function()
      if GameBugReport then
        GameBugReport.removeRow(bugViewList, row) GameBugReport.setRemoveConfirmWindowLock(false)
      end
    end

    local onCancelCallback = function()
      if GameBugReport then
        GameBugReport.setRemoveConfirmWindowLock(false)
      end
    end

    displayCustomBox('Warning', 'Are you sure that you want to remove the row id ' .. row.id .. '?', {{ text = 'Yes', buttonCallback = buttonCallback }}, 1, 'No', onCancelCallback, nil)
    GameBugReport.setRemoveConfirmWindowLock(true)
  end
end

function GameBugReport.bugViewSetReportState()
  if not g_game.canPerformGameAction() or not getWindowState() then
    return
  end

  local err
  local row = bugViewList:getFocusedChild()
  if not row then
    err = 'No row selected.'
  elseif viewState == 255 then
    err = 'Is not possible to set for this state.'
  end
  if err then
    displayErrorBox('Error', err)
    return
  end

  -- Ignored fields
  local _bugCategory = 255
  local _position    = {}
  local _comment     = ''
  local _page        = 65535
  local _rowsPerPage = 65535

  row.state = viewState
  sendUpdateState(row)

  updateReportRowTitle(row)
  GameBugReport.listOnChildFocusChange(bugViewList, bugViewList:getFocusedChild())
end
