require("lib.ecs-lua.ECS")

local anim8 = require("lib.anim8.anim8")

local Component = ECS.Component
local World = ECS.World
local System = ECS.System
local Query = ECS.Query

local Position = Component({x = 0, y = 0})
local Velocity = Component({vx = 5, vy = 5})
local Direction = Component({x = 0, y = 0})


local Angle = Component({value = 0})
local Sprite = Component(function (param)
    return{value = love.graphics.newImage(param.path)}
end)

local Movable = Query.Filter(function (entity)
    return entity[Velocity].vx > 0 or entity[Velocity].vy > 0
end)


local MoveCharacterSystem = System('process', 1, Query.All(MainCharacter), function (self, deltaTime)
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

local DirByAngleSynch = System('process', 2, Query.All(Angle, Direction), function (self)
    self:Result():ForEach(function (entity)
        local angle = entity[Angle].value
        local direction = entity[Direction]
        direction.x = math.sin(angle)
        direction.y = math.cos(angle)
    end)
end)


local vectorDirByKeyboardSystem = System('process', 2, Query.All(MainCharacter).Any(Direction, Velocity), function (self, deltaTime)
    local direction = Direction({x = 0, y = 0})
        local velocity = Velocity({vx=5, vy=5})
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
    self:Result():ForEach(function (entity)
        local dir = entity[Direction]
        local vel = entity[Velocity]
        dir.x = direction.x + dir.x
        dir.y = direction.y + dir.x
        vel.vx = velocity.vx + vel.vx
        vel.vy = velocity.vy + vel.vy
        dir.x = vel.vx
        dir.y = vel.vy
        if dir.x * dir.y ~= 0 then
            local di = math.sqrt(dir.x * dir.x + dir.y * dir.y)
            dir.x = dir.x / di
            dir.y = dir.y / di
        end
    end)
end)


local AngleByKeyboard = System('process', 2, Query.All(MainCharacter).Any(Angle, Velocity), function (self, deltaTime)

    self:Result():ForEach(function (entity)
        local angle = entity[Angle]
        local velocity = entity[Velocity]
        if love.keyboard.isDown("right") then
            angle.value = angle.value + (0.1 * (5 / velocity.vx))
        end
        if love.keyboard.isDown("left") then
            angle.value = angle.value - (0.1 * (5 / velocity.vy))
        end
    end)
end)

local DirectionByKeyboardInputSystem = System("process", 2, Query.All(MainCharacter),function (self)
        -- entity[Direction].x = direction.x
    -- entity[Direction].y = direction.y
    self:Result():ForEach(function (entity)

        local direction = entity[Direction]
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

        -- if direction.x * direction.y ~= 0 then
        direction.x = direction.x / math.sqrt(2)
        direction.y = direction.y / math.sqrt(2)
    end)
end)

local SpeedUpByKeyboardInputSystem = System('process', 2, Query.All(MainCharacter).Any(Velocity), function (self)
    -- local velocity = Velocity({vx = 5, vy = 5})

    self:Result():ForEach(function (entity)
        local velocity = entity[Velocity]
        if love.keyboard.isDown('lctrl') then
            velocity.vx = math.min((velocity.vx + 1), 10)
            velocity.vy = math.min((velocity.vy + 1), 10)
        else
            velocity.vx = math.max((velocity.vx - 1), 5)
            velocity.vy = math.max((velocity.vy - 1), 5)
        end
    end)
end)

function love.load()
    local sprite = love.graphics.newImage('rocket.png')

    GameWorld = World()
    
    MainCharacter = GameWorld:Entity(
        Position({x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2}),
        Velocity({vx = 5, vy = 5}),
        Direction({x = 1, y = -1}),
        Sprite({path='rocket.png'}),
        Angle({value = 90})
    )

    GameWorld:AddSystem(MoveCharacterSystem)
    GameWorld:AddSystem(RenderCharacterSystem)
    -- GameWorld:AddSystem(DirectionByKeyboardInputSystem)
    GameWorld:AddSystem(SpeedUpByKeyboardInputSystem)
    GameWorld:AddSystem(SpriteRender)
    GameWorld:AddSystem(AngleByKeyboard)
    GameWorld:AddSystem(DirByAngleSynch)
    -- GameWorld:AddSystem(vectorDirByKeyboardSystem)
    -- local img = love.graphics.newImage('particle.png')

	-- psystem = love.graphics.newParticleSystem(img, 32)
	-- psystem:setParticleLifetime(2, 5) -- Particles live at least 2s and at most 5s.
	-- psystem:setEmissionRate(5)
	-- psystem:setSizeVariation(1)
	-- psystem:setLinearAcceleration(-20, -20, 20, 20) -- Random movement in all directions.
	-- psystem:setColors(1, 1, 1, 1, 1, 1, 1, 0) -- Fade to transparency.
end



function love.update(dt)
    GameWorld:Update('process', love.timer.getTime())
    -- psystem:update(dt)

end

function love.draw()
    GameWorld:Update('render', love.timer.getTime())
    -- love.graphics.draw(psystem, love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)
    -- love.graphics.circle("fill", player.x, player.y, 100)
end