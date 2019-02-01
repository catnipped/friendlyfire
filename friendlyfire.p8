pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--todo
--  enemy behavior patterns
--  damage system (collision)
--	shield system
--  dash
--  wave system
--  design wave 1-10
--  menu 
--  highscores
--  ui


--init and help functions below
function _init()
	const = {
		bounds = {
			{x = 200, y = 350, w = 200, h = 100},
			{x = 200, y = 200, w = 200, h = 100}
		},
		limits = {
			x1 = 100, x2 = 600, y1 = 100, y2 = 550
		},
		vector = {
			up = {0,-1},
			down = {0,1}
		},
		stars = initstars(64,3)
	}

	const = protect(const)

	state = {
		score = 0,
		lives = 3,
		players = {
			{ id = 1,
				type = "player", 
				x = const.bounds[1].x+100, 
				y = const.bounds[1].y+50, 
				rad = 3, 
				vx = 0, 
				vy = 0,
				cam = {
					x = const.bounds[1].x+100, 
					y = const.bounds[1].y+50, 
				},
				shield = true, 
				shieldrad = 9, 
				projdir = const.vector.up, 
				cooldown = -1, 
				rateoffire = {0,0.3} 
			},
			{ id = 2, 
				type = "player",
				x = const.bounds[2].x+100, 
				y = const.bounds[2].y+50,  
				rad = 3, 
				vx = 0, 
				vy = 0, 
				cam = {
					x = const.bounds[2].x+100, 
					y = const.bounds[2].y+50, 
				},
				shield = true,
				shieldrad = 9, 
				projdir = const.vector.down, 
				cooldown = -1, 
				rateoffire = {0,0.2} 
			}
		},
		enemies = {},
		projectiles = {},
		animations = {},
		time = 0,
	}
	
	printh("init")
	for i = 1,4 do
		add(state.enemies, spawnenemy({const.bounds[2].x + rnd(200),const.bounds[2].y + rnd(200)},"alien"))
	end
end

function initstars(a,layer)
	local stars = {}
	for i = 1,layer do
		local l = {}
		for x = 1, a do
			add(l,{flr(rnd(256*i)),flr(rnd(256*i))})
		end
		stars[i] = l
	end
	return stars
end

function pythagorish(ax,ay,bx,by)
  local px = (bx-ax) * 0.001
  local py = (by-ay) * 0.001

  if abs(px) > 127 or abs(py) > 127 then
    return 100
  end
  return (px*px + py*py)
end

function sloppysqrt(x)
    s=((x/2)+x/(x/2)) / 2
    for i = 1,3 do
        s=(s+x/s)/2
		end
    return s
end

function every(duration,offset,period)
	local frames = flr(state.time * 60)
  local offset = offset or 0
  local period = period or 1
  local offset_frames = frames + offset
  return offset_frames % duration < period
end

function protect(tbl)
	return setmetatable({}, {
		__index = tbl,
		__newindex = function(t, key, value)
			error("attempting to change constant " ..
							tostring(key) .. " to " .. tostring(value), 2)
		end
	})
end

function ipairs (a)
  local function iter(a, i)
    i = i + 1
    local v = a[i]
    if v then
      return i, v
    end
  end
  return iter, a, 0
end

function funmap (things, fn)
	local mapped = {}
	for index, thing in pairs(things) do
		mapped[index] = fn(thing)
	end
	return mapped
end

function each (things, fn)
	for i, thing in ipairs(things) do
		fn(thing)
	end
end

function filter (things, fn)
	local filtered = {}
	each(things, function(thing)
		if fn(thing) then
			add(filtered, thing)
		end
	end)
	return filtered
end

function lerp(a,b,t)
 	local c = a + t * (b - a)
	return c
end


-->8
--update functions below
function  _update60()
	local lstate = state
	local events = {}
	local sectors = initsectors(20,20)
	sectors = updatesectors(sectors, state.players)
	sectors = updatesectors(sectors, state.enemies)
	sectors = updatesectors(sectors, state.projectiles)

	lstate.projectiles = updateprojectiles(lstate.projectiles, sectors)
	lstate.players = updateplayers(lstate.players, lstate.time, events, sectors)
	lstate.enemies = updateenemies(lstate.enemies, lstate.time, events, sectors)

	--printh(isinsector(state.players[1].x,state.players[1].y)[1] .. "/" .. isinsector(state.players[1].x,state.players[1].y)[2] )
	--printh(#myneighbours(state.players[1].x,state.players[1].y,sectors))

	events = returncollisions(events,lstate, sectors)
	events = updateevents(lstate,events)
	lstate.animations = updateanims(lstate.animations)
	lstate = cleanup(lstate)
	lstate.time += 1/60
	if every(rnd(1000)) and #lstate.enemies < 8 then
		add(state.enemies, spawnenemy({const.bounds[2].x + rnd(200),const.bounds[2].y + rnd(200)},"alien"))
	end
	if every(60) then lstate.score += 1 end
	state = lstate
--	printh("memory: ".. (stat(0)/1024))
end


-- SECTOR STUFF BELOW
function initsectors(width,height)
	local sectors = {}
	for x = -width,width do
		sectors[x] = {}
		for y = -height,height do
			sectors[x][y] = {}
		end
	end
	return sectors
end

function updatesectors(sectors, entities)
	for i in all(entities) do
		local sector = isinsector(i.x,i.y)
		if sectors[sector[1]] == nil then
			sectors[sector[2]] = {}
		end
		if sectors[sector[1]][sector[2]] == nil then
			sectors[sector[1]][sector[2]] = {}
		end
		add(sectors[sector[1]][sector[2]],i)
	end
	return sectors
end

function isinsector(x,y)
	local lx = mid(flr(x/25),-20,20)
	local ly = mid(flr(y/25),-20,20)
	return {lx,ly}
end

function myneighbours(ex,ey,sectors)
	local vector = isinsector(ex,ey)
	local entities = {}
	for x = vector[1]-1,vector[1]+1 do
		if x > 0 and x < 21 then
			for y = vector[2]-1,vector[2]+1 do
				if y > 0 and y < 21 then
					for i in all(sectors[x][y]) do
						add(entities,i)
					end
				end
			end
		end
	end
	return entities
end


function cleanup(state)
	local lstate = state
	-- lstate.enemies = filter(state.enemies, function(i)
	-- 	return i.death == true
	-- end)
	lstate.projectiles = filter(state.projectiles, function(i)
		return i.death == false
	end)

	return lstate
end

-- player
function updateplayers(p, time, events)
	local lps = p
	lps = funmap(lps, function(lp)
		local lbounds = const.bounds[lp.id]
		lp.x += lp.vx
		lp.y += lp.vy
		lp.vx = lerp(lp.vx, 0, 0.05)
		lp.vy = lerp(lp.vy, 0, 0.05)

		if btn(4,lp.id-1) and cooldowntimer(time, lp) then 
			local lproj = spawnprojectile(lp,11)
			lp.cooldown = time
			lp.rateoffire[1] = lp.rateoffire[2]
			add(events,{type = "projectile", object = lproj}) 
		elseif btn(4,lp.id-1) then
			lp.rateoffire[1] = lp.rateoffire[2]
		else
			lp.rateoffire[1] -= 0.05
		end
		if btn(2,lp.id-1) then lp.vy += -0.1 end
		if btn(3,lp.id-1) then lp.vy += 0.1 end
		if btn(0,lp.id-1) then lp.vx += -0.1 end
		if btn(1,lp.id-1) then lp.vx += 0.1 end
	
		if lp.x > (lbounds.x+lbounds.w) then lp.vx -= 0.15 end
		if lp.x < (lbounds.x) then lp.vx += 0.15 end
		if lp.y > (lbounds.y+lbounds.h) then lp.vy -= 0.15 end
		if lp.y < (lbounds.y) then lp.vy += 0.15 end
		lp.vy = mid(lp.vy, -4, 4)
		lp.vx = mid(lp.vx, -4, 4)
		lp.cam = updatecam(lp)
		return lp
	end)
	return lps
end

function cooldowntimer(time, p)
	if time - p.cooldown < p.rateoffire[1] then
		return false
	else
		return true
	end
end

function updatecam(p)
	local lcam = p.cam
	local lbounds = const.bounds[p.id]
	lcam.x = flr(lerp(lcam.x,p.x,0.2))
	lcam.y = flr(lerp(lcam.y,p.y,0.2))
	return lcam
end

-- collisions
function returncollisions(events, state, sectors)
	local levents = {}
	each(state.projectiles, function(i)
		if every(4,(isinsector(i.x,i.y)[2] % 4)) then
			local collision = projcollisioncheck(i, sectors)
			if collision ~= nil then
				i.death = true
				add(levents, {type = "collision", object = collision})
			else
				i.death = false
			end
		end
	end)
	
	for i in all(events) do
		add(levents,i)
	end
	return levents
end

function collisioncheck(ax, ay, bx, by, ar, br)
	local length = min(ar+br,101)*0.001
	return pythagorish(ax, ay, bx, by) < (length^2)
end

function projcollisioncheck(proj,sectors)
	collision = nil
	local neighbours = myneighbours(proj.x,proj.y,sectors)
	each(neighbours, function(i)
		local lrad = i.rad
		if i.shield then lrad = i.shieldrad end
		if collisioncheck(i.x,i.y,proj.x,proj.y,lrad,proj.rad) and (i.id ~= proj.id) and i.type ~= "projectile" then
			printh("collision!")
			collision = {
				x = proj.x,
				y = proj.y,
				hit = i
			}
		end
	end)

	return collision
end

-- projectile
function spawnprojectile(p,color)
	local proj = { 
		id = p.id,
		type = "projectile", 
		x = p.x, 
		y =  p.y,
		rad = 2, 
		vector = p.projdir,  
		velocity = 1.2, 
		color = color,
		death = false, 
	}
	proj.x += proj.vector[1] * 8
	proj.y += proj.vector[2] * 8
	return proj
end

function updateprojectiles(projs, sectors)
	local lprojs = {}
	if #projs > 0 then
		lprojs = funmap(projs, function(lproj)
			lproj.x += lproj.vector[1] * lproj.velocity
			lproj.y += lproj.vector[2] * lproj.velocity
			return lproj
		end)
		lprojs = filter(lprojs, function (i)
			return outofbounds(i,const.limits) == false
		end)
		lprojs = filter(lprojs, function (i)
			return #lprojs < 100
		end)
	end
	return lprojs
end

function outofbounds(object,limits)
	return (object.x > limits.x2) or (object.x < limits.x1) or (object.y > limits.y2) or (object.y < limits.y1) 
end


-- enemy
function spawnenemy(pos,type,state)
	local enemy = {}
	if type == "alien" then
		enemy = { 
			id = flr(rnd(1000)),
			type ="enemy",
			hp = 3, 
			x = pos[1], 
			y =  pos[2],
			rad = 6,   
			vector = {0,0},
			projdir = {0,0},
			velocity = 0.3,
			movement = function(enemy, time, events)
				local closestplayer = getclosestplayer(enemy.x,enemy.y)
				local directionofplayer = normalizedvectora2b(enemy,closestplayer,enemy.vector)
				enemy.vector = {
					lerp(enemy.vector[1],directionofplayer[1],0.01),
					lerp(enemy.vector[2],directionofplayer[2],0.01),
				}
				if every(flr(rnd(360+1000))) and stat(1) < 0.9 then
					enemy.projdir = directionofplayer
					local lproj = spawnprojectile(enemy,8)
					add(events,{type = "projectile", object = lproj}) 
				end
	--			enemy.vector = {sin(time%1),sin(time%1)}
			end,
			gfx = function(enemy)
				spr(6,enemy.x-3,enemy.y-4) 
			end
		}
	end
	return enemy
end

function getclosestplayer(x,y)
	local p = {x = 0, y = 0}
	local p1 = state.players[1]
	local p2 = state.players[2]
	local distance1 = abs((p1.x+p1.y)-(x+y))
	local distance2 = abs((p2.x+p2.y)-(x+y))

	if distance1 < distance2 then
		p = p1
	elseif distance2 < distance1 then
		p = p2
	end
	return p
end


function normalizedvectora2b(entitya,entityb,vector)
	local magnitude = abs(sloppysqrt(pythagorish(entitya.x,entitya.y,entityb.x,entityb.y))) * 1000
	if magnitude > 0 then
		vector = {(entityb.x-entitya.x)/magnitude,(entityb.y-entitya.y)/magnitude}
	end
	return vector
end

function updateenemies(e, time, events, sectors)
	local les = {}
	les = filter(e, function(le)
		local neighbours = myneighbours(le.x,le.y,sectors)
		each(neighbours, function(i)
			if (i ~= le) and collisioncheck(le.x, le.y, i.x, i.y, le.rad, i.rad) then
				local vector = normalizedvectora2b(le,i,le.vector)
				le.x -= vector[1] * (le.velocity *3)
				le.y -= vector[2] * (le.velocity *3)
			end
		end)
		
		le.x += le.vector[1] * le.velocity
		le.y += le.vector[2] * le.velocity
		
		le.movement(le,time,events)
		if le.hp <= 0 then 
			add(events,{type="animation", object = spawngfx("explosion",le.x,le.y)})
		end
		
		return le.hp > 0
	end)
	return les
end

--events

function updateevents(state,events)
	local lstate = state
	local newprojs = filter(events, function (i) 
		return i.type == "projectile"
	end)

	each (newprojs, function (i)
		add(lstate.projectiles, i.object)
		local object = spawngfx("flare",i.object.x,i.object.y)
		add(lstate.animations,object)
	end)


	local collisions = filter(events, function (i) 
		return i.type == "collision"
	end)

	each (collisions, function (i)
		local projcolgfx = spawngfx("projcol",i.object.x,i.object.y)
		add(lstate.animations,projcolgfx)
		local hitgfx = spawngfx("ehit",i.object.hit.x,i.object.hit.y)
		add(lstate.animations,hitgfx)
	
		if i.object.hit.type == "enemy" then
			for e in all(lstate.enemies) do
				if i.object.hit.id == e.id then
					e.hp -= 1
				end
			end
		end
		if i.object.hit == lstate.players[1] or i.object.hit == lstate.players[2] then
			lstate.score = 0
		else
			lstate.score += 100
		end
	end)

		local anims = filter(events, function (i) 
		return i.type == "animation"
	end)

	each (anims, function (i)
		add(lstate.animations,i.object)
	end)

	return lstate
end

--animation
function updateanims(animations)
	local lanims = animations
	for i in all(lanims) do
		i.frame += 1
	end
	local lanims2 = filter(lanims, function(i)
		return i.frame < i.runtime
	end)
	return lanims2
end

function spawngfx(type, lx, ly)
	gfx = {}
	if type == "flare" then
		gfx = {
			frame = 0,
			runtime = 5,
			x = lx,
			y = ly,
			gfx = function(gfx)
				local clr = 7
				if every(3,0,2) then clr = 11 end
				circfill(gfx.x,gfx.y,6-gfx.frame/2,clr)
			end	
		}
	end
	if type == "explosion" then
		gfx = {
			frame = 0,
			runtime = 10,
			x = lx,
			y = ly,
			gfx = function(gfx)
				local clr = 0
				if every(2) then clr = 7+flr(rnd(2)) end
				circfill(gfx.x,gfx.y,1+gfx.frame,clr)
			end	
		}
	end
	if type == "ehit" then
		gfx = {
			frame = 0,
			runtime = 4,
			x = lx,
			y = ly,
			gfx = function(gfx)
				circfill(gfx.x,gfx.y,5,7+flr(rnd(2)))
			end	
		}
	end
	if type == "projcol" then
		gfx = {
			frame = 0,
			runtime = 5+rnd(5),
			x = lx,
			y = ly,
			rotation = rnd(1),
			gfx = function(a)
				local clrs = {7,14,11}
				if a.x ~= nil then
					for i = 1,7 do
						local rad = i/7
						local x2 = a.x + cos(rad+a.rotation) * (a.frame *0.9)
						local y2 = a.y + sin(rad+a.rotation) * (a.frame *0.9)
						line(a.x,a.y,x2,y2,clrs[flr(rnd(4))])
						-- circfill(a.x,a.y,1,0)
					end
				end
			end	
		}
	end
	return gfx
end

-->8
--draw functions below
function _draw()
	 if every(1) then cls() end

	drawplayerviewport(state.players[2],0,60,-16)
	drawplayerviewport(state.players[1],68,128,-112)
	
	clip()
	camera(0,0)
	
	drawui()
	
	camera(16+sin(state.time%1)*10,-84+cos(state.time%1)*10)
	-- if every(10) == false then palt(7,true) end
	-- if every(16) == false then palt(11,true) end
	-- if every(30) == false then palt(14,true) end
	-- if every(8) then pal(7,8) end
	-- for x = 36,0,-1 do
	-- 	for y = 0,10 do
	-- 		map(x,y,x*4+4*y,y*3-3*x,1,1)
	-- 	end
	-- end
end

function drawplayerviewport(p,y1,y2,yoffset)
	clip(0,y1,128,y2)
	camera(p.cam.x-64,p.cam.y+yoffset)
	pal()
	
	local cambounds = {x1 = p.cam.x-64, x2 = p.cam.x+64, y1 = p.cam.y+y1+yoffset, y2 = p.cam.y+y2+yoffset}

	drawstars(p)
	drawgrid(p)
	drawenemies(p,cambounds,y1,y2,yoffset)
	drawprojectiles(p,cambounds,y1,y2,yoffset)
	for anim in all(state.animations) do
		anim.gfx(anim)
	end
	for player in all(state.players) do
		drawplayer(player, p, y1, y2, yoffset)
	end
	pal()
end

function drawstars(p)
	local starcolors = {5,6,7}
	for l = 1,#const.stars do
		for s in all(const.stars[l]) do
				pset((p.cam.x / l+5)*0.9+s[1]-128,(p.cam.y / l+5)*0.9+s[2]-128,starcolors[l])
		end
	end
end

function drawgrid(p)
	local box = const.bounds[p.id]
		if every(2,0) then 
			for x = box.x,box.x+box.w,50 do
				line(x,box.y,x,box.y+box.h,5)
			end
			for y = box.y,box.y+box.h,50 do
				line(box.x,y,box.x+box.w,y,5)
			end
			-- rect(box.x,box.y,box.x+box.w,box.y+box.h,11) 
		end
		-- if every(30,3,5) then rect(box.x,box.y,box.x+box.w,box.y+box.h,14) end
end		

function drawenemies(p, cambounds,y1,y2,yoffset)
	for enemy in all(state.enemies) do
		if outofbounds(enemy,cambounds) then 
			local x = mid((enemy.x),p.cam.x-64,p.cam.x+59)
			local y = mid((enemy.y),p.cam.y+y1+yoffset+1,p.cam.y+y2+yoffset-4)
			palt(0,false)
			palt(15,true)
			if every(60,0,40) then spr(14,x-1,y-1) end
			pal()
		end
		enemy.gfx(enemy)
	end
end

function drawplayer (p1,p2,y1,y2,yoffset)
	local flipy = false
	if p2 ~= p1 then
		local x = mid((p1.x),p2.cam.x-64,p2.cam.x+59)
		local y = flr(mid((p1.y),p2.cam.y+y1+yoffset+1,p2.cam.y+y2+yoffset-4))
		palt(15,true)
		palt(0,false)
		if every(60,0,40) then spr(11+p1.id,x-1,y-1) end
		pal()
	end
	--if every(4,0,2) and p1.shield then circ(p1.x,p1.y,p1.shieldrad,3) end
	if p1.id == 2 then flipy = true end
	if btn(0,p1.id-1) then
		spr(2,p1.x-3,p1.y-8,1,2,true,flipy)
	elseif btn(1,p1.id-1) then
		spr(2,p1.x-3,p1.y-8,1,2,false,flipy)
	else
		spr(1,p1.x-3,p1.y-8,1,2,false,flipy)
	end
end

function drawprojectiles(p,cambounds,y1,y2,yoffset)
	
	for proj in all(state.projectiles) do

		if outofbounds(proj,cambounds) then 
			local x = mid((proj.x),p.cam.x-64,p.cam.x+63)
		 	local y = mid((proj.y),p.cam.y+y1+yoffset,p.cam.y+y2+yoffset-1)
			if every(30) then circfill(x,y,0,proj.color) end
		else
			local color = 7
			if every(3,0,2) then color = proj.color end
			circfill(proj.x,proj.y,1+flr(rnd(proj.rad)),color)
		end
	end
	
end

function drawscore (score, x, y)
 for n = 1,#score do
    local nr = 0 .. sub(score, n,n)
   	 spr(32+nr,((n-1)*10)+x,y)
	end
end

function drawui()
	rect(-1,61,128,67,5)
	drawscore("" .. state.score ,4,60)
	for i = 1,state.lives do 
		spr(3,128-i*8,62)
	end
	pal()
	--debug
	local percent = flr(stat(1)*100)
	print(percent .. "%", 4 , 4 , stat(1)*10)
end


__gfx__
000000000000000000000000000000000000000000000000007770000077000007700000000000000000000000000000f0000ffff00000fff00000ff00000000
00000000000000000000000007770700000000000000000007777700077e70007e8700000000000000000000000000000bbbb0ff0bbbbb0f0888880f00000000
00700700000700000007000077577000000000000000000078777870777ee70078070000000000000000000000000000f0bbb0fff0bbbb0f0880880f00000000
000770000077700000777000077707000000000000000000788788707ee8870007700000000000000000000000000000f0bbb0ff0bbbb0ff0888880f00000000
0007700000777000007770000000000000000000000000007887887007e87000000000000000000000000000000000000bbbbb0f0bbbbb0f0880880f00000000
007007000775770007775700000000000000000000000000078787000077000000000000000000000000000000000000f00000fff00000fff00f00ff00000000
000000000755570007755500000000000000000000000000077777000000000000000000000000000000000000000000ffffffffffffffffffffffff00000000
000000000775770007775700000000000000000000000000007770000000000000000000000000000000000000000000ffffffffffffffffffffffff00000000
07000000077777000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000007770000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000007770000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777077700777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000770007700770770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000700700070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777707777777777777777007777707777777777777777777777777777777777777777000000000000000000000000000000000000000000000000
70007007070000700007000700007007070700707000700070007000000700077000700770007007000000000000000000000000000000000000000000000000
70077007070000707777000700007007700700707000777770007777000700077000700770007007000000000000000000000000000000000000000000000000
70707007070000707000000700770007777777777000000770007007007000700777000770007007000000000000000000000000000000000000000000000000
77007007070000707000777700007007000700707777000770007007070007007000700777777007000000000000000000000000000000000000000000000000
70007007070000707000700000007007000700700007000770007007070007007000700700007007000000000000000000000000000000000000000000000000
77777777777777777777777777777777007777777777777777777777077777007777777777777777000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e777777b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee77bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeebbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000eb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3030300030300000303030003030300030303000303000003000000030003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000030003000003000003030000030003000300030003000000030003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300030300000003000003000000030003000300030003000000030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000030003000303030003030300030003000303000003030300000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300030303000303000003030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000300000300030003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300000300000303000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000030303000300030003030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
