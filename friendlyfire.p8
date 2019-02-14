pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--todo
--  wave system
--  menu 
--  game over screen


--init and help functions below
function _init()
	music(1)
	const = {
		music = {0,4,8,-1},
		bounds = {
			{x = 200, y = 350, w = 200, h = 100},
			{x = 200, y = 200, w = 200, h = 100},
		},
		combinedbounds = {
				x1 = 200, x2 = 400,  y1 = 200, y2 = 450
		},
		limits = {
			x1 = 100, x2 = 500, y1 = 100, y2 = 550
		},
		vector = {
			up = {0,-1},
			down = {0,1},
			left = {-1,0},
			right = {1,0}
		},
		stars = initstars(64,3)
	}

	const = protect(const)

	state = {
		score = 0,
		multiplier = 10,
		lastpoints = 0,
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
				shield = false,
				energy = 0, 
				shieldrad = 8, 
				projdir = const.vector.up, 
				cooldown = -1, 
				rateoffire = {0,0.3},
				death = false,
				invulnerable = 0
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
				shield = false,
				energy = 0,
				shieldrad = 8, 
				projdir = const.vector.down, 
				cooldown = -1, 
				rateoffire = {0,0.2},
				death = false,
				invulnerable = 0
			}
		},
		enemies = {},
		projectiles = {},
		animations = {},
		time = 0,
	}
	
	printh("init")
	for i = 1,2 do
		add(state.enemies, spawnenemy({const.bounds[2].x + rnd(200),const.bounds[2].y + rnd(200)},"orb",state))
		add(state.enemies, spawnenemy({const.bounds[2].x + rnd(200),const.bounds[2].y + rnd(200)},"alien",state))
		add(state.enemies, spawnenemy({const.bounds[2].x + rnd(200),const.bounds[2].y + rnd(200)},"robot",state))
		local origin = {const.bounds[2].x + rnd(200),const.bounds[2].y + rnd(200)}
		state.enemies = generatespacetrash(flr(rnd(10)),origin,state.enemies)
	end
	local origin = {const.bounds[2].x + rnd(200),const.bounds[2].y + rnd(200)}
	generatesnake(8,origin,const.vector.right,state.enemies)
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

function vectornormalized(vector)
	local factor = 1/(abs(vector[1])+abs(vector[2]))
	return {vector[1]*factor,vector[2]*factor}
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
	if every(44*60) then music(const.music[1+flr(rnd(#const.music))]) end
	local lstate = state
	local events = {}
	local sectors = initsectors(20,20)
	sectors = updatesectors(sectors, state.players)
	sectors = updatesectors(sectors, state.enemies)
	sectors = updatesectors(sectors, state.projectiles)

	lstate = updateplayers(lstate, events, sectors, lstate.time)
	lstate.enemies = updateenemies(lstate.enemies, lstate, events, sectors)
	lstate.projectiles = updateprojectiles(lstate.projectiles, sectors)
	

	--printh(isinsector(state.players[1].x,state.players[1].y)[1] .. "/" .. isinsector(state.players[1].x,state.players[1].y)[2] )
	--printh(#myneighbours(state.players[1].x,state.players[1].y,sectors))

	events = returncollisions(events,lstate, sectors)
	events = updateevents(lstate,events)
	lstate.animations = updateanims(lstate.animations)
	lstate = cleanup(lstate)
	lstate.time += 1/60
	-- if every(rnd(1000)) and #lstate.enemies < 8 then
	-- 	add(state.enemies, spawnenemy({const.bounds[2].x + rnd(200),const.bounds[2].y + rnd(200)},"alien"))
	-- end
	state = lstate
--	printh("memory: ".. (stat(0)/1024))
end


-- sector stuff below
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
		if i.death ~= true then
			local sector = isinsector(i.x,i.y)
			if sectors[sector[1]] == nil then
				sectors[sector[2]] = {}
			end
			if sectors[sector[1]][sector[2]] == nil then
				sectors[sector[1]][sector[2]] = {}
			end
			add(sectors[sector[1]][sector[2]],i)
		end
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

function respawn(p)
	sfx(19,-2)
	sfx(25)
	lp = p
	lp.death = false
	lp.energy = 0
	lp.invulnerable = state.time
	return lp
end

-- player
function updateplayers(state, events, sectors, time)
	lstate = state
	lstate.players = funmap(state.players, function(lp)
		lp.energy += (lstate.multiplier/10)/60
		local lbounds = const.bounds[lp.id]
		lp.x += lp.vx
		lp.y += lp.vy
		lp.vx = lerp(lp.vx, 0, 0.05)
		lp.vy = lerp(lp.vy, 0, 0.05)
		if btn(2,lp.id-1) then 
			if btn(5,lp.id-1) then 
				lp.vy = -2
				if lp.death == false then
					poof = spawngfx("poof",lp.x,lp.y)
					add(lstate.animations, poof)
					sfx(26)
				end
			else
				lp.vy += -0.1
			end
		end
		if btn(3,lp.id-1) then 
			if btn(5,lp.id-1) then 
				lp.vy = 2
				if lp.death == false then
					poof = spawngfx("poof",lp.x,lp.y)
					add(lstate.animations, poof)
					sfx(26)
				end
			else
				lp.vy += 0.1
			end
		end
		if btn(0,lp.id-1) then 
			if btn(5,lp.id-1) then 
					lp.vx = -2
					if lp.death == false then
						poof = spawngfx("poof",lp.x,lp.y)
						add(lstate.animations, poof)
						sfx(26)
					end
				else
					lp.vx += -0.1 
				end
			end
		if btn(1,lp.id-1) then 
			if btn(5,lp.id-1) then 
				lp.vx = 2
				if lp.death == false then
					poof = spawngfx("poof",lp.x,lp.y)
					add(lstate.animations, poof)
					sfx(26)
				end
			else 
				lp.vx += 0.1 
			end
		end
		if lp.x > (lbounds.x+lbounds.w) then 
			if btn(5,lp.id-1) then lp.vx -= 2.5 
			else lp.vx -= 0.15 end
		end
		if lp.x < (lbounds.x) then 
			if btn(5,lp.id-1) then lp.vx += 2.5
			else lp.vx += 0.15 end
		end
		if lp.y > (lbounds.y+lbounds.h) then 
			if btn(5,lp.id-1) then lp.vy -= 2.5 
			else lp.vy -= 0.15 end
		end
		if lp.y < (lbounds.y) then 
			if btn(5,lp.id-1) then lp.vy += 2.5 
			else lp.vy += 0.15 end
		end
		lp.vy = mid(lp.vy, -4, 4)
		lp.vx = mid(lp.vx, -4, 4)
		lp.cam = updatecam(lp)
		if lp.death and lp.energy > 100 then lp = respawn(lp) end
		if lp.death == false then
			if lp.energy > 100 and lp.shield == false then lp.shield = true sfx(23) lp.energy = 0 end
			
		
			local neighbours = myneighbours(lp.x,lp.y,sectors)
			if playercolcheck(lp,neighbours) and isinvulnerable(lp) == false then
				if lp.shield == true then 
					lp.shield = false
					lp.energy = 0
					lp.invulnerable = state.time
					printh("lose shield!")
					local loseshield = spawngfx("loseshield",lp.x,lp.y)
					add(lstate.animations,loseshield)
					sfx(24)
				elseif isinvulnerable(lp) == false then
					lp.death = true
					lstate.multiplier = 10
					lp.energy = 0
					sfx(24)
					sfx(17)
					local deathgfx = spawngfx("death",lp.x,lp.y)
					add(lstate.animations,deathgfx)
				end	
			end
			if btn(4,lp.id-1) and cooldowntimer(time, lp) then
				local projgfx = function(proj) 
						local color = 7
						if every(3,0,2) then color = proj.color end
						circfill(proj.x,proj.y,proj.rad,color)
				end 
				local lproj = spawnprojectile(lp,projgfx,11)
				lp.cooldown = time
				lp.rateoffire[1] = lp.rateoffire[2]
				sfx(12+lp.id)
				add(events,{type = "projectile", object = lproj}) 
			elseif btn(4,lp.id-1) then
				lp.rateoffire[1] = lp.rateoffire[2]
			else
				lp.rateoffire[1] -= 0.05
			end
			
		end
		return lp
	end)
	return lstate
end

function isinvulnerable(p)
	return (state.time - p.invulnerable) < 2
end

function playercolcheck(p,neighbours)
	local lneighbours = filter(neighbours, function(n)
		return n.type == "enemy"
	end)
	for n in all(lneighbours) do
		if collisioncheck(p.x, p.y, n.x, n.y, p.rad, n.rad) then 
			return true 
		end
	end
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
		local offset = 0
		if stat(1) > 0.9 then offset = 3 end
		if every(4+offset,(isinsector(i.x,i.y)[2] % 4+offset)) then
			local collision = projcollisioncheck(i, sectors)
			if collision ~= nil then
				i.death = true

				printh(collision.hit.subtype)
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
			if (i.type == "enemy" and proj.origin == "player") or (i.type == "player" and proj.origin == "enemy") then
		--	printh("collision!")
				collision = {
					x = proj.x,
					y = proj.y,
					hit = i,
					id = proj.id
				}
			end
		end
	end)
	return collision
end

-- projectile
function spawnprojectile(p,gfx,color,rad,vel)
	local proj = { 
		id = p.id,
		type = "projectile",
		origin = p.type, 
		x = p.x, 
		y =  p.y,
		rad = rad or 1, 
		vector = p.projdir,  
		velocity = vel or 1.2, 
		color = color,
		death = false, 
		gfx = gfx
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
	if type == "orb" then
		enemy = { 
			id = flr(rnd(1000)),
			points = 100,
			type ="enemy",
			subtype = type,
			hp = 30, 
			hit = {false, nil},
			x = pos[1], 
			y =  pos[2],
			rad = 8,   
			vector = {1,0},
			velocity = 0.1,
			movement = function(enemy, state, events)	
					if enemy.hit[1] then 
						enemy.velocity += 0.05 
						if enemy.hit[2] == 1 then
							enemy.vector[2] -= 0.05
						else
							enemy.vector[2] += 0.05
						end
						enemy.vector[2] = mid(enemy.vector[2],-1,1)
					end
					local lbounds = const.combinedbounds
			
					if enemy.x > (lbounds.x2) then enemy.vector[1] -= 0.03 end
					if enemy.x < (lbounds.x1) then enemy.vector[1] += 0.03 end
					if enemy.y > (lbounds.y2) then enemy.vector[2] -= 0.03 end
					if enemy.y < (lbounds.y1) then enemy.vector[2] += 0.03 end
			end,
			gfx = function(enemy, time)
				palt(15,true)
				palt(0,false)
				local colors = {14,8,11}
				local color = colors[1+flr(rnd(#colors))]
				if every(enemy.hp,0,2) then pal(0,color) pal(7,0) sfx(22) end
				if every(enemy.hp,4,2) then pal(0,color) end
				spr(9,enemy.x-8,enemy.y-8,2,2)
			end
		}
	end
	if type == "robot" then
		enemy = { 
			id = flr(rnd(1000)),
			points = 20,
			type ="enemy",
			subtype = type,
			hp = 3, 
			hit = {false, nil},
			x = pos[1], 
			y =  pos[2],
			rad = 6,   
			vector = {0,0},
			projdir = {0,0},
			velocity = 0.3,
			movement = function(enemy, state, events)	
				local time = state.time
				if every(120) then
					local vlist = {const.vector.up,const.vector.left,const.vector.down,const.vector.right}
					enemy.vector = vlist[1+flr(rnd(4))]
					enemy.projdir = {-enemy.vector[1],-enemy.vector[2]}
				end
				if outofbounds(enemy,const.combinedbounds) then
					enemy.vector = {-enemy.vector[1],-enemy.vector[2]}
				end
				if every(180) then
					local rectgfx = function (proj)
						local colors = {14,7,11,8}
						fillp(flr(rnd(9999)))
						local color = colors[1+flr(rnd(#colors))]
						rectfill(proj.x-3,proj.y-2,proj.x+3,proj.y+2,color)
						fillp()
					end
					local lproj = spawnprojectile(enemy,rectgfx,8,3,0.2)
					add(events,{type = "projectile", object = lproj})
					sfx(21) 
				end
			end,
			gfx = function(enemy, time)
				palt(15,true)
				local colors = {14,8,7}
				local color = colors[1+flr(rnd(#colors))]
				rectfill(enemy.x-2,enemy.y-3,enemy.x+1,enemy.y+2,0)
				line(enemy.x+sin(time/2%1)*3,enemy.y-2,enemy.x+sin(time/2%1)*3,enemy.y,color)
				spr(4,enemy.x-3,enemy.y-4) 
			end
		}
	end
	if type == "alien" then
		enemy = { 
			id = flr(rnd(1000)),
			points = 10,
			type ="enemy",
			subtype = type,
			hp = 3, 
			hit = {false, nil},
			x = pos[1], 
			y =  pos[2],
			rad = 6,   
			vector = {0,0},
			projdir = {0,0},
			velocity = 0.3,
			movement = function(enemy, state, events)
				local time = state.time
				local closestplayer = getclosestplayer(enemy.x,enemy.y)
				local directionofplayer = vectornormalized(vectora2b(enemy,closestplayer))
				enemy.vector = {
					lerp(enemy.vector[1],directionofplayer[1],0.01),
					lerp(enemy.vector[2],directionofplayer[2],0.01),
				}
				if every(flr(rnd(360+1000))) and stat(1) < 0.9 then
					enemy.projdir = directionofplayer
					local projgfx = function(proj) 
						local color = 7
						if every(3,0,2) then color = proj.color end
						circfill(proj.x,proj.y,proj.rad,color)
					end
					local lproj = spawnprojectile(enemy,projgfx,8)
					add(events,{type = "projectile", object = lproj}) 
					sfx(20)
				end
	--			enemy.vector = {sin(time%1),sin(time%1)}
			end,
			gfx = function(enemy, time)
				palt(0,false)
				palt(15,true)
				spr(6,enemy.x-3,enemy.y-4) 
			end
		}
	end

	return enemy
end

function generatesnake(size,origin,direction,enemies)
 	local vlist = {const.vector.up,const.vector.left,const.vector.down,const.vector.right}
  local generatedsize = 1
	local construct = {}
 
	local master = {
		sprite = 7,
		points = 15,
		id = flr(rnd(1000)),
		type = "enemy",
		subtype = "head",
		snakeid = 0,
		x = origin[1],
		y = origin[2],
		velocity = 1,
		vector = {0,0},
		hp = 2,
		hit = {false, nil},
		rad = 3,
		movement = function(enemy,state,events) 
			if every(10) then
				local target = getclosestplayer(enemy.x,enemy.y)
				
				local directionoftarget = vectornormalized(vectora2b(enemy,target))
				enemy.vector = {
					lerp(enemy.vector[1],directionoftarget[1],0.01),
					lerp(enemy.vector[2],directionoftarget[2],0.01),
				}
			end
		end,
		gfx = function(i)
			palt(0,false)
			palt(15,true)
			local sprite = i.sprite
			if every(60,i.snakeid*8,30) then 
				sprite += 1
				
			end
			if i.hp == 1 and every(4,0,2) then pal(7,8) end
			spr(sprite,i.x-3,i.y-3)
			pal()
		end
	}

	add(construct,master)

  for i = 1,size do
		local slave = {
			sprite = 7,
			points = 15,
			type = "enemy",
			subtype = "snakeslave",
			id = master.id + generatedsize,
			snakeid = generatedsize,
			x = master.x - direction[1]*generatedsize*8,
			y = master.y - direction[2]*generatedsize*8,
			velocity = 1,
			hit = {false, nil},
			vector = master.vector,
			hp = 2,
			rad = 3,
			movement = function(enemy,state,events) 

				local target = nil
				local targetid = enemy.id -1
				for i in all(state.enemies) do
					if targetid == i.id then 
						target = i 
					end
				end
				if target == nil then 
					enemy.movement = function(enemy,state,events) 
						if every(10) then
							local target = getclosestplayer(enemy.x,enemy.y)
							local directionoftarget = vectornormalized(vectora2b(enemy,target))
							enemy.vector = {
								lerp(enemy.vector[1],directionoftarget[1],0.01),
								lerp(enemy.vector[2],directionoftarget[2],0.01),
							}
						end
					end
				else
					if collisioncheck(enemy.x,enemy.y,target.x,target.y,enemy.rad*2,target.rad) then
						enemy.vector = {0,0}
					else
						local directionoftarget = vectornormalized(vectora2b(enemy,target))
						enemy.vector = {
							lerp(enemy.vector[1],directionoftarget[1],0.1),
							lerp(enemy.vector[2],directionoftarget[2],0.1),
						}
					end
				end
			end,
			gfx = master.gfx
		}
		add(construct,slave)
		generatedsize += 1
  end

  local lenemies = enemies
  each(construct,function(i)
    add(lenemies,i)
  end)
  return enemies
end
function generatespacetrash(size,origin,enemies)
  local vlist = {const.vector.up,const.vector.left,const.vector.down,const.vector.right}
  local generatedsize = 1
  local master = {
    sprite = 20+flr(rnd(4)),
		points = 5,
		flipy = coinflip(),
		flipx = coinflip(),
    id = flr(rnd(1000)),
    type = "enemy",
    subtype = "master",
    x = origin[1],
		y = origin[2],
		velocity = 0.1,
    vector = const.vector.down,
    hp = 2,
		hit = {false, nil},
    rad = 3,
		movement = function(i,state,events) end,
		gfx = function(i)
			palt(0,false)
			palt(15,true)
			if i.hp == 1 and every(4,0,2) then pal(7,8) end
			spr(i.sprite,i.x-3,i.y-4,1,1,i.flipx,i.flipy)
			pal()
		end
  }
  local construct = {master}
  while generatedsize < size do
    for i in all(construct) do
      if coinflip() then
        local slave = {
          sprite = 20+flr(rnd(4)),
					points = 5,
					flipy = coinflip(),
					flipx = coinflip(),
          type = "enemy",
          subtype = "slave",
          id = master.id + generatedsize,
          x = i.x,
					y = i.y,
					velocity = 0.1,
					hit = {false, nil},
          vector = master.vector,
          hp = 2,
          rad = 3,
          movement = function(slave,state,events)
          end,
          gfx = master.gfx
        }
        local crash = true
        while crash do
					crash = false
          local offset = vlist[1+flr(rnd(4))]
          slave.x += offset[1]*8
          slave.y += offset[2]*8
          for i2 in all(construct) do
            if i2.x == slave.x and i2.y == slave.y then crash = true end          
          end
        end
        add(construct,slave)
        generatedsize += 1
      end
    end
  end

  local lenemies = enemies
  each(construct,function(i)
    add(lenemies,i)
  end)
  return enemies
end

function coinflip()
 	if rnd(2) > 1 then
		return true
	else
		return false
	end	
end

function getclosestplayer(x,y)
	local p = {x = 0, y = 0}
	local p1 = state.players[1]
	local p2 = state.players[2]
	local distance1 = abs((p1.x+p1.y)-(x+y))
	local distance2 = abs((p2.x+p2.y)-(x+y))

	if distance1 < distance2 and p1.death == false then
		p = p1
	elseif distance2 < distance1 and p2.death == false  then
		p = p2
	end
	return p
end


function vectora2b(entitya,entityb)
	return {(entityb.x-entitya.x),(entityb.y-entitya.y)}
end

function updateenemies(e, state, events, sectors)
	local time = state.time
	local les = {}
	les = filter(e, function(le)
	
		-- local neighbours = myneighbours(le.x,le.y,sectors)
		-- -- each(neighbours, function(i)
		-- -- 	if (i ~= le) and collisioncheck(le.x, le.y, i.x, i.y, le.rad, i.rad) then
		-- -- 		local vector = normalizedvectora2b(le,i,le.vector)
		-- -- 		le.x -= vector[1] * (le.velocity *3)
		-- -- 		le.y -= vector[2] * (le.velocity *3)
		-- -- 	end
		-- -- end)
		le.x += le.vector[1] * le.velocity
		le.y += le.vector[2] * le.velocity
		
		le.movement(le,state,events)
		le.hit = {false, nil}
		if le.hp <= 0 then 
			add(events,{type="animation", object = spawngfx("explosion",le.x,le.y)})
		end
		if le.hp <= 0 then 
			state.score += le.points * (state.multiplier/10)
			state.multiplier += 1
			state.lastpoints = le.points
			sfx(15)
		end
		return le.hp > 0
	end)
	return les
end

--events

function updateevents(state,events)
	local lstate = state

	local enemy = filter(events, function (i)
	return i.type == "enemy"
	end)
	each (enemy, function (i)
	 local e = spawnenemy({i.object.x,i.object.y},i.object.type,state)
	 add(lstate.enemies,e)
	end)
	
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
		
		if i.object.hit.type == "player" then
			for p in all(lstate.players) do
				if i.object.hit.id == p.id then
					if p.shield == true and isinvulnerable(p) == false then 
						p.shield = false
						p.energy = 0
						p.invulnerable = state.time
						printh("lose shield!")
						local loseshield = spawngfx("loseshield",i.object.hit.x,i.object.hit.y)
						add(lstate.animations,loseshield)
						sfx(24)
					elseif isinvulnerable(p) == false then
						p.death = true
						sfx(24)
						sfx(17)
						sfx(19)
						p.energy = 0
						local deathgfx = spawngfx("death",i.object.hit.x,i.object.hit.y)
						add(lstate.animations,deathgfx)
					end	
				end
			end
		end
		if i.object.hit.type == "enemy" then
			for e in all(lstate.enemies) do
				if i.object.hit.id == e.id then
					e.hp -= 1
					e.hit = {true, i.object.id}
				end
			end
		end
		if i.object.hit.type ~= "player" then
			lstate.score += 1
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
	if type == "poof" then 
		gfx = {
			frame = 0,
			runtime = 8,
			x = lx,
			y = ly,
			gfx = function(gfx)
				local clrs = {14,11}
				if every(6,-gfx.frame,1) then
					local clr = clrs[1+flr(rnd(#clrs))]
					pal(7,clr)
					palt(15,true)
					spr(46,gfx.x-4,gfx.y-8,2,2)
				end
				pal()
			end	
		}
	end
	if type == "loseshield" then
			gfx = {
			frame = 0,
			runtime = 40,
			x = lx,
			y = ly,
			gfx = function(gfx)
				if gfx.frame == 1 then circfill(gfx.x,gfx.y,100,11) end
				if every(gfx.frame,0,2) then
					circ(gfx.x,gfx.y,8+gfx.frame,11)
				end
			end	
		}
	end
	if type == "death" then
		gfx = {
			frame = 0,
			runtime = 40,
			x = lx,
			y = ly,
			gfx = function(gfx)
				if gfx.frame == 1 then circfill(gfx.x,gfx.y,100,0) end
				if gfx.frame == 2 then circfill(gfx.x,gfx.y,100,7) end
				if gfx.frame == 3 then circfill(gfx.x,gfx.y,100,8) end
				if every(2,0,1) then
					fillp(flr(rnd(9999)))
					circ(gfx.x,gfx.y,gfx.frame,7)
				end
				if every(2,1,1) then
					fillp(flr(rnd(9999)))
					circ(gfx.x,gfx.y,gfx.frame-gfx.frame/8,8)
				end
				fillp()
				if every(gfx.frame/2,0,2) then
					
					circfill(gfx.x,gfx.y,gfx.frame,14)
				end
	
			end	
		}
	end
	if type == "flare" then
		gfx = {
			frame = 0,
			runtime = 5,
			x = lx,
			y = ly,
			gfx = function(gfx)
				local clr = 7
				if every(3,0,2) then clr = 11 end
				circfill(gfx.x,gfx.y,4-gfx.frame/2,clr)
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
				-- circfill(gfx.x,gfx.y,5,7+flr(rnd(2)))
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

function minutesseconds (time)
	local seconds = flr(time % 60)
	if seconds < 10 then seconds = "0" .. seconds end
	local minutes = min(flr(time / 60),99)
	if minutes < 10 then minutes = "0" .. minutes end
	return "" .. minutes .. ":" .. seconds	
end

-->8
--draw functions below
function _draw()
	cls()

	drawplayerviewport(state.players[2],0,61,-16)
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

	drawgrid(p)
	drawstars(p)
	drawenemies(p,cambounds,y1,y2,yoffset)
	for player in all(state.players) do
		if player.death ~= true then
			if isinvulnerable(player) then
				if every(8,0,4) then drawplayer(player, p, y1, y2, yoffset) end
			else
				drawplayer(player, p, y1, y2, yoffset) 
			end
		else
			drawdeadplayer(player)
		end
	end
	drawprojectiles(p,cambounds,y1,y2,yoffset)
	for anim in all(state.animations) do
		anim.gfx(anim)
	end
	
	pal()
end

function drawdeadplayer(p)
			flipy = nil
			yoffset = 0
			if p.id == 2 then flipy = true yoffset = 1 end
			if every(2) then 
				clr = 5
				if p.energy > 95 and every(4) then clr = 7 end
				line(p.x-4,p.y,p.x-6,p.y,clr)
				line(p.x+4,p.y,p.x+6,p.y,clr)
				line(p.x,p.y+7,p.x,p.y+9,clr)
				line(p.x,p.y-7,p.x,p.y-9,clr)
				rect(p.x-4,p.y-7,p.x+4,p.y+7,clr)
				rectfill(p.x-4,p.y+7,p.x+4,p.y+7-flr(p.energy*0.14),clr)
				palt(15,true) palt(0,false) spr(3,p.x-3,p.y-8+yoffset,1,2,false,flipy) palt() 
				drawmini(""..flr(p.energy),p.x+6,p.y+5,clr)
			end
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
		if every(30,3,5) then rect(const.combinedbounds.x1, const.combinedbounds.y1, const.combinedbounds.x2, const.combinedbounds.y2 ,14) end
end		

function drawenemies(p, cambounds,y1,y2,yoffset)
	for enemy in all(state.enemies) do
		if outofbounds(enemy,cambounds) then 
			local x = mid((enemy.x),p.cam.x-66,p.cam.x+64)
			local y = mid((enemy.y),p.cam.y+y1+yoffset-1,p.cam.y+y2+yoffset)
			if enemy.velocity > 0.5 then pal(2,8) end
			if every(30-enemy.velocity*10,0,enemy.velocity*10) then spr(14,x-1,y-1) end
			pal()
		end
		if enemy.hit[1] then pal(0,7+flr(rnd(2))) pal(7,0) sfx(16) end
		enemy.gfx(enemy,state.time)
		
		pal()
	end
end

function drawplayer (p1,p2,y1,y2,yoffset)
	local flipy = false
	if p2 ~= p1 then
		local x = mid((p1.x),p2.cam.x-64,p2.cam.x+59)
		local y = flr(mid((p1.y),p2.cam.y+y1+yoffset+1,p2.cam.y+y2+yoffset-5))
		palt(15,true)
		palt(0,false)
		if every(60,0,40) then spr(11+p1.id,x-1,y-1) end
	end
	if p1.shield then 
		if every(3) then
			circ(p1.x,p1.y,p1.shieldrad,11)
		end
	elseif every(2) then
		clr = 5
		if p1.energy > 95 then clr = 11 end
		drawmini(""..flr(p1.energy),p1.x+6,p1.y+4,clr)
	end
	palt(15,true)
	palt(0,false)
	if p1.id == 2 then flipy = true end
	if btn(0,p1.id-1) then
		spr(2,p1.x-3,p1.y-8,1,2,true,flipy)
	elseif btn(1,p1.id-1) then
		spr(2,p1.x-3,p1.y-8,1,2,false,flipy)
	else
		spr(1,p1.x-3,p1.y-8,1,2,false,flipy)
	end
	pal()
end

function drawprojectiles(p,cambounds,y1,y2,yoffset)
	
	for proj in all(state.projectiles) do

		if outofbounds(proj,cambounds) then 
			local x = mid((proj.x),p.cam.x-64,p.cam.x+63)
		 	local y = mid((proj.y),p.cam.y+y1+yoffset,p.cam.y+y2+yoffset-1)
		
			if every(30-proj.velocity*10,0,proj.velocity*10) then circfill(x,y,0,proj.color) end
		else
			proj.gfx(proj)
		end
	end
	
end

function drawscore (score, x, y)
 for n = 1,#score do
    local nr = 0 .. sub(score, n,n)
   	 spr(32+nr,((n-1)*10)+x,y)
	end
end

function drawmini (score, x, y,clr)
pal(7,clr)
 for n = 1,#score do
    local nr = 0 .. sub(score, n,n)
		if nr == "0:" then
			spr(74,((n-1)*5)+x,y)
		elseif nr == "0x" then
			spr(75,((n-1)*5)+x,y)
		elseif nr == "0." then
			spr(76,((n-1)*5)+x,y)
		else
			spr(64+nr,((n-1)*5)+x,y)
		end
	end
pal()
end

function drawui()
	rect(-1,61,128,67,5)
	if state.players[1].shield ~= true then
			clr = 11
			pset(state.players[1].energy*1.28, 67, clr)
	end
	local scorestring = "" .. flr(state.score)
	drawscore(scorestring, 4,60)
	local multiplier = "" .. state.multiplier
	if #multiplier == 2 then multiplier = sub(multiplier,1,1) .. "." .. sub(multiplier,2,2) end
	drawmini("x" .. multiplier,4+(#scorestring*10),63,5)
	drawmini(minutesseconds(state.time),101,63,5)
	pal()
	--debug
	local percent = flr(stat(1)*100)
	print(percent .. "%", 4 , 4 , stat(1)*10)
end


__gfx__
00000000ffffffffffffffffffffffffff7777fff77777ffff777fffff77ffffffffffffffffff7777ffffff00000000f0000ffff00000ff22220000ff0000ff
00000000fffffffffffffffffffffffff777777f7000007ff77777fff7787fffff77ffffffff77000077ffff000000000bbbb0ff0bbbbb0f22220000f088880f
00700700fff7fffffff7fffffff0ffff770000777070707f7877787f777887fff7e87ffffff7000000007fff00000000f0bbb0fff0bbbb0f222200000880880f
00077000ff777fffff777fffff000fff700000077007007f7887887f788007fff7807fffff700770000007ff00000000f0bbb0ff0bbbb0ff000000000888880f
00077000ff777fffff777fffff000fff770000777070707f7887887ff7807fffff77fffff70077700000007f000000000bbbbb0f0bbbbb0f00000000088000ff
00700700f77077fff77707fff00f00fff777777f7000007ff78787ffff77fffffffffffff70777000000007f00000000f00000fff00000ff00000000f00fffff
00000000f70007fff77000fff0fff0ffff7777fff77777fff77777ffffffffffffffffff700770000000000700000000ffffffffffffffff00000000ffffffff
00000000f77077fff77707fff00f00ffffffffffffffffffff777fffffffffffffffffff700000000000000700000000ffffffffffffffff00000000ffffffff
07000000f77777fff77777fff00000fff777777ffffff7ff777fffffff7ff7ff0000000070000000000000070000000000000000000000000000000000000000
77700000ff777fffff777fffff000fff70000007ff7ff7ffff7fff7ff777f7ff0000000070000000000007070000000000000000000000000000000000000000
07000000ff777fffff777fffff000fff7000000777777777f777777f7700077700000000f70000000000007f0000000000000000000000000000000000000000
00000000f77777ffff777ffff00000ff70000007fffffffffffffffff70007ff00000000f70000000000707f0000000000000000000000000000000000000000
00000000777f777ff77777ff000f000f00000007ffffffffff77777ff70007ff00000000ff700000000707ff0000000000000000000000000000000000000000
0000000077fff77ff77f77ff00fff00f70000007777fff77777fff77777777ff00000000fff7000007007fff0000000000000000000000000000000000000000
000000007fffff7ff7fff7ff0fffff0f70000007ff7f777fff7ff77fff7ff7ff00000000ffff77000077ffff0000000000000000000000000000000000000000
00000000fffffffffffffffffffffffff777707ffffff7ffff7ff7ffff7ff7ff00000000ffffff7777ffffff0000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffff
7777777777777770777777777777777700777770777777777777777777777777777777777777777707770000000000000000000000000000ffff7fffffffffff
7000700707000070000700070000700707070070700070007000700000070007700070077000700707070000000000000000000000000000fff7f7ffffffffff
7007700707000070777700070000700770070070700077777000777700070007700070077000700707770000000000000000000000000000ff7fff7fffffffff
7070700707000070700000070077000777777777700000077000700700700070077700077000700700000000000000000000000000000000ff7fff7fffffffff
7700700707000070700077770000700700070070777700077000700707000700700070077777700707770000000000000000000000000000f7fffff7ffffffff
7000700707000070700070000000700700070070000700077000700707000700700070070000700707070000000000000000000000000000f7fffff7ffffffff
7777777777777777777777777777777700777777777777777777777707777700777777777777777707770000000000000000000000000000f7fffff7ffffffff
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f7fffff7ffffffff
0007700077777777777707777777777777777777777777777777077777777777777777777777777700000000000000000000000000000000ff7fff7fffffffff
0777777070007000700707077070070770007007700707077007070707000070700070007000700700000000000000000000000000000000ff7fff7fffffffff
7777777770007000700777077770077770007007700707077007770707000070700070007000700700000000000000000000000000000000f7fffff7ffffffff
e777777b700007700770007000700700700077707007070770070707070000707000700070007007000000000000000000000000000000007fff7fff7fffffff
eee77bbb700070007007770700700700700070077007770770070707070000707000700070007007000000000000000000000000000000007ff7f7ff7fffffff
0eeebbb0700070007007070700700700700070077007070770070707070000707000700070007007000000000000000000000000000000007f7fff7f7fffffff
000eb00077777777777707770077770077777007777707777777077777777777777777777777777700000000000000000000000000000000f7fffff7ffffffff
77770000777000007770000077770000707700000777000070000000777700007777000077770000077000007007000000000000000000000000000000000000
70070000077000000770000007770000777700000770000077770000077700007777000077770000000000000770000000000000000000000000000000000000
77770000777700000777000077770000007700007770000077770000077700007777000000070000077000007007000007700000000000000000000000000000
__map__
3030300030300000303030003030300030303000303000003000000030003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000030003000003000003030000030003000300030003000000030003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300030300000003000003000000030003000300030003000000030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000030003000303030003030300030003000303000003030300000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300030303000303000003030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000300000300030003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300000300000303000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000030303000300030003030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000001b1b1b1b1b1b1b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001b1b1b1b1b1b1b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000001b1b1b1b1b1b1b1b1b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001b1b1b001b1b1b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001b1b1b001b1b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001b001b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0031003200330034003500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0036003700250038003900340031000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010e00200725507255072510725507255072550725507255072550725507255072550725507255072550725507255072550725507255072551125511255112550725507255072550725511255112551125511251
010e00000a2550a2550a2550a2550a2550a2550a2550a2550a2550a2550a2550a2550a2550a2550a2550a2550a2550a2550a2550a2550a2551125511255112550a2550a2550a2550a25511255112551125511251
010e00073e755377553e755377553e75539755377553e7553c7050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705007050070500705
011c000000000000000000000000000000000000000000000000000000000000000000000000000b4000140000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00101e6550000000000000000665500000000000000006655000000000000000066550000000000000001e655000000000000000066550000000000000000665500000000000000006655000000000000000
000e0020225502254022540225402254022540225302253022520225102251022500000000000000000000000000000000000000000000000000000000000000000000000000000000001d5501d5301d5201d520
000e00201f5501f5501f5401f5401f5401f5401f5401f5401f5301f5201f5201f5100000000000000000000000000000000000000000000000000000000000000000000000000000000021550215302152021520
000e0020215502154021540215402154021540215302153021520215202151021510000000000000000000000000000000000000000000000000000000000000000000000000000000001d5501d5301d5201d510
000e00201f5501f5401f5401f5401f5401f5401f5301f5301f5201f5201f5101f5100000000000000000000000000000000000000000000000000000000000000000000000000000000021500215002150021500
000e00202b1502b1402b1402b1402b1402b1402b1302b1302b1302b1202b1102b1100010000100001000010000100001000010000100001000010000100001000010000100001000010029120291302915029150
000e00202615026150261502614026140261502615026150261302613026120261200010000100001000010000100001000010000100001000010000100001000010000100001000010029120291302914029150
000e00202b1502b1402b1402b1402b1402b1402b1402b1402b1302b1302b1202b120001000010000100001000010000100001000010000100001000010000100001000010000100001002d1202d1302d1402d140
000e00202b1502b1402b1402b1402b1402b1402b1402b1302b1302b1202b1102b11000100001000010000100001000010000100001000010000100001000010000100001002d1002d1002d1002d1000010000100
010100001d2710c16113151111430c133031230611302113001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103
010100001f2710c16113151111430c133031230611302113001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103
0003000016273156731426313653132331363312233116430e2430e2430c6330d2230b6230b223096230a2230a623092230962308213076130721305613032130161301613032030320302203012030120301203
000b00000165500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605006050060500605
010700003945302351003000030002341003000030002331003000030000300023210030000300003000231100300003000030000300003000030000300003000030000300003000030000300003000030000300
010f00003b7652f005090050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
011201090871107721057210272102722027220372105711077110070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
01010000112470c23713127111270c1170f117121171a117001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103001030010300103
010700001d5440c53613526115270c5170f517125171a517005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503
010700001a71500704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400000
0107000005510085210e5311154116551175511754017530175201751017510175151750017500005010050100501005010050100501005010050100501005010050100501005010050100501005010050100500
010a00001751417640156551e6551b645226351f6251c6151b6151a61517500175000050100501005010050100501005010050100501005010050100501005010050100501005010050100501005000000000000
0107000002516025260e5361a53626546325460e5560e305003000030002351003000030000300023410030000300003000233100300003000232100300003000231100300023110030000300003000030000000
010700001f1261d126131162911600105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00201304307135071050710507125071150710507105130430713507105071050712507115071050710513043071350710507105071311112111115111051304307135071050710511121111111111511105
010e0020160430a13507105071050a1250a1150710507105160430a13507105071050a1250a1150710507105160430a13507105071050a131111211111511105160430a135071050710511121111111111511105
__music__
01 5e420509
00 5e42060a
00 5f42070b
02 5e42080c
01 02090544
00 020a0644
00 020b0744
02 020c0844
01 05064344
00 06054344
00 05064344
00 06074344
00 07064344
00 07084344
02 08054344
01 09024344
00 0a024344
00 0b024344
02 0c024344
03 02424344
03 00044344
01 00424504
00 00424604
00 01424704
00 00424804
01 00420504
00 00420604
00 01420704
00 00420804
00 00090504
00 000a0604
00 010b0704
00 000c0804
01 00020504
00 00020604
00 01020704
02 00020804

