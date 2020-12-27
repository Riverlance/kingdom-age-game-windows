_G.GameContainers = { }



function GameContainers.init()
  -- Alias
  GameContainers.m = modules.game_containers

  g_ui.importStyle('container')

  connect(Container, {
    onOpen       = GameContainers.onContainerOpen,
    onClose      = GameContainers.onContainerClose,
    onSizeChange = GameContainers.onContainerChangeSize,
    onUpdateItem = GameContainers.onContainerUpdateItem
  })

  connect(g_game, {
    onGameEnd = GameContainers.clean
  })

  GameContainers.reloadContainers()
end

function GameContainers.terminate()
  disconnect(g_game, {
    onGameEnd = GameContainers.clean
  })

  disconnect(Container, {
    onOpen       = GameContainers.onContainerOpen,
    onClose      = GameContainers.onContainerClose,
    onSizeChange = GameContainers.onContainerChangeSize,
    onUpdateItem = GameContainers.onContainerUpdateItem
  })

  _G.GameContainers = nil
end

function GameContainers.reloadContainers()
  GameContainers.clean()

  for _,container in pairs(g_game.getContainers()) do
    GameContainers.onContainerOpen(container)
  end
end

function GameContainers.clean()
  for containerid,container in pairs(g_game.getContainers()) do
    GameContainers.destroy(container)
  end
end

function GameContainers.destroy(container)
  if container.window then
    container.window:destroy()
    container.window = nil
    container.itemsPanel = nil
  end
end

function GameContainers.refreshContainerItems(container)
  for slot=0,container:getCapacity()-1 do
    local itemWidget = container.itemsPanel:getChildById('item' .. slot)
    itemWidget:setItem(container:getItem(slot))
  end

  if container:hasPages() then
    GameContainers.refreshContainerPages(container)
  end
end

function GameContainers.toggleContainerPages(containerWindow, pages)
  -- Mini window header that contains page panel
  local miniWindowHeader = containerWindow:getChildById('miniWindowHeader')
  miniWindowHeader:setHeight(pages and 28 or 0)
end

function GameContainers.refreshContainerPages(container)
  local miniWindowHeader = container.window:getChildById('miniWindowHeader')
  local pagePanel        = miniWindowHeader:getChildById('pagePanel')

  local currentPage = 1 + math.floor(container:getFirstIndex() / container:getCapacity())
  local pages       = 1 + math.floor(math.max(0, (container:getSize() - 1)) / container:getCapacity())
  pagePanel:getChildById('pageLabel'):setText(tr('Page %d of %d', currentPage, pages))

  local prevPageButton = pagePanel:getChildById('prevPageButton')
  if currentPage == 1 then
    prevPageButton:setEnabled(false)
  else
    prevPageButton:setEnabled(true)
    prevPageButton.onClick = function() g_game.seekInContainer(container:getId(), container:getFirstIndex() - container:getCapacity()) end
  end

  local nextPageButton = pagePanel:getChildById('nextPageButton')
  if currentPage >= pages then
    nextPageButton:setEnabled(false)
  else
    nextPageButton:setEnabled(true)
    nextPageButton.onClick = function() g_game.seekInContainer(container:getId(), container:getFirstIndex() + container:getCapacity()) end
  end
end

function GameContainers.refreshContainerSize(containerWindow, resetToMaxHeight)
  local contentsPanel    = containerWindow:getChildById('contentsPanel')
  local layout           = contentsPanel:getLayout()
  local cellSize         = layout:getCellSize()
  local numColumns       = layout:getNumColumns()
  local minContentHeight = cellSize.height
  local maxContentHeight = cellSize.height * layout:getNumLines()
  local realMinHeight    = containerWindow:getRealMinHeight()
  local minHeight        = realMinHeight + minContentHeight
  local maxHeight        = realMinHeight + maxContentHeight
  local containerHeight  = containerWindow:getHeight()

  -- Set minimum and maximum window height
  containerWindow:setContentMinimumHeight(minContentHeight)
  containerWindow:setContentMaximumHeight(maxContentHeight)

  -- Set window height
  -- Opened on new window (if is not resetToMaxHeight) or containerHeight (actual window size) exceeds the minHeight and maxHeight limits of internal opened container
  if not resetToMaxHeight and not containerWindow.previousContainer or containerHeight < minHeight or containerHeight > maxHeight then
    local newContentHeight

    -- On change the panel's width
    if resetToMaxHeight then
      newContentHeight = maxContentHeight

    -- This is useful for decay items and when the container window changes its size
    else
      local filledLines = math.max(1, math.ceil(containerWindow.container:getItemsCount() / numColumns))
      newContentHeight  = filledLines * cellSize.height
    end

    containerWindow:setContentHeight(newContentHeight)
  end
end

function GameContainers.onContainerOpen(container, previousContainer)
  local containerWindow
  if previousContainer then -- Opened on same window
    containerWindow = previousContainer.window
    previousContainer.window = nil
    previousContainer.itemsPanel = nil
  else
    containerWindow = g_ui.createWidget('ContainerWindow')
  end

  containerWindow:setId('container' .. container:getId())
  containerWindow.container = container
  containerWindow.previousContainer = previousContainer



  -- This disables scrollbar auto hiding
  local scrollbar = containerWindow:getChildById('miniwindowScrollBar')
  scrollbar:mergeStyle({ ['$!on'] = {}})

  -- onClose callback
  connect(containerWindow, {
    onClose = function(self)
      g_game.close(container)
      self:hide()
    end
  })

  -- Refresh container size on change panel of container
  connect(containerWindow, {
    onChangeWindowPanel = function(self, newParent)
      if newParent:getWidth() == self.lastPanel:getWidth() then
        return
      end
      GameContainers.refreshContainerSize(containerWindow)
    end
  })

  local contentsPanel = containerWindow:getChildById('contentsPanel')
  connect(contentsPanel, {
    onGeometryChange = function(self, oldRect, newRect)
      local minimizeButton = containerWindow:getChildById('minimizeButton')
      if minimizeButton:isOn() then
        return
      end
      GameContainers.refreshContainerSize(containerWindow, true)
    end
  })

  -- upArrowMenuButton callback
  local upArrowMenuButton = containerWindow:getChildById('upArrowMenuButton')
  upArrowMenuButton.onClick = function()
    g_game.openParent(container)
  end
  upArrowMenuButton:setVisible(container:hasParent())
  upArrowMenuButton:setTooltip(tr('Back'))

  -- Set item widget
  local containerItemWidget = containerWindow:getChildById('containerItemWidget')
  containerItemWidget:setItem(container:getContainerItem())
  containerItemWidget:setPhantom(true)

  -- Set item name
  local name = container:getName()
  name = name:sub(1,1):upper() .. name:sub(2)
  containerWindow:setText(name)



  -- Setup children
  contentsPanel:destroyChildren()
  for slot = 0, container:getCapacity() - 1 do
    local itemWidget = g_ui.createWidget('Item', contentsPanel)
    itemWidget:setId('item' .. slot)
    itemWidget:setItem(container:getItem(slot))
    itemWidget:setMargin(0)
    itemWidget.position = container:getSlotPosition(slot)

    if not container:isUnlocked() then
      itemWidget:setBorderColor('red')
    end
  end

  -- Update container's window and itemsPanel
  container.window = containerWindow
  container.itemsPanel = contentsPanel

  -- Update pages bar
  GameContainers.toggleContainerPages(containerWindow, container:hasPages())
  GameContainers.refreshContainerPages(container)



  -- Setup window
  GameInterface.onContainerMiniWindowOpen(containerWindow, previousContainer)

  -- Update size
  GameContainers.refreshContainerSize(containerWindow)
end

function GameContainers.onContainerClose(container)
  GameContainers.destroy(container)
end

function GameContainers.onContainerChangeSize(container, size)
  if not container.window then
    return
  end

  GameContainers.refreshContainerItems(container)
end

function GameContainers.onContainerUpdateItem(container, slot, item, oldItem)
  if not container.window then
    return
  end

  local itemWidget = container.itemsPanel:getChildById('item' .. slot)
  itemWidget:setItem(item)
end
