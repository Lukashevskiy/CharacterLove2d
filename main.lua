require("lib.ecs-lua.ECS")

local anim8 = require("lib.anim8.anim8")

local Component = ECS.Component
local World = ECS.World
local System = ECS.System
local Query = ECS.Query

local Position = Component({x = 0, y = 0})
local Velocity = Component({vx = 5, vy = 5})
local Direction = Component({x = 0, y = 0})

local Sprite = Component({value = nil})

local Movable = Query.Filter(function (entity)
    return entity[Velocity].vx > 0 or entity[Velocity].vy > 0
end)


local MoveCharacterSystem = System('process', 1, Query.All(MainCharacter).Any(Movable()), function (self, deltaTime)
    self:Result():ForEach(function (entity)
        local velocity = entity[Velocity]
        local direction = entity[Direction]
        local dt = {dx = velocity.vx * direction.x, dy = velocity.vy * direction.y}
        local position = entity[Position]

        position.x = position.x + dt.dx
        position.y = position.y + dt.dy
    end)
end)

local RenderCharacterSystem = System('render', 1, Query.All(MainCharacter), function (self)
    self:Result():ForEach(function (entity)
        local position = entity[Position]
        love.graphics.setColor(1,1,1)
        love.graphics.circle('fill', position.x, position.y, 10)
    end)
end)


local SpriteRender = System('render', 1, Query.All(Sprite, Position, Direction), function (self)
    self:Result():ForEach(function (entity)
        local pos = entity[Position]
        local spr = entity[Sprite].value
        local dir = entity[Direction]
        local angle = math.atan2 (dir.x, -dir.y)
        local oy = spr:getWidth() / 2
        local ox = spr:getHeight() / 2
        love.graphics.draw(spr, pos.x, pos.y, angle, 0.5, 0.5, ox, oy)
    end)
end)


local DirectionByKeyboardInputSystem = System('process', 2, Query.All(MainCharacter).Any(Direction), function (self, deltaTime)
    local direction = {x = 0, y = 0}
    if love.keyboard.isDown('right') then
        direction.x = 1
    end
    if love.keyboard.isDown('left') then
        direction.x = -1
    end
    if love.keyboard.isDown('up') then
        direction.y = -1
    end
    if love.keyboard.isDown('down') then
        direction.y = 1
    end
    
    if direction.x * direction.y ~= 0 then
        direction.x = direction.x / math.sqrt(2)
        direction.y = direction.y / math.sqrt(2)
    end

    self:Result():ForEach(function (entity)
        entity[Direction].x = direction.x
        entity[Direction].y = direction.y
    end)
end)

local SpeedUpByKeyboardInputSystem = System('process', 2, Query.All(MainCharacter).Any(Velocity), function (self)
    local velocity = Velocity({vx = 5, vy = 5})
    if love.keyboard.isDown('lshift') then
        velocity.vx = 10
        velocity.vy = 10
    end
    self:Result():ForEach(function (entity)
        entity[Velocity] = velocity
    end)
end)

function love.load()
    local sprite = love.graphics.newImage('rocket.png')

    GameWorld = World()
    
    MainCharacter = GameWorld:Entity(
        Position({x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2}),
        Velocity({vx = 5, vy = 5}),
        Direction({x = 0, y = -1}),
        Sprite({value = sprite})
    )
    
    GameWorld:AddSystem(MoveCharacterSystem)
    GameWorld:AddSystem(RenderCharacterSystem)
    GameWorld:AddSystem(DirectionByKeyboardInputSystem)
    GameWorld:AddSystem(SpeedUpByKeyboardInputSystem)
    GameWorld:AddSystem(SpriteRender)
end



function love.update(dt)
    GameWorld:Update('process', love.timer.getTime())
end

function love.draw()
    GameWorld:Update('render', love.timer.getTime())
    -- love.graphics.circle("fill", player.x, player.y, 100)
end