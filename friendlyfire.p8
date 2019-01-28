pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- todo
-- �█� enemy behavior patterns
-- �█� enemy shoot
-- �█� damage system (collision)
-- �█� shield system
-- �█� dash
-- �█� wave system
-- �█� design wave 1-10
-- �█� menu 
-- �█� highscores
-- �█� ui

--init and help functions below
function _init()
	const = {
		bounds = {
			{x = -100, y = 64, w = 200, h = 100},
			{x = -100, y = -64, w = 200, h = 100}
		},
		limits = {
			x1 = -200, x2 = 300, y1 = -200, y2 = 200
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
				x = 100, 
				y = 100, 
				rad = 3, 
				vx = 0, 
				vy = 0,
				cam = {
					x = 0,
					y = 0
				},
				shield = true, 
				shieldrad = 9, 
				projdir = const.vector.up, 
				cooldown = -1, 
				rateoffire = {0,0.2} 
			},
			{ id = 2, 
				x = 0, 
				y = 0, 
				rad = 3, 
				vx = 0, 
				vy = 0, 
				cam = {
					x = 0,
					y = 0
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
		time = 0
	}
	printh("init")
	for i = 1,4 do
		add(state.enemies, spawnenemy({rnd(100),rnd(100)},"alien"))
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

function pythagoras(ax,ay,bx,by)
  local px = bx-ax
  local py = by-ay
  return sqrt(px*px + py*py)
end

function vectornormalize(vector)
		local lvector = {0,0}
		local len = sqrt(vector[1] * vector[1] + vector[2] * vector[2])
    if len ~= 0 and len ~= 1 then
        lvector[1] = vector[1] / len
        lvector[2] = vector[2] / len
    end
		return lvector
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
	lstate.players = updateplayers(lstate.players, lstate.time, events)
	lstate.enemies = updateenemies(lstate.enemies, lstate.time, events)
	lstate.projectiles = updateprojectiles(lstate.projectiles)
	events = returncollisions(events,lstate)
	events = updateevents(lstate,events)
	lstate.animations = updateanims(lstate.animations)
	lstate = cleanup(lstate)
	lstate.time += 1/60
	if every(rnd(60)) then lstate.score += flr(rnd(10)) end
	state = lstate
	events = {}
	if state.enemies[1].x > 300 then 
		printh(state.players[1].x .. "/" .. state.players[1].y) 
	end
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
			local lproj = spawnprojectile(lp)
			lp.cooldown = time
			lp.rateoffire[1] = lp.rateoffire[2]
			add(events,{type = "projectile", object = lproj}) 
		elseif btn(4,lp.id-1) then
			lp.rateoffire[1] = lp.rateoffire[2]
		else
			lp.rateoffire[1] -= 0.1
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
function returncollisions(events, state)
	local levents = {}
	each(state.projectiles, function(i)
		local collision = projcollisioncheck(i, state.players, state.enemies)
		if collision ~= nil then
			add(levents, {type = "collision", object = collision})
		end
	end)
	
	for i in all(events) do
		add(levents,i)
	end
	return levents
end

function collisioncheck(ax, ay, bx, by, ar, br)
	return pythagoras(ax, ay, bx, by) < (ar + br)
end

function projcollisioncheck(proj,players,enemies)
	collision = nil

	each(players, function(i)
		local lrad = i.rad
		if i.shield then lrad = i.shieldrad end
		if collisioncheck(i.x,i.y,proj.x,proj.y,lrad,proj.rad) and (i.id ~= proj.id) then
			printh("collision!")
			collision = {
				x = proj.x,
				y = proj.y,
			}
		end
	end)
	each(enemies, function(i)
		if collisioncheck(i.x,i.y,proj.x,proj.y,i.rad,proj.rad) and (i.id ~= proj.id) then
			printh("collision!")
			collision = {
				x = proj.x,
				y = proj.y,
			}
		end
	end)
	return collision
end

-- projectile
function spawnprojectile(p)
	local proj = { 
		id = p.id, 
		x = p.x, 
		y =  p.y,
		rad = 1, 
		vector = p.projdir,  
		velocity = 1.2, 
		gfx = 1,
		death = false, 
	}
	proj.x += proj.vector[1] * 8
	proj.y += proj.vector[2] * 8
	return proj
end

function updateprojectiles(projs)
	local lprojs = {}
	if #projs > 0 then
		lprojs = funmap(projs, function(lproj)
			lproj.x += lproj.vector[1] * lproj.velocity
			lproj.y += lproj.vector[2] * lproj.velocity
			local collision = projcollisioncheck(lproj, state.players, state.enemies)
			if collision == nil then
				lproj.death = false
			else
				lproj.death = true
			end
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
			id = 3,
			hp = 10, 
			x = pos[1], 
			y =  pos[2],
			rad = 6,   
			vector = {0,0},
			velocity = 0.3,
			movement = function(enemy,time)
				
				local closestplayer = getclosestplayer(enemy.x,enemy.y)
				local directionofplayer = normalizedvectora2b(enemy,closestplayer,enemy.vector)
				enemy.vector = {
					lerp(enemy.vector[1],directionofplayer[1],0.01),
					lerp(enemy.vector[2],directionofplayer[2],0.01),
				}
	--			enemy.vector = {sin(time%1),sin(time%1)}
			end,
			gfx = function(enemy)
				if every(20) then circfill(enemy.x,enemy.y,enemy.rad,8) end
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
	local magnitude = abs(pythagoras(entitya.x,entitya.y,entityb.x,entityb.y))
	if magnitude > 0 then
		vector = {(entityb.x-entitya.x)/magnitude,(entityb.y-entitya.y)/magnitude}
	end
	return vector
end

function updateenemies(e, time, events)
	local les = e
	les = funmap(les, function(le)
		each(les, function(i)
			if (i ~= le) and collisioncheck(le.x, le.y, i.x, i.y, le.rad, i.rad) then
				local vector = normalizedvectora2b(le,i,le.vector)
				le.x -= vector[1] * (le.velocity *3)
				le.y -= vector[2] * (le.velocity *3)
			end
		end)
		each(state.players, function(i)
			if (i ~= le) and collisioncheck(le.x, le.y, i.x, i.y, le.rad, i.rad) then
				local vector = normalizedvectora2b(le,i,le.vector)
				le.x -= vector[1] * (le.velocity *3)
				le.y -= vector[2] * (le.velocity *3)
			end
		end)
		
		le.x += le.vector[1] * le.velocity
		le.y += le.vector[2] * le.velocity
		
		le.movement(le,time)
		return le
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
			local object = spawngfx("projcol",i.object.x,i.object.y)
			add(lstate.animations,object)
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
				if every(3,0,2) then clr = 8 end
				circfill(gfx.x,gfx.y,4-gfx.frame/2,clr)
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
	cls()

	drawplayerviewport(state.players[2],0,60,-16)
	drawplayerviewport(state.players[1],68,128,-112)
	
	clip()
	camera(0,0)
	
	drawui()
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
			if every(60,0,40) then spr(14,x,y) end
		end
		enemy.gfx(enemy)
	end
end

function drawplayer (p1,p2,y1,y2,yoffset)
	local flipy = false
	if p2 ~= p1 then
		local x = mid((p1.x),p2.cam.x-64,p2.cam.x+59)
		local y = flr(mid((p1.y),p2.cam.y+y1+yoffset+1,p2.cam.y+y2+yoffset-4))
		if every(60,0,40) then spr(11+p1.id,x,y) end
	end
	if every(4,0,2) and p1.shield then circ(p1.x,p1.y,p1.shieldrad,3) end
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
	if every(3,0,2) then pal(7,8) end
	for proj in all(state.projectiles) do
		
		if outofbounds(proj,cambounds) then 
			local x = mid((proj.x),p.cam.x-64,p.cam.x+63)
		 	local y = mid((proj.y),p.cam.y+y1+yoffset,p.cam.y+y2+yoffset-1)
			if every(30) then circfill(x,y,0,8) end
		else
			spr(16,proj.x-proj.rad,proj.y-proj.rad)
		end
	end
	pal()
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
000000000000000000000000000000000000000000000000007770000077000007700000000000000000000000000000bbbb0000bbbbb0008888800000000000
00000000000000000000000007770700000000000000000007777700077e70007e8700000000000000000000000000000bbb00000bbbb0008808800000000000
00700700000700000007000077577000000000000000000078777870777ee700780700000000000000000000000000000bbb0000bbbb00008888800000000000
000770000077700000777000077707000000000000000000788788707ee8870007700000000000000000000000000000bbbbb000bbbbb0008808800000000000
0007700000777000007770000000000000000000000000007887887007e870000000000000000000000000000000000000000000000000000000000000000000
00700700077577000777570000000000000000000000000007878700007700000000000000000000000000000000000000000000000000000000000000000000
00000000075557000775550000000000000000000000000007777700000000000000000000000000000000000000000000000000000000000000000000000000
00000000077577000777570000000000000000000000000000777000000000000000000000000000000000000000000000000000000000000000000000000000
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
