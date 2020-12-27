-- @docclass
UIProgressBar = extends(UIWidget, "UIProgressBar")

function UIProgressBar.create()
  local progressbar = UIProgressBar.internalCreate()
  progressbar:setFocusable(false)
  progressbar:setOn(true)
  progressbar.min = 0
  progressbar.max = 100
  progressbar.value = 0
  progressbar.fillerBackgroundWidget = nil
  progressbar.bgBorderLeft = 0
  progressbar.bgBorderRight = 0
  progressbar.bgBorderTop = 0
  progressbar.bgBorderBottom = 0
  progressbar.bgColor = 'alpha'
  progressbar.bgAreaColor = 'alpha'
  progressbar.imageSource = ''
  progressbar.imageBorder = 0
  progressbar.phases = 0
  progressbar.phasesBorderWidth = 1
  progressbar.phasesBorderColor = '#98885e88'
  return progressbar
end

function UIProgressBar:setMinimum(minimum)
  self.minimum = minimum
  if self.value < minimum then
    self:setValue(minimum)
  end
end

function UIProgressBar:setMaximum(maximum)
  self.maximum = maximum
  if self.value > maximum then
    self:setValue(maximum)
  end
end

function UIProgressBar:setValue(value, minimum, maximum)
  if minimum then
    self:setMinimum(minimum)
  end

  if maximum then
    self:setMaximum(maximum)
  end

  self.value = math.max(math.min(value, self.maximum), self.minimum)
  self:updateBackground()
end

function UIProgressBar:setPercent(percent)
  self:setValue(percent, 0, 100)
end

function UIProgressBar:setPhases(value)
  self.phases = value
  self:updateBackground()
end

function UIProgressBar:setPhasesBorderWidth(value)
  self.phasesBorderWidth = value
  self:updateBackground()
end

function UIProgressBar:setPhasesBorderColor(value)
  self.phasesBorderColor = value
  self:updateBackground()
end

function UIProgressBar:getPercent()
  return self.value
end

function UIProgressBar:getPercentPixels()
  return (self.maximum - self.minimum) / self:getWidth()
end

function UIProgressBar:getProgress()
  if self.minimum == self.maximum then
    return 1
  end

  return (self.value - self.minimum) / (self.maximum - self.minimum)
end

function UIProgressBar:getPhases()
  return self.phases
end

function UIProgressBar:getPhasesBorderWidth()
  return self.phasesBorderWidth
end

function UIProgressBar:getPhasesBorderColor()
  return self.phasesBorderColor
end

function UIProgressBar:updateFillerBackground() -- Should destroy children before at UIProgressBar:updateBackground()
  self.fillerBackgroundWidget = g_ui.createWidget('UIWidget', self)
  self.fillerBackgroundWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
  self.fillerBackgroundWidget:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  self.fillerBackgroundWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
  self.fillerBackgroundWidget:setMarginLeft(self.bgBorderLeft)
  self.fillerBackgroundWidget:setMarginRight(self.bgBorderRight)
  self.fillerBackgroundWidget:setMarginTop(self.bgBorderTop)
  self.fillerBackgroundWidget:setMarginBottom(self.bgBorderBottom)
  self.fillerBackgroundWidget:setWidth(math.round(math.max(self:getProgress() * (self:getWidth() - self.bgBorderLeft - self.bgBorderRight), 1)))
  self.fillerBackgroundWidget:setBackgroundColor(self.bgColor)
  self.fillerBackgroundWidget:setImageSource(self.imageSource)
  self.fillerBackgroundWidget:setImageBorder(self.imageBorder)
  self.fillerBackgroundWidget:setPhantom(true)
end

function UIProgressBar:updatePhases()
  if self.phases < 2 or self.phasesBorderWidth < 1 then
    return
  end

  local phaseWidth = (self:getWidth() - (self.bgBorderLeft + self.bgBorderRight)) / self.phases
  local phaseHeight = (self:getHeight() - (self.bgBorderTop + self.bgBorderBottom)) / 4

  for i = 1, self.phases - 1 do
    local rect = { x = 0, y = 0, width = self.phasesBorderWidth, height = phaseHeight }
    local widget = g_ui.createWidget('UIWidget', self)
    widget:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)

    widget:setMarginLeft((i * phaseWidth) + self.bgBorderLeft)

    widget:setRect(rect)
    widget:setBackgroundColor(self.phasesBorderColor)
    widget:setPhantom(true)
  end
end

function UIProgressBar:updateBackground()
  if self:isOn() then
    -- Remove old widgets
    self:destroyChildren()

    -- Background area
    self:setBackgroundColor(self.bgAreaColor)
    self:setImageSource('')
    self:setImageBorder(0)

    -- Filler background
    self:updateFillerBackground()

    -- Phases
    self:updatePhases()
  end
end

function UIProgressBar:onSetup()
  self:updateBackground()
end

function UIProgressBar:onStyleApply(name, node)
  for name,value in pairs(node) do
    if name == 'background-padding-left' then
      self.bgBorderLeft = tonumber(value)
    elseif name == 'background-padding-right' then
      self.bgBorderRight = tonumber(value)
    elseif name == 'background-padding-top' then
      self.bgBorderTop = tonumber(value)
    elseif name == 'background-padding-bottom' then
      self.bgBorderBottom = tonumber(value)
    elseif name == 'background-padding' then
      self.bgBorderLeft = tonumber(value)
      self.bgBorderRight = tonumber(value)
      self.bgBorderTop = tonumber(value)
      self.bgBorderBottom = tonumber(value)
    elseif name == 'background-area-color' then
      self.bgAreaColor = tostring(value)
    elseif name == 'background-color' then
      self.bgColor = tostring(value)

    elseif name == 'image-source' then
      self.imageSource = tostring(value)
    elseif name == 'image-border' then
      self.imageBorder = tonumber(value)
    end
  end
end

function UIProgressBar:onGeometryChange(oldRect, newRect)
  if not self:isOn() then
    self:setHeight(0)
  end
  self:updateBackground()
end

function UIProgressBar:setFillerBackgroundColor(color)
  if not self.fillerBackgroundWidget then
    return
  end

  self.fillerBackgroundWidget:setBackgroundColor(color)
end
