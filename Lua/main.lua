-- helper functions

function pieceCantMove(X, Y)
    return (X < 1 or Y < 1 or X > mapLength or Y > mapHeight or mapBackground[Y][X] ~= ' ')
end

function canPieceMove(X, Y, testRotation)
    for y = 1, 4 do
        for x = 1, 4 do
            if pieces[pieceShape][testRotation][y][x] ~= ' ' then
                local tmpX = X + x
                local tmpY = Y + y

                if pieceCantMove(tmpX, tmpY) then
                    return false
                end
            end
        end
    end

    return true
end

function getNextPieceShape()
    retShape = nextPieceShape
    nextPieceShape = love.math.random(1, 4)
    return retShape
end

function newPiece()
    pieceX = 3
    pieceY = 0
    pieceRotation = 1
    pieceShape = getNextPieceShape()
    score = score + 4
end

function prepareGame()
    mapBackground = {}
    for y = 1, mapHeight do
        mapBackground[y] = {}
        for x = 1, mapLength do
            mapBackground[y][x] = ' '
        end
    end

    newPiece()
    timer = 0
end

function drawBlock(block, x, y, mode)
    local colors = {
        [' '] = {0, 0, 0},
        a = {1, .0, .0},
        b = {.0, 1, .0},
        c = {.0, .0, 1},
        d = {1, .0, 1}
    }

    local color = colors[block]
    love.graphics.setColor(color)

    local blockSize = 20
    local sideSize = blockSize - 1

    love.graphics.rectangle(
        mode,
        (x - 1) * blockSize,
        (y - 1) * blockSize,
        sideSize,
        sideSize
    )
end

function drawMapBackground()
    for y = 1, mapHeight do
        for x = 1, mapLength do
            drawBlock(mapBackground[y][x], x + offsetX, y + offsetY, 'line')
        end
    end
end

function drawPiece(xOffset, yOffset, shape, rotation)
    for y = 1, 4 do
        for x = 1, 4 do
            local block = pieces[shape][rotation][y][x]
            if block ~= ' ' then
                drawBlock(block, x + xOffset, y + yOffset, 'fill')
            end
        end
    end
end

function gameOver()
    love.event.quit()
end

function setPieceToBackground()
    for y = 1, 4 do
        for x = 1, 4 do
            local block =
                pieces[pieceShape][pieceRotation][y][x]
            if block ~= ' ' then
                mapBackground[pieceY + y][pieceX + x] = block
            end
        end
    end
end

function removeRows(y)
    for removeY = y, 1, -1 do
        for removeX = 1, mapLength do
            local replacement = ' '
            if removeY ~= 1 then
                replacement = mapBackground[removeY - 1][removeX]
            end
            mapBackground[removeY][removeX] = replacement
        end
    end
end

function checkIfRowsCompleted()
    for y = 1, mapHeight do
        local complete = true
        for x = 1, mapLength do
            if mapBackground[y][x] == ' ' then
                complete = false
                break
            end
        end

        if complete then
            shouldAnimate = true
            removeRows(y)
        end
    end
end

function actionsUp()
    local testRotation = pieceRotation + 1
    if testRotation > #pieces[pieceShape] then
        testRotation = 1
    end

    if canPieceMove(pieceX, pieceY, testRotation) then
        pieceRotation = testRotation
    end
end

function actionsDown()
    local testRotation = pieceRotation - 1
    if testRotation < 1 then
        testRotation = #pieces[pieceShape]
    end

    if canPieceMove(pieceX, pieceY, testRotation) then
        pieceRotation = testRotation
    end
end

function actionsLeft()
    local tmpX = pieceX - 1
    if canPieceMove(tmpX, pieceY, pieceRotation) then
        pieceX = tmpX
    end
end

function actionsRight()
    local tmpX = pieceX + 1
    if canPieceMove(tmpX, pieceY, pieceRotation) then
        pieceX = tmpX
    end
end

function actionsSpace()
    while canPieceMove(pieceX, pieceY + 1, pieceRotation) do
        pieceY = pieceY + 1
        timer = maxStepTime
    end
end

function saveGame()
    local file = io.open("./gameState.txt", "w+")
    io.output(file)
    io.write(levelTimer)
    io.write('\n')
    io.write(pieceX)
    io.write('\n')
    io.write(pieceY)
    io.write('\n')
    io.write(pieceRotation)
    io.write('\n')
    io.write(pieceShape)
    io.write('\n')
    io.write(score)
    io.write('\n')
    io.write(nextPieceShape)
    io.write('\n')
    for y = 1, mapHeight do
        for x = 1, mapLength do
            io.write(mapBackground[y][x])
        end
        if y ~= mapHeight then
            io.write('\n')
        end
    end
    io.close(file)
end

function loadGame()
    -- load game from file gameState.txt
    local cnt = 0
    local indexY = 1
    local indexX = 1
    local file = io.open("./gameState.txt")
    local lines = file:lines()

    for line in lines do
        if cnt == 0 then
            levelTimer = tonumber(line)
        elseif cnt == 1 then
            pieceX = tonumber(line)
        elseif cnt == 2 then
            pieceY = tonumber(line)
        elseif cnt == 3 then
            pieceRotation = tonumber(line)
        elseif cnt == 4 then
            pieceShape = tonumber(line)
        elseif cnt == 5 then
            score = tonumber(line)
        elseif cnt == 6 then
            nextPieceShape = tonumber(line)
        else
            for c in string.gmatch(line, ".") do
                if c ~= '\n' then
                    mapBackground[indexY][indexX] = c
                    indexX = indexX + 1
                    if indexX > mapLength then
                        indexX = 1
                        indexY = indexY + 1
                    end
                end
            end
        end
        cnt = cnt + 1
    end
    io.close(file)
end

function newAnimation(image, width, height, duration)
    local animation = {}
    animation.spriteSheet = image;
    animation.quads = {};

    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end

    animation.duration = duration or 1
    animation.currentTime = 0

    return animation
end

-- Main game body:
function love.load()
    screenSizeX = 800
    screenSizeY = 800
    love.window.setMode(screenSizeX, screenSizeY, {resizable=false, vsync=0})
    love.graphics.setBackgroundColor(0.5, 0.5, 0.5)

    pieces = {
        {
            {
                {'a', 'a', 'a', 'a'},
                {' ', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
            {
                {' ', ' ', 'a', ' '},
                {' ', ' ', 'a', ' '},
                {' ', ' ', 'a', ' '},
                {' ', ' ', 'a', ' '},
            },
        },
        {
            {
                {'b', 'b', 'b', ' '},
                {' ', 'b', ' ', ' '},
                {' ', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
            {
                {' ', 'b', ' ', ' '},
                {'b', 'b', ' ', ' '},
                {' ', 'b', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
            {
                {' ', 'b', ' ', ' '},
                {'b', 'b', 'b', ' '},
                {' ', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
            {
                {' ', 'b', ' ', ' '},
                {' ', 'b', 'b', ' '},
                {' ', 'b', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
        },
        {
            {
                {'c', 'c', 'c', ' '},
                {'c', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
            {
                {'c', 'c', ' ', ' '},
                {' ', 'c', ' ', ' '},
                {' ', 'c', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
            {
                {' ', ' ', 'c', ' '},
                {'c', 'c', 'c', ' '},
                {' ', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
            {
                {' ', 'c', ' ', ' '},
                {' ', 'c', ' ', ' '},
                {' ', 'c', 'c', ' '},
                {' ', ' ', ' ', ' '},
            },
        },
        {
            {
                {' ', 'd', 'd', ' '},
                {'d', 'd', ' ', ' '},
                {' ', ' ', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
            {
                {'d', ' ', ' ', ' '},
                {'d', 'd', ' ', ' '},
                {' ', 'd', ' ', ' '},
                {' ', ' ', ' ', ' '},
            },
        }
    }

    mapLength = 10
    mapHeight = 18

    maxStepTime = 0.5
    levelTimer = 0

    offsetX = 2.5
    offsetY = 4

    nextPieceShape = love.math.random(1, 4)
    score = 0

    sleeping = false
    sleepTimer = 0

    sounds = {}
    sounds.space = love.audio.newSource("assets/space.wav", "static")
    sounds.music = love.audio.newSource("assets/background.mp3", "stream")

    sounds.music:setLooping(true)
    sounds.music:play()

    boom = love.graphics.newImage("assets/boom-sheet.png")
    animation = newAnimation(boom, math.floor(boom:getWidth() / 4), math.floor(boom:getHeight() / 2), 1)
    shouldAnimate = false

    prepareGame()
end

function love.draw()
    if (shouldAnimate) then
        local spriteNum = math.floor(animation.currentTime / animation.duration * #animation.quads) + 1
        love.graphics.draw(animation.spriteSheet, animation.quads[spriteNum], 50, 50, 0, 1, 1)
    end
    drawMapBackground()
    drawPiece(pieceX + offsetX, pieceY + offsetY, pieceShape, pieceRotation)
    drawPiece(5, 1, nextPieceShape, 1)
end

function love.update(dt)
    if shouldAnimate == true then
        animation.currentTime = animation.currentTime + dt
        if animation.currentTime >= animation.duration then
            animation.currentTime = 0
            shouldAnimate = false
        end
    end

    levelTimer = levelTimer + dt
    timer = timer + dt

    if timer >= maxStepTime then
        timer = 0

        local tmpY = pieceY + 1
        if canPieceMove(pieceX, tmpY, pieceRotation) then
            pieceY = tmpY
        else
            setPieceToBackground()
            checkIfRowsCompleted()
            newPiece()

            if not canPieceMove(pieceX, pieceY, pieceRotation) then
                gameOver()
            end
        end
    end

    if levelTimer > 15 then
        maxStepTime = maxStepTime - 0.05
        levelTimer = 0
    end
end

function love.keypressed(key)
    if key == 'up' then
        actionsUp()
    elseif key == 'down' then
        actionsDown()
    elseif key == 'left' then
        actionsLeft()
    elseif key == 'right' then
        actionsRight()
    elseif key == 'space' then
        sounds.space:play()
        actionsSpace()
    elseif key == 's' then
        saveGame()
    elseif key == 'l' then
        loadGame()
    elseif key == 'm' then
        sounds.music:stop()
    end
end
