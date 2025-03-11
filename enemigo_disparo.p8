pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function _init()
    putbacks = {} -- Inicializar putbacks correctamente
    enemies = {} -- Inicializar enemigos correctamente
    
    init_enemies() -- Llamar antes de cualquier acceso a enemies
    fix_corner_stick = true
    bullets = {}

    plr = { 
        x = 20, 
        y = 20, 
        dx = 0, 
        dy = 0, 
        f = false, 
        gravity = 0.2, 
        jforce = 0,
        jcd = 0, -- Jump cooldown
        state = "idle",
        sp = 1,
        health = 3,
        pickups = 0,
        score = 0
    }
    soundclear=true
    init_hud()
     
end

function _update()
   
    update_player()
    update_bullets()
    update_enemies()
    check_player_enemy_collision()

    if soundclear then
        sfx(5,1)
        soundclear=false
    end

    --if not stat(57) then
    --    music(0)
    --end
    
    update_hud()
				
end

function _draw()
    cls()
    map()
    draw_player()
    draw_bullets()
    draw_enemies()
    draw_hud()
end

-->8
--player--


function update_player()
    -- Si el jugador estれく en el aire, establecer estado en "jump"
    if not onground() then
        plr.state = "jump"
    elseif plr.dx != 0 then
        plr.state = "crawl"
    else
        plr.state = "idle"
    end

    -- Control de movimiento horizontal
    if btn(➡️) then 
        plr.dx = 1 
        plr.f = false
    elseif btn(⬅️) then 
        plr.dx = -1 
        plr.f = true
    else 
        plr.dx = 0
    end

    -- Control de salto
    if btnp(❎) and onground() then
        plr.jcd = 5 -- Set jump cooldown
    end

    if btn(❎) and plr.jcd > 0 then
        plr.jforce = -4 -- Apply jump force
        plr.jcd -= 1
    end

    -- Aplicar gravedad y fuerza de salto
    plr.dy += plr.gravity
    local new_y = plr.y + plr.dy + plr.jforce

    -- Si colisiona con el techo, detener el salto
    if collide_top(new_y) then
        plr.jforce = 0
        plr.dy = 0
        if fix_corner_stick then
            plr.y += 1
        end
    else
        plr.y = new_y
    end

    -- Reducir la fuerza de salto progresivamente
    if plr.jforce < 0 then
        plr.jforce += 0.3
    end

    -- Colisiれはn con el suelo
    if onground() then
        plr.y = flr(plr.y / 8) * 8
        plr.dy = 0
        plr.jforce = 0
        plr.jcd = 0
    end

    -- Movimiento horizontal con colisiれはn
    local new_x = plr.x + plr.dx
    if not collidex(new_x) then
        plr.x = new_x
    end

    animate_plr()

    if btnp(🅾️) then shoot() end
end


function draw_player()
    spr(plr.sp, plr.x, plr.y, 1, 1, plr.f)
end

function reset_player(damage)
    plr.x = 20
    plr.y = 20
    plr.dx = 0
    plr.dy = 0
    plr.jforce = 0
    plr.health -= damage
end

function is_tile_map(tx, ty)
    return fget(mget(tx, ty), 0)
end

function onground()
    local ptxl = flr((plr.x + 2) / 8)
    local ptxr = flr((plr.x + 5) / 8)
    local pty = flr((plr.y + 8) / 8)
    return is_tile_map(ptxl, pty)  or is_tile_map(ptxr, pty) 
    
end

function collidex(new_x)
    local pty = flr((plr.y + 5) / 8) -- Altura del personaje
    local ptxl = flr((new_x + 2) / 8) -- Lado izquierdo
    local ptxr = flr((new_x + 5) / 8) -- Lado derecho
    return is_tile_map(ptxl, pty) or is_tile_map(ptxr, pty)
end

function collide_top(new_y)
    local ptxl = flr((plr.x + 2) / 8) -- Lado izquierdo
    local ptxr = flr((plr.x + 5) / 8) -- Lado derecho
    local pty = flr((new_y) / 8) -- Arriba del jugador

    local left_collision = is_tile_map(ptxl, pty)
    local right_collision = is_tile_map(ptxr, pty)

    -- Si la variable global estれく activada, corregir el bug de quedarse pegado en esquinas
    if fix_corner_stick then
        return left_collision or right_collision
    else
        -- Si estれく desactivado, permitir quedarse pegado en esquinas
        return (left_collision and right_collision)
    end
end



-->8
--animation--

function animate_plr()
    if plr.state == "idle" then
        plr.sp = 1
    elseif plr.state == "crawl" then
        if plr.sp < 4.7 then
            plr.sp += 0.3
        else
            plr.sp = 1
        end
    elseif plr.state == "jump" then
        plr.sp = 17 -- Sprite de salto
    end
end


-->8
--danger--

--enemies--


function init_enemies()
    enemies = {} 

    for x = 0, 47 do
        for y = 0, 15 do
            if mget(x, y) == 25 then 
                add(putbacks, { tx = x, ty = y, sp = 25 }) 
                mset(x, y, 9) 

                add(enemies, {
                    x = x * 8, 
                    y = y * 8, 
                    sp = 26, 
                    frames = {26, 27}, -- Animaciれはn de movimiento
                    frame_timer = 0, -- Control de animaciれはn
                    f = true, 
                    ox = x * 8, 
                    dx = 1, 
                    speed = 0.5, 
                    turn_timer = 0, -- Timer para cambiar direcciれはn
                    dying = false,  -- Estado de destrucciれはn
                    death_timer = 0, -- Controla la animaciれはn antes de desaparecer
                    blink_timer = 0, -- Controla el parpadeo antes de desaparecer
                    value = 1
                })
            end
        end
    end
end




function update_enemies()
    for e in all(enemies) do
        if e.dying then
            update_enemy_destruction(e) -- Manejar animaciれはn de muerte
        else
            -- Calcular la nueva posiciれはn
            local new_x = e.x + e.dx * e.speed
            local new_y = e.y + 1 -- Simular gravedad

            -- Coordenadas para detecciれはn de colisiれはn
            local ptxl = flr((e.x + 2) / 8) -- Lado izquierdo
            local ptxr = flr((e.x + 5) / 8) -- Lado derecho
            local pty = flr((e.y + 8) / 8) -- Pies del enemigo
            local ground_left = is_tile_map(ptxl, pty) -- Suelo a la izquierda
            local ground_right = is_tile_map(ptxr, pty) -- Suelo a la derecha

            -- Verificar si el enemigo estれく en el aire y aplicar gravedad
            if not ground_left and not ground_right then
                e.y = new_y -- Dejar que caiga
            else
                -- Detectar si el enemigo estれく en el borde de una plataforma
                local ptxl_next = flr((new_x + 2) / 8)
                local ptxr_next = flr((new_x + 5) / 8)
                local ground_left_next = is_tile_map(ptxl_next, pty)
                local ground_right_next = is_tile_map(ptxr_next, pty)

                -- Si va a caer en el prれはximo paso, cambiar de direcciれはn
                if (not ground_left_next and e.dx < 0) or (not ground_right_next and e.dx > 0) then
                    e.turn_timer += 1
                    if e.turn_timer > 10 then -- Esperar 10 frames antes de girar
                        e.dx *= -1
                        e.f = not e.f -- Voltear sprite
                        e.turn_timer = 0 -- Reiniciar temporizador de giro
                    end
                else
                    e.turn_timer = 0 -- Si no estれく en el borde, resetear temporizador
                    e.x = new_x -- Mover enemigo
                end
            end

            -- **Animaciれはn normal del enemigo**
            e.frame_timer += 1
            if e.frame_timer > 10 then -- Cambia de sprite cada 10 frames
                if e.sp == e.frames[1] then
                    e.sp = e.frames[2]
                else
                    e.sp = e.frames[1]
                end
                e.frame_timer = 0 -- Resetear temporizador de animaciれはn
            end
        end
    end
end






function draw_enemies()
    for e in all(enemies) do
        spr(e.sp, e.x, e.y, 1, 1, e.f)
        --rect(e.x, e.y, e.x+7, e.y+7, 8) -- Dibuja la hitbox
    end
end


function check_player_enemy_collision()
    for e in all(enemies) do
        if abs(plr.x - e.x) < 6 and abs(plr.y - e.y) < 6 then
            reset_player(1) -- Funciれはn para manejar colisiれはn con el jugador
        
        end
    end
end

function update_enemy_destruction(e)
    sfx(3)
    e.death_timer += 1

    -- Animaciれはn de destrucciれはn (3 frames: 22, 23, 24)
    if e.death_timer < 6 then
        e.sp = 22
    elseif e.death_timer < 12 then
        e.sp = 23
    elseif e.death_timer < 18 then
        e.sp = 24
    else
        -- Fase de parpadeo antes de eliminar
        e.blink_timer += 1
        if e.blink_timer % 4 < 2 then
            e.sp = 0 -- Invisible
        else
            e.sp = 24 -- れあltimo frame de animaciれはn
        end

        -- Eliminar enemigo despuれたs de un tiempo
        if e.blink_timer > 16 then
            del(enemies, e)
            plr.score += e.value
            update_hud()
        end
    end
end





-->8
-- bullets --
function shoot()
    local bx = plr.x + (plr.f and -4 or 8)
    add(bullets, { x = bx, y = plr.y + 4, dx = plr.f and -2 or 2 })
    sfx(2)
end

function update_bullets()
    for b in all(bullets) do
        b.x += b.dx

        if b.x < 0 or b.x > 128 then 
            del(bullets, b) 
        end
        
        for e in all(enemies) do
            if abs(b.x - e.x) < 7 and abs(b.y - e.y) < 7 then
                -- Activar animaciれはn de destrucciれはn y detener movimiento
                e.dying = true
                e.dx = 0
                e.speed = 0
                e.death_timer = 0
                e.blink_timer = 0
                del(bullets, b) -- Eliminar la bala
                break
            end
        end
    end
end




function draw_bullets()
    for b in all(bullets) do
        circfill(b.x, b.y, 2, 6)
        circfill(b.x, b.y, 1, 7)
    end
end


-->8
-- hud --


function init_hud()
    -- puedes inicializar otros valores si necesitas mれくs lれはgica
    
    hud = {
	    x = 85, 
	    y = 2, -- posiciれはn en la pantalla
	    width = 40, 
	    height = 22, -- tamaれねo del recuadro
	    health = 3, -- vida inicial
	    score = 0, -- puntuaciれはn inicial
	    pickups = 0 -- recolectables iniciales
		}

end

function update_hud()
    -- aquれと puedes actualizar el hud con variables globales del jugador si lo deseas
    hud.health = plr.health
    hud.score = plr.score
    hud.pickups = plr.pickups
end

function draw_hud()
    -- dibujar el fondo del hud
    rectfill(hud.x, hud.y, hud.x + hud.width, hud.y + hud.height, 0) -- fondo oscuro

    -- dibujar iconos y valores
    print("♥"..hud.health, hud.x + 3, hud.y + 2, 8)  -- vida (rojo)
    print("★"..hud.score, hud.x + 3, hud.y + 8, 10) -- puntos (amarillo)
    print("●"..hud.pickups, hud.x + 3, hud.y + 16, 11) -- frutas (verde)
end

__gfx__
0000000000111000000000000011100000111000000000000000000000000000dddddddddddddddd0ffffff000bbb000dddddddddd55511dd111111d00000000
00000000017bb10000111000017bb100017bb100000000000000000000000000dddddddddddddddd2444444f033bbb00ddddddddd5771e1d11cccc1100000000
0070070001bba100017bb10001bba10001bba100000000000000000000000000dddeeedddddddddd2444444f0333bb00dddddddd1791e1711cccccc100000000
0007700001bbb10001bba10001bbb10001bbb100000000000000000000000000ddeeeeeddddddddd2444444f00333b00dddddddd1a7777611ccc676100000000
000770000133335501bbb1000133335501333355000000000000000000000000eeeeeeeedddddddd2444444f00002400dddddb3d19aaa9611ccc777100000000
0070070000131150013333550013115000131150000000000000000000000000dddddddddddddddd2454545f00002400ddbdb3ddd169aa1d1ccc676100000000
0000000000111000001311500011100000111000000000000000000000000000dddddddddddddddd2545454f00024000dd3b3dddd16aa91d1cccccc100000000
0000000000101000001001000001010000100100000000000000000000000000dddddddddddddddd0222222000024000ddd33ddddd1111dd1cccccc100000000
0000000000111000000000000000000000000000000000000000000000000000000000000000000000000000000000009999dddddddd99990000000000000000
00000000017bb1000000000000000000000000000000000001111000011110000111100001111000011110000000000098999899998999890000000000000000
0000000001bba100000000000001110000000000000000001b8891001b9891001a999100189991001b8881000111100099989998899989990000000000000000
0000000011bbb155000000000017bb1000000000000000001988b9101989b9101999a910199989101888b8101b88810099999999999999990000000000000000
000000000133335000001110017bba10000000000000000017179881171799811717999117179991171788811888b81098989898898989890000000000000000
000000000013110000017bb101bbbb10000000000000000001018981010189910101999101019991010188811717888189898989989898980000000000000000
00000000001110000117bb5101bb3310000000000000000017179891171798811717999117179991171788811717888198989898898989890000000000000000
00000000010001001333bbb11b333100000000000000000018888810188888101999991019999910188888101888881088888888888888880000000000000000
0000000000000000000000000000000000000000000000000000000000000000dcccccccdccccccc000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000c1111111c1111111000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000c111111cc111111c000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000cd000000cd000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001111101111111011000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000cc100ccccc100ccc000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001111c1111111c111000000000000000000000000000000000000000000000000
__gff__
0000000000000000000001000002000000000000000000000000000004040000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
292929292909090909090909090909090a0a0a0a090909090909090909090a0a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
290909090908090908090909090909090a09090909090909080909090909090a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
290909090909090909090908090909090a09090909090909090909090909090a090a0a090909080909090a0a0909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292909090908090909090909090909090a090908090909090909090d0909090a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292909090909090929292909090909090a0a090909090809090909090909090a0909080909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292929292909090909090909090909090a0a0a0a0a090909090a0a0a0909090a090909090919090d09090909090d09190000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2909090909090909090909090919090c0a0a0a0909090909090909090909090a0909090a0a0a0a0a09090809090a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2909090909090809090909292929292928090a09090a0a09090909090809090a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
290909092929090929290909090909090a090a0909090909090909090909090a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
290909090909090909090909090909090a090909080909090a090919090d090a090909090909090909090d090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
290919090909090909090909090909090a090909090909090a0a0a0a0a0a090a0909080909090909090a0a0a0909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
282929292909090909090909090909090a0909090909090a090909090909090a0909090909090809090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2909090909092909090909090909190e0a0909090a0909090909090909090e0a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2909291c1c1c1c1c1c292929292929290a090d090909090909190909090a0a0a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292929292929292929292929292929290a0a0a0a0909090a0a0a0a0a0909090a0e09090919090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
292929292929292929292929292929290a1c1c1c1c1c1c1c1c1c1c1c1c1c1c0a0a0a0a0a0a0a0a1c1c1c1c1c1c1c1c0a0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400002605000000000001005002000000000205000000080000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700001b7501b7501f7502275022750227501f7501f7501d7501d7501d7501d7501f75024750277502b7503075033750337503375033740337403374033740337403373033720337101b750007001b75013700
000600000e15008150212501d70024700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000162007640083400432000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000021550000002255000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000c0500c0500c0500c0500f0500f05011050110500f0500f05011050110501105011050160501605014050140501305011050130501300013050130501605016050180501805011050110500f0500f050
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0020000018d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
