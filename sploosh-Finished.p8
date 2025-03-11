pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
	level=0
	levels=2
	
	--all this also in respawn()
	state="start"
	putbacks={}
	iplr()
	anitimer=10
	ienemies()
	ipickups()
	bullets={} -- lista de disparos
	boba=3
	soundclear=true

end


function _update()

	if state=="play" then
		uplr()
		upickups()
		uhazards()
		uenemies()
		udoors()
		update_bullets()
		
	elseif state=="dead" then
		if btnp(❎) then
			respawn()
		end
		
	elseif state=="start" then
		if btnp(❎) then
			state="play"
		end
		
	elseif state=="win" then
	
		if btnp(❎) then
			if level<levels then
				level+=1
				respawn()
			else
				level=0
				respawn()
			end
		end
	end
	
end


function _draw()
	cls()
	
	camera(128*level,0)--offsets game
		map()
		dplr()
		denemies()
		draw_bullets()
		
	camera(0,0)--doesn't offset ui
		dpickups()
		
	--pop up messages--
	if state=="dead" then
		rectfill(38,58,88,66,1)
		print("you are dead",40,60,7)
	elseif state=="start" then
		rectfill(38,58,88,66,1)
		print("press ❎",48,60,7)
	elseif state=="win" then
		rectfill(38,58,88,66,1)
		print("you win!",48,60,7)
	end
	
end
-->8
--player--
function iplr()
--setup our player

	plr={
		x=20+128*level,
		y=20,
		dx=0, --direction x
		f=false, --flip x
		state="idle",
		sp=1 --sprite
	}
	
	jcd=0 --jump cooldown
	jforce=0--jump force
	
	gravity=2

end

function uplr()

--save player x loc
	local lx=plr.x

--how the plr responds to ctrls
	if btn(➡️) then
		plr.dx=1
		plr.f=false
		plr.state="crawl"

	elseif btn(⬅️) then
		plr.dx=-1
		plr.f=true
		plr.state="crawl"
		
	else
		plr.dx=0
		plr.state="idle"
	end
	
	if btnp(❎) then
		if onground() then
			jcd=5
		end
	end
	
	if btn(❎) then
	--jump
		if jcd>0 then
			jforce=8
			jcd-=1
		end
	end
	
	if btnp(🅾️) then -- ataque
		shoot()
 end
	
	--move player lr
	plr.x+=plr.dx
	
	--if col x move back
	if collidex() then
		plr.x=lx
	end
	
	--gravity
	if not onground() then
		plr.y+=gravity
		plr.state="jump"

	end
	
	--fix intersecting w/floor
	for i=1,gravity do
		if inground() then
			plr.y-=1
		end
	end--for
	
	
	--apply jforce
		if jforce>0 then
			jforce-=1
		end
		
		plr.y-=jforce
		
		if colceil() then
			jforce=0
			jcd=0
		end
		
		animate_plr()
	
end--uplr

function dplr()
--draw what the player is doing
	spr(plr.sp,plr.x,plr.y,1,1,plr.f)
end

function onground()
	local ptxl=(plr.x+2)/8
	local ptxr=(plr.x+5)/8
	local pty=(plr.y+8)/8
	
	if mget(ptxl,pty)==10 or mget(ptxr,pty)==10 then
		return true
	else
		return false
	end
end

function collidex()
--collides with walls
	local ptxl=(plr.x+2)/8
	local ptxr=(plr.x+5)/8
	local pty=(plr.y+5)/8
	
	if mget(ptxl,pty)==10 or mget(ptxr,pty)==10 then
		return true
	else
		return false
	end
	
end

function colceil()
	local ptxl=(plr.x+2)/8
	local ptxr=(plr.x+5)/8
	local pty=(plr.y+2)/8
	
	if mget(ptxl,pty)==10 or mget(ptxr,pty)==10 then
		return true
	else
		return false
	end
	
end

function inground()
	local ptxl=(plr.x+2)/8
	local ptxr=(plr.x+5)/8
	local pty=(plr.y+7)/8
	
	if mget(ptxl,pty)==10 or mget(ptxr,pty)==10 then
		return true
	else
		return false
	end
end
-->8
--animation--

function animate_plr()

--handle animation state

	if plr.state=="idle" then
		plr.sp=1

	elseif plr.state=="crawl" then

		--crawl animation
		if plr.sp<4.7 then
			plr.sp+=.3
		else
			plr.sp=1
		end
		
	elseif plr.state=="jump" then
		plr.sp=17
	end--ani state



end--animate_plr
-->8
--interactables--

function ipickups()
		for x=0,47 do
			for y=0,15 do
				if mget(x,y)==13 then
					add(putbacks,{
						tx=x,
						ty=y,
						sp=13
					})
				end
			end--fory
		end--forx
end

function upickups()

	local ptx=(plr.x+4)/8
	local pty=(plr.y+5)/8
	
	if mget(ptx,pty)==13 then
		mset(ptx,pty,9)
		boba-=1
		sfx(2)
		soundclear=true
	end
end

function dpickups()
	print("boba: "..boba)
end

function udoors()

	local ptx=(plr.x+4)/8
	local pty=(plr.y+5)/8
	
	if mget(ptx,pty)==14 then
		if boba==0 then
			state="win"
				if soundclear then
					sfx(1)
					soundclear=false
				end
		else
			if soundclear then
				sfx(0)
				soundclear=false
			end
		end
	else
		soundclear=true
	end
end
-->8
--danger--

--enemies--

function ienemies()

	enemies={}

--loop thru tiles and find enemies
		for x=0,47 do
			for y=0,15 do
				if mget(x,y)==25 then
				
					add(putbacks,{
						tx=x,
						ty=y,
						sp=25
					})

					mset(x,y,9)--delete tile
					
					--add an enemy here
					add(enemies,{
						ex=x*8,
						ey=y*8,
						sp=26,
						f=true,
						ox=x*8,--orign on x
						dx=1 --direction on x
					})
					
				end
			end--fory
		end--forx
end

function uenemies()
	for e in all(enemies) do
		
		--move back and forth
		if abs(e.ex-e.ox)>16 then
			e.dx=e.dx*-1
		end
		e.ex+=e.dx*.5--add direction
		
		--animate enemies
		if anitimer<=0 then
			if e.sp==26 then
				e.sp=27
			else
				e.sp=26
			end
		end
		
		--flip enemies
		if e.dx>0 then
			e.f=true
		else
			e.f=false
		end
		
		--test if touching plr
		
		if abs(plr.x-e.ex)<8 and abs(plr.y-e.ey)<8 then
			plr.sp=18
			state="dead"
		end
		
	end
end

function denemies()
	for e in all(enemies) do
		spr(e.sp,e.ex,e.ey,1,1,e.f)
	end
end



--hazards--

function uhazards()

	local ptx=(plr.x+4)/8
	local pty=(plr.y+5)/8
	
	if mget(ptx,pty)==28 or mget(ptx,pty)==29 then
		plr.sp=18
		state="dead"
	end
	
	--animate tiles
	if anitimer<=0 then
		--animate lava
		for x=0,47 do
			for y=0,15 do
				if mget(x,y)==28 then
					mset(x,y,29)
				elseif mget(x,y)==29 then
					mset(x,y,28)
				end
			end--fory
		end--forx
		anitimer=10
	else
		anitimer-=1
	end
	
end
-->8
--respawn--

function respawn()

	--put back tiles--
	for t in all(putbacks) do
		mset(t.tx,t.ty,t.sp)
		del(putbacks,t)
	end
	
	state="start"
	putbacks={}
	iplr()
	anitimer=10
	ienemies()
	ipickups()
	boba=3
	soundclear=true

end
-->8
-- bullets --
function shoot()
    local bx = plr.x + (plr.f and -4 or 8)
    add(bullets, {x=bx, y=plr.y+4, dx=plr.f and -2 or 2, size=4}) -- Agregar tamaれねo de bala
    sfx(3)
end

function update_bullets()
    for b in all(bullets) do
        b.x += b.dx
        if b.x < 0 or b.x > 128 then
            del(bullets, b)
        else
            for e in all(enemies) do
                if abs(b.x - e.ex) < b.size and abs(b.y - e.ey) < b.size then -- Usar el tamaれねo de la bala
                    del(enemies, e)
                    del(bullets, b)
                    sfx(4)
                    break
                end
            end
        end
    end
end

function draw_bullets()
    for b in all(bullets) do
        circfill(b.x, b.y, b.size, 6) -- Usar el tamaれねo de la bala
		      circfill(b.x, b.y, b.size/1.5, 7)
    end
end

__gfx__
0000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccffffffcccbbbccccccccccccc55511c1111111100000000
0000000000000000000000000000000000000000000000000000000000000000cccccccccccccccc2444444fc33bbbccccccccccc5771d1c1dddddd100000000
0070070000001110000111000011100000011100000000000000000000000000ccc777cccccccccc2444444fc333bbcccccccccc1791d1711dddddd100000000
0007700000017bb10017bb10017bb1000017bb10000000000000000000000000cc77777ccccccccc2444444fcc333bcccccccccc1a7777611dddddd100000000
000770000017bba1017bba1017bba100017bba1000000000000000000000000077777777cccccccc2444444fcccc24cccccccb3c19aaa9611dddd1d100000000
00700700001bbbb101bbbb101bbbb10001bbbb10000000000000000000000000cccccccccccccccc2454545fcccc24ccccbcb3ccc169aa1c1dddddd100000000
0000000001bb331001bb33101bb3310001bb3310000000000000000000000000cccccccccccccccc2545454fccc24ccccc3b3cccc16aa91c1dddddd100000000
000000001b3331001b3331001b3331001b333100000000000000000000000000ccccccccccccccccc222222cccc24cccccc33ccccc1111cc1dddddd100000000
000000000000111000000000000000000000000000000000000000000000000000000000cccccccc00000000000000009999cccccccc99990000000000000000
0000000000017bb100000000000000000000000000000000000000000000000000000000c1111ccc011110000000000098999899998999890000000000000000
000000000017bba100000000000000000000000000000000000000000000000000000000189991cc1b8881000111100099989998899989990000000000000000
00000000001bbbb1000000000000000000000000000000000000000000000000000000001999891c1888b8101b88810099999999999999990000000000000000
00000000001b33100000111000000000000000000000000000000000000000000000000017179991171788811888b81098989898898989890000000000000000
00000000001b331000017bb1000000000000000000000000000000000000000000000000c1c19991010188811717888189898989989898980000000000000000
0000000001b331000117bb5100000000000000000000000000000000000000000000000017179991171788811717888198989898898989890000000000000000
00000000001110001333bbb10000000000000000000000000000000000000000000000001999991c188888101888881088888888888888880000000000000000
__gff__
0000000000000000000001000002000000000000000000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0a0909090909090909090909090909090a0a0a0a090909090909090909090a0a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0909090908090908090909090909090a09090909090909080909090909090a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0d09090909090909090908090909090a09090909090909090909090909090a090a0a090909080909090a0a0909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a09090908090909090909090909090a090908090909090909090d0909090a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0909090909090a0a0a09090909090a0a090909090809090909090909090a0909080909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a0a0a09090909090909090909090a0a0a0a0a090909090a0a0a0909090a090909090919090d09090909090d09190000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a09090909090909090909090d19090c0a0a0a0909090909090909090909090a0909090a0a0a0a0a09090809090a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0909090d0908090909090a0a0a0a0a0a090a09090a0a09090909090809090a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0909090a0a09090a0a0909090909090a090a0909090909090909090909090a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0909090909090909090909090909090a090909080909090a090919090d090a090909090909090909090d090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0919090909090909090909090909090a090909090909090a0a0a0a0a0a090a0909080909090909090a0a0a0909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a0a0a09090909090909090909090a0909090909090a090909090909090a0909090909090809090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a09090909090a09090909190909090e0a0909090a0909090909090909090e0a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a090a1c1c1c1c1c1c0a0a0a0a0a0a0a0a090d090909090909190909090a0a0a0909090909090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0909090a0a0a0a0a0909090a0e09090919090909090909090909090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a1c1c1c1c1c1c1c1c1c1c1c1c1c1c0a0a0a0a0a0a0a0a1c1c1c1c1c1c1c1c0a0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400002605000000000001005002000000000205000000080000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700001b7501b7501f7502275022750227501f7501f7501d7501d7501d7501d7501f75024750277502b7503075033750337503375033740337403374033740337403373033720337101b750007001b75013700
000600000f75011700227501d70024700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
