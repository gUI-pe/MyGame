local enemy = require "enemy"
local button = require "Button"

math.randomseed(os.time())

local game = {
    difficulty = 1,
    state = {
        menu = true,
        paused = false,
        running = false,
        ended = false,
        won = false
    },

    points = 0,
    levels ={10, 20, 30, 40, 50, 60, 70, 80, 90}
}

local fonts = {
    medium = {
        font = love.graphics.newFont(16),
        size = 16
    },

    large = {
        font = love.graphics.newFont(30),
        size = 30
    },
    
    massive = {
        font = love.graphics.newFont(60),
        size = 60
    }
}

local buttons = {
    menu_state = {},
    ended_state = {}
}

enemies = {}

local function changeGameState(state)
    game.state["menu"] = state == "menu" 
    game.state["paused"] = state == "paused" 
    game.state["running"] = state == "running" 
    game.state["ended"] = state == "ended" 
    game.state["won"] = state == "won"
end

local function startNewGame()
    changeGameState("running")

    game.points = 0

    enemies = {
        enemy(1)
    }
end
function love.load()
    wf = require 'libraries/windfield'

    world = wf.newWorld(0,0)

    camera = require 'libraries/camera'
    cam = camera()

    anim8 = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    sti = require 'libraries/sti'
    gameMap = sti('maps/testMap.lua')

    sounds = {}
    sounds.anew = love.audio.newSource("sounds/a new beginning.ogg", "stream")
    sounds.dark = love.audio.newSource("sounds/dark fallout.ogg", "stream")
    sounds.music = love.audio.newSource("sounds/music.mp3", "stream")
    sounds.ghost = love.audio.newSource("sounds/ghost.ogg", "static")
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.1)
    sounds.anew:setVolume(0.1)
    sounds.dark:setVolume(0.1)
    sounds.ghost:setVolume(0.2)

    sounds.music:play()

    player = {}
    player.collider = world:newBSGRectangleCollider(200,100, 50, 100, 10)
    player.collider:setFixedRotation(true)
    player.x = 200
    player.y = 100
    player.speed = 100000
    player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png')
    player.grid = anim8.newGrid( 12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight() )

    player.animations = {}
    player.animations.down = anim8.newAnimation( player.grid('1-4', 1), 0.2 )
    player.animations.left = anim8.newAnimation( player.grid('1-4', 2), 0.2 )
    player.animations.right = anim8.newAnimation( player.grid('1-4', 3), 0.2 )
    player.animations.up = anim8.newAnimation( player.grid('1-4', 4), 0.2 )

    player.anim = player.animations.left

    enemyImage = love.graphics.newImage('sprites/round ghost walk/sprite_0.png')

    buttons.menu_state.play_game = button("Play Game", startNewGame, nil, 125, 50)
    buttons.menu_state.exit_game = button("Exit Game", love.event.quit, nil, 125, 50)

    buttons.ended_state.replay_game = button("Replay", startNewGame, nil, 115, 50)
    buttons.ended_state.menu = button("Menu", changeGameState, "menu", 115, 50)
    buttons.ended_state.exit_game = button("Quit", love.event.quit, nil, 115, 50)

    background = love.graphics.newImage('sprites/background.png')

    walls = {}
    if gameMap.layers["Walls"] then
        for i, obj in pairs(gameMap.layers["Walls"].objects) do
            local wall = world:newRectangleCollider(obj.x,obj.y,obj.width,obj.height)
            wall:setType('static')
            table.insert(walls, wall)
        end
    end

    gameState = 1

end

function  love.mousepressed(x, y, button, istouch, presses)
    if not game.state["running"] then
        if button == 1 then 
            if game.state["menu"] then
                for index in pairs(buttons.menu_state) do
                    buttons.menu_state[index]:checkPressed(x, y, 1)
                end
            elseif game.state["ended"] then
                for index in pairs(buttons.ended_state) do
                    buttons.ended_state[index]:checkPressed(x, y, 1)
                end
            elseif game.state["won"] then
                for index in pairs(buttons.ended_state) do
                    buttons.ended_state[index]:checkPressed(x, y, 1)
                end
            end
        end
    end
end

function love.update(dt)
    local isMoving = false

    local vx = 0
    local vy = 0

    if love.keyboard.isDown("right") then
        vx = player.speed * dt
        player.anim = player.animations.right
        isMoving = true
    end

    if love.keyboard.isDown("left") then
        vx = player.speed * -1 * dt
        player.anim = player.animations.left
        isMoving = true
    end

    if love.keyboard.isDown("down") then
        vy = player.speed * dt
        player.anim = player.animations.down
        isMoving = true
    end

    if love.keyboard.isDown("up") then
        vy = player.speed * -1 * dt
        player.anim = player.animations.up
        isMoving = true
    end

    player.collider:setLinearVelocity(vx,vy)

    if isMoving == false then
        player.anim:gotoFrame(2)
    end

    world:update(dt)
    player.x = player.collider:getX()
    player.y = player.collider:getY()

    player.anim:update(dt)

    if game.state["running"] then
        sounds.music:stop()
        sounds.anew:play()

        for i = 1,#enemies do
            if not enemies[i]:checkTouched(player.x, player.y) then
                enemies[i]:move(player.x, player.y)

                for i = 1,#game.levels do
                    if math.floor(game.points) == game.levels[i] then
                        table.insert(enemies, 1, enemy(game.difficulty * (1.5) * (1.2)))

                        game.points = game.points + 1
                    end
                end

            else
                sounds.anew:stop()
                sounds.dark:play()
                sounds.ghost:play()
                changeGameState("ended")
            end
        end   
        game.points = game.points + dt
    end

    if game.state["menu"] then
        sounds.dark:stop()
        sounds.music:play()

    end

    if game.points >= 100 then
        game.points = 100
        changeGameState("won")
    end
    if game.state["won"] then
        sounds.anew:stop()
        sounds.music:play()

    end

    cam:lookAt(player.x, player.y)

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    if cam.x < w/2 then 
        cam.x = w/2
    end

    if cam.y < h/2 then 
        cam.y = h/2
    end

    local mapW = gameMap.width * gameMap.tilewidth
    local mapH = gameMap.height * gameMap.tileheight

    if cam.x > (mapW - w/2) then
        cam.x = (mapW - w/2)
    end

    if cam.y > (mapH - h/2) then
        cam.y = (mapH - h/2) 
    end
end


function love.draw()
    love.graphics.setFont(fonts.medium.font)
    cam:attach()
        gameMap:drawLayer(gameMap.layers['Ground'])
        gameMap:drawLayer(gameMap.layers['Trees'])
        gameMap:drawLayer(gameMap.layers['Trees2'])
        gameMap:drawLayer(gameMap.layers['Trees3'])
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 6, nil, 6, 9) 
        if game.state["running"] then
            for i = 1,#enemies do
                enemies[i]:draw()
            end   
        end
    cam:detach()

    if game.state["running"] then
        love.graphics.printf(math.floor(game.points), fonts.massive.font, 0, 10, love.graphics.getWidth(), "center")
    end

    if game.state["menu"] then
        buttons.menu_state.play_game:draw(10, 20, 20, 20)
        buttons.menu_state.exit_game:draw(10, 80, 20, 20)
    end

    if game.state["ended"] then
        love.graphics.setFont(fonts.large.font)

        buttons.ended_state.replay_game:draw(love.graphics.getWidth()/2.25, love.graphics.getHeight()/1.8, 10, 10)
        buttons.ended_state.menu:draw(love.graphics.getWidth()/2.25, love.graphics.getHeight()/1.54, 17, 10)
        buttons.ended_state.exit_game:draw(love.graphics.getWidth()/2.25, love.graphics.getHeight()/1.33, 22, 10)

        love.graphics.printf(math.floor(game.points), fonts.massive.font, 0, love.graphics.getHeight()/ 2 - fonts.massive.size, love.graphics.getWidth(), "center")
    end

    if game.state["won"] then
        love.graphics.printf("YOU WON", fonts.massive.font, 0, love.graphics.getHeight()/ 2 - fonts.massive.size, love.graphics.getWidth(), "center")
        love.graphics.printf(math.floor(game.points), fonts.massive.font, 0, 10, love.graphics.getWidth(), "center")

        buttons.ended_state.replay_game:draw(love.graphics.getWidth()/2.25, love.graphics.getHeight()/1.8, 10, 10)
        buttons.ended_state.exit_game:draw(love.graphics.getWidth()/2.25, love.graphics.getHeight()/1.54, 22, 10)
    end
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function love.keypressed(key)
    if key == "z" then 
        sounds.music:stop()
        sounds.dark:stop()
        sounds.anew:stop()
    end
end