-- Sokoban minimal for LÖVE2D
-- Tiles:
-- # wall
-- . goal
-- $ box
-- @ player
-- * box on goal
-- + player on goal
-- space floor

local TILE = 32

local levels = {
  {
    "########",
    "#  .   #",
    "#  $   #",
    "#  @   #",
    "#      #",
    "########",
  },
  {
    "  #######",
    "###     #",
    "# .$$@  #",
    "#   .   #",
    "###     #",
    "  #######",
  }
}

local levelIndex = 1

local map = {}
local w, h = 0, 0
local player = { x = 1, y = 1 }
local cleared = false

local function deepcopy(t)
  local r = {}
  for k, v in pairs(t) do
    if type(v) == "table" then r[k] = deepcopy(v) else r[k] = v end
  end
  return r
end

local originalLevelLines = nil

local function loadLevel(idx)
  levelIndex = ((idx - 1) % #levels) + 1
  originalLevelLines = deepcopy(levels[levelIndex])

  map = {}
  h = #originalLevelLines
  w = 0
  for y = 1, h do
    w = math.max(w, #originalLevelLines[y])
  end

  for y = 1, h do
    map[y] = {}
    local line = originalLevelLines[y]
    for x = 1, w do
      local ch = line:sub(x, x)
      if ch == "" or ch == nil then ch = " " end
      if ch == "" then ch = " " end
      map[y][x] = ch

      if ch == "@" or ch == "+" then
        player.x, player.y = x, y
      end
    end
  end
  cleared = false
end

local function isWall(x, y)
  if y < 1 or y > h or x < 1 or x > w then return true end
  return map[y][x] == "#"
end

local function isBox(ch) return ch == "$" or ch == "*" end
local function isGoal(ch) return ch == "." or ch == "*" or ch == "+" end
local function isPlayer(ch) return ch == "@" or ch == "+" end

local function setCell(x, y, ch)
  if y < 1 or y > h or x < 1 or x > w then return end
  map[y][x] = ch
end

local function cell(x, y)
  if y < 1 or y > h or x < 1 or x > w then return "#" end
  return map[y][x]
end

local function movePlayer(dx, dy)
  if cleared then return end

  local px, py = player.x, player.y
  local nx, ny = px + dx, py + dy
  local tx, ty = px + 2*dx, py + 2*dy

  local cur = cell(px, py)
  local nextc = cell(nx, ny)

  if isWall(nx, ny) then return end

  -- helper: leave current cell (restore goal or floor)
  local function leaveCurrent()
    if cur == "+" then
      setCell(px, py, ".")
    else
      setCell(px, py, " ")
    end
  end

  -- helper: enter cell (become + if on goal)
  local function enterCell(x, y)
    local c = cell(x, y)
    if c == "." then
      setCell(x, y, "+")
    else
      setCell(x, y, "@")
    end
    player.x, player.y = x, y
  end

  -- If next is box, try push
  if isBox(nextc) then
    local beyond = cell(tx, ty)
    if isWall(tx, ty) or isBox(beyond) then return end

    -- move box into beyond
    if beyond == "." then
      setCell(tx, ty, "*")   -- box on goal
    else
      setCell(tx, ty, "$")
    end

    -- clear box from next (restore goal/floor)
    if nextc == "*" then
      setCell(nx, ny, ".")
    else
      setCell(nx, ny, " ")
    end

    -- move player into next
    leaveCurrent()
    enterCell(nx, ny)
  else
    -- normal move
    leaveCurrent()
    enterCell(nx, ny)
  end

  -- check clear: no "$" remains (all boxes are "*")
  for y = 1, h do
    for x = 1, w do
      if map[y][x] == "$" then
        cleared = false
        return
      end
    end
  end
  cleared = true
end

function love.load()
  love.window.setTitle("Sokoban (minimal)")
  loadLevel(1)
end

function love.keypressed(key)
  if key == "up" then movePlayer(0, -1)
  elseif key == "down" then movePlayer(0, 1)
  elseif key == "left" then movePlayer(-1, 0)
  elseif key == "right" then movePlayer(1, 0)
  elseif key == "r" then loadLevel(levelIndex)
  elseif key == "n" then loadLevel(levelIndex + 1)
  end
end

local function drawTile(x, y, ch)
  local px = (x - 1) * TILE
  local py = (y - 1) * TILE

  -- floor background
  love.graphics.rectangle("fill", px, py, TILE, TILE)

  if ch == "#" then
    love.graphics.rectangle("fill", px+2, py+2, TILE-4, TILE-4)
  elseif ch == "." then
    love.graphics.circle("fill", px + TILE/2, py + TILE/2, 5)
  elseif ch == "$" then
    love.graphics.rectangle("fill", px+6, py+6, TILE-12, TILE-12)
  elseif ch == "*" then
    love.graphics.rectangle("fill", px+6, py+6, TILE-12, TILE-12)
    love.graphics.circle("fill", px + TILE/2, py + TILE/2, 5)
  elseif ch == "@" then
    love.graphics.circle("fill", px + TILE/2, py + TILE/2, 10)
  elseif ch == "+" then
    love.graphics.circle("fill", px + TILE/2, py + TILE/2, 10)
    love.graphics.circle("fill", px + TILE/2, py + TILE/2, 5)
  end
end

function love.draw()
  -- simple palette via draw order; set colors per tile
  love.graphics.setBackgroundColor(0.12, 0.12, 0.14)

  local ox, oy = 20, 60
  love.graphics.push()
  love.graphics.translate(ox, oy)

  for y = 1, h do
    for x = 1, w do
      local ch = map[y][x]

      -- base floor color
      love.graphics.setColor(0.18, 0.18, 0.2)
      love.graphics.rectangle("fill", (x-1)*TILE, (y-1)*TILE, TILE, TILE)

      if ch == "#" then
        love.graphics.setColor(0.35, 0.35, 0.38)
      elseif ch == "." then
        love.graphics.setColor(0.9, 0.85, 0.3)
      elseif ch == "$" then
        love.graphics.setColor(0.7, 0.45, 0.2)
      elseif ch == "*" then
        love.graphics.setColor(0.7, 0.55, 0.25)
      elseif ch == "@" then
        love.graphics.setColor(0.3, 0.75, 0.95)
      elseif ch == "+" then
        love.graphics.setColor(0.3, 0.75, 0.95)
      else
        -- space
        love.graphics.setColor(0.18, 0.18, 0.2)
      end

      drawTile(x, y, ch)
    end
  end

  love.graphics.pop()

  love.graphics.setColor(1, 1, 1)
  love.graphics.print(("Level %d / %d"):format(levelIndex, #levels), 20, 20)
  love.graphics.print("Arrow keys: move   R: restart   N: next", 200, 20)

  if cleared then
    love.graphics.print("CLEARED! Press N for next level.", 20, 40)
  end
end
