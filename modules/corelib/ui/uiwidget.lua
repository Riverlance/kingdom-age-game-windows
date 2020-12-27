-- @docclass UIWidget

function UIWidget:onSetup()
  local id = self:getId()

  local isMiniWindowHeader = id == "miniWindowHeader"
  local isMiniWindowFooter = id == "miniWindowFooter"

  if isMiniWindowHeader or isMiniWindowFooter then
    local miniWindow          = self:getParent()
    local miniwindowScrollBar = miniWindow:getChildById('miniwindowScrollBar') -- We use scrollbar because contentsPanel follow its top/down anchors

    local isMiniWindowHeaderCreated = isMiniWindowHeader or miniWindow:getChildById('miniWindowHeader') ~= nil
    local isMiniWindowFooterCreated = isMiniWindowFooter or miniWindow:getChildById('miniWindowFooter') ~= nil

    miniwindowScrollBar:breakAnchors()

    miniwindowScrollBar:addAnchor(AnchorTop, isMiniWindowHeaderCreated and 'miniWindowHeader' or 'miniwindowTopBar', AnchorOutsideBottom)
    miniwindowScrollBar:addAnchor(AnchorBottom, isMiniWindowFooterCreated and 'miniWindowFooter' or 'bottomResizeBorder', AnchorOutsideTop)

    miniwindowScrollBar:addAnchor(AnchorRight, 'parent', AnchorRight)
  end
end

function UIWidget:setMargin(...)
  local params = {...}
  if #params == 1 then
    self:setMarginTop(params[1])
    self:setMarginRight(params[1])
    self:setMarginBottom(params[1])
    self:setMarginLeft(params[1])
  elseif #params == 2 then
    self:setMarginTop(params[1])
    self:setMarginRight(params[2])
    self:setMarginBottom(params[1])
    self:setMarginLeft(params[2])
  elseif #params == 4 then
    self:setMarginTop(params[1])
    self:setMarginRight(params[2])
    self:setMarginBottom(params[3])
    self:setMarginLeft(params[4])
  end
end

function UIWidget:onDrop(widget, mousePos)
  if self == widget then
    return false
  end

  -- Avoid dropping miniwindow outside it's panel
  local miniWindowContainer = nil
  if widget:getClassName() == 'UIMiniWindow' then
    -- Finding if dropped widget is UIMiniWindowContainer
    local children = rootWidget:recursiveGetChildrenByPos(mousePos)
    for i=1,#children do
      local child = children[i]
      if child:getClassName() == 'UIMiniWindowContainer' then
        miniWindowContainer = child
        break
      end
    end
  end
  if not miniWindowContainer and widget.lastPanel then
    local oldParent = widget:getParent()
    if oldParent then
      oldParent:removeChild(widget)
    end

    if widget.movedWidget then
      local index = widget.lastPanel:getChildIndex(widget.movedWidget)
      widget.lastPanel:insertChild(index + widget.movedIndex, widget)
    else
      widget.lastPanel:addChild(widget)
    end

    signalcall(widget.lastPanel.onFitAll, widget.lastPanel, self)
  end

  if widget:getClassName() == 'UIHotkeybarContainer' then
    local parent = widget:getParentBar()
    if not parent or not modules.game_hotkeys or not GameHotkeys.isOpen() then
      return false
    end

    local dropParent = self:getParent()
    if dropParent and dropParent:getClassName() == 'UIHotkeybar' then
      dropParent:onDrop(widget, mousePos)
      return true
    end

    parent:removeHotkey(widget)
    return true
  end

  return false
end

function UIWidget:getHorizontalMargin(withoutWidth)
  return (not withoutWidth and self:getWidth() or 0) + self:getMarginLeft() + self:getMarginRight()
end

function UIWidget:getHorizontalPadding(withoutWidth)
  return (not withoutWidth and self:getWidth() or 0) + self:getPaddingLeft() + self:getPaddingRight()
end

function UIWidget:getHorizontalLength(marginOnly)
  return self:getWidth() + self:getHorizontalMargin(true) + (not marginOnly and self:getHorizontalPadding(true) or 0)
end

function UIWidget:getVerticalMargin(withoutHeight)
  return (not withoutHeight and self:getHeight() or 0) + self:getMarginTop() + self:getMarginBottom()
end

function UIWidget:getVerticalPadding(withoutHeight)
  return (not withoutHeight and self:getHeight() or 0) + self:getPaddingTop() + self:getPaddingBottom()
end

function UIWidget:getVerticalLength(marginOnly)
  return self:getHeight() + self:getVerticalMargin(true) + (not marginOnly and self:getVerticalPadding(true) or 0)
end
