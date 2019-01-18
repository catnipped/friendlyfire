pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

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
		}
	}
	const = protect(const)
	state = {
		players = {
			{ id = 1, x = 100, y = 100, rad = 4 , vx = 0, vy = 0, projdir = const.vector.up, cooldown = -1, rateoffire = {0,0.2} },
			{ id = 2, x = 0, y = 0, rad = 4, vx = 0, vy = 0, projdir = const.vector.down, cooldown = -1, rateoffire = {0,1} }
		},
		enemies = {},
		projectiles = {},
		cam = {
			x = 0,
			y = 0
		},
		time = 0
	}
	printh("init")
end

function pythagoras(ax,ay,bx,by)
  local px = bx-ax
  local py = by-ay
  return sqrt(px*px + py*py)
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
function  _update60()
	local lstate = state
	local events = {}
	lstate.players = updatePlayers(lstate.players, lstate.time, events)
	lstate.projectiles = updateProjectiles(lstate.projectiles, events, lstate.players, lstate.enemies)
	lstate.cam = updateCam(lstate.cam, lstate.players[1])
	camera(lstate.cam.x-64,lstate.cam.y-64)
	lstate = updateEvents(lstate,events)
	lstate.time += 1/60
	state = lstate
	events = {}
end

function updatePlayers(p, time, events)
	local lps = p
	lps = funmap(lps, function(lp)
		local lbounds = const.bounds[lp.id]
		lp.x += lp.vx
		lp.y += lp.vy
		lp.vx = lerp(lp.vx, 0, 0.05)
		lp.vy = lerp(lp.vy, 0, 0.05)

		if btn(4,lp.id-1) and cooldowntimer(time, lp) then 
			local lproj = spawnProjectile(lp)
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
		return lp
	end)
	return lps
end

function cooldowntimer(time, p)
	if time - p.cooldown < p.rateoffire[1] then
		printh(time-p.cooldown)
		return false
	else
		return true
	end
end

function spawnProjectile(p)
	local proj = { 
		id = p.id, 
		x = p.x-3.5, 
		y =  p.y-12,
		rad = 2, 
		vector = p.projdir,  
		velocity = 1.2, 
		gfx = 1, 
	}
	return proj
end


function updateProjectiles(projs, events, players, enemies)
	local lprojs = projs
	if #lprojs > 0 then
		lprojs = funmap(lprojs, function(lproj)
			lproj.x += lproj.vector[1] * lproj.velocity
			lproj.y += lproj.vector[2] * lproj.velocity
			local collision = projCollisionCheck(lproj, players, enemies)
			if collision != nil then
				add(events, {type = "collision", collision})
			end
			return lproj
		end)
		each(lprojs, function (i)
			if outOfBounds(i) then del(lprojs,i) end
		end)
		while #lprojs > 100 do del(lprojs,lprojs[1]) end
	end
	return lprojs
end

function outOfBounds(object)
	if object.x > const.limits.x2 or object.x < const.limits.x1 or 
	object.y > const.limits.y2 or object.y < const.limits.y1 then
		return true
	else
		return false
	end
end

function projCollisionCheck(proj,players,enemies)
	collision = {}
	funmap(players, function(i)
		if collisionCheck(i.x,i.y,proj.x,proj.y,i.rad,proj.rad,i.id,proj.id) then
			collision = {i, proj}
		end
	end)
	map(enemies, function(i)
		if collisionCheck(i.x,i.y,proj.x,proj.y,i.rad,proj.rad,i.id,proj.id) then
			collision = {i, proj}
		end
	end)
	return collision
end

function collisionCheck(ax, ay, bx, by, ar, br, aid, bid)
	if pythagoras(ax, ay, bx, by) < (ar + br) and aid != bid then
		printh("collision!")
		return true
	else 
		return false
	end
end

function updateCam(cam, p)
	local lcam = cam
	local lp = p
	local lbounds = const.bounds[lp.id]
	lcam.x = flr(lerp(lcam.x,lp.x,0.1))
	lcam.y = flr(lerp(lcam.y,lp.y,0.1))
	return lcam
end

function updateEvents(state,events)
	local lstate = state
	local newProjs = filter(events, function (i) 
		return i.type == "projectile"
	end)

	each (newProjs, function (i)
		add(lstate.projectiles, i.object)
	end)
	return lstate
end


-->8
function _draw()
	cls()
	local lbounds = const.bounds
	for box in all(lbounds) do
		rect(box.x,box.y,box.x+box.w,box.y+box.h,3)
	end
	for proj in all(state.projectiles) do 
		spr(16,proj.x,proj.y)
	end
	for p in all(state.players) do
		local lp = p
		local flipy = false
		if p.id == 2 then flipy = true end
		if btn(0,lp.id-1) then
			spr(2,lp.x-3,lp.y-8,1,2,true,flipy)
		elseif btn(1,lp.id-1) then
			spr(2,lp.x-3,lp.y-8,1,2,false,flipy)
		else
			spr(1,lp.x-3,lp.y-8,1,2,false,flipy)
		end
	end
	print(stat(1), state.cam.x -54 , state.cam.y - 54 , 7)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000700000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007770000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007770000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000077777000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700077077000777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000070007000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077077000777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007770000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007eb700007770000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007be700077777000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777077700777070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000770707700770770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700700700700770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
