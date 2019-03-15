pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--todo
--  wave system pass 3
--  spawn animation
--  menu/highscore 


--init and help functions below
function _init()
	screen = "title"
	music(21)
	
	callsign = { "01ACID02BITTER03COLD04DEAD05ELECTRIC06FILTHY07GIANT08HOT09ILL10JANKY11KILL12LOST13MEDIOCRE14NASTY15OPTIC16PROUD17QUIRKY18RADICAL19SALTY20TOP21URBAN22VICIOUS23WOKE24XENIAL25YELLOW26ZESTY", "01ARROW02BANANA03CURE04DEATH05ENEMY06FOX07GIANT08HORROR09IDIOT10JUSTICE11KING12LOVE13MASS14NEEDLE15ORANGE16PILOT17QUEEN18RAVEN19SIREN20TERROR21UNCLE22VOICE23WARRIOR24XENO25YOUTH26ZODIAC"
	}
	origo = {x = 300, y = 325}
	musics = {0,4,8}
	bounds = {
			{x = 200, y = 350, w = 200, h = 100},
			{x = 200, y = 200, w = 200, h = 100},
		}
	combinedbounds = {
				x1 = 200, x2 = 400,  y1 = 200, y2 = 450
		}
	limits = {
			x1 = 100, x2 = 500, y1 = 100, y2 = 550
		}
	vectors = {
			vec(0,-1), vec(0,1), vec(-1,0), vec(1,0)
		}
	stars = initstars(64,3)

	initgame()
	sessionscore = {0,{0,0,"BEAT","THIS"},{0,0,"",""},false}
	cartdata(1)
	scores = getscores()
	xoffset = 0
	xvelocity = 0.5
  menuitem(3, "reset highscores", function() 
		for i = 1,#scores*5 do
			dset(nr,0)
		end
	end)
end

function initgame()
	score = 0
	timebonus = 0
	multiplier = 10
	lastpoints = 0
	lives = 3
	enemies = {}
	projectiles = {}
	animations = {}
	time = 0
	difficulty = 1
	players = {
		initplayer(1),
		initplayer(2)
	}	
end

function generatespawnpoint()
	return {x = 200 + flr(rnd(2))*rnd(200), y = 200 + flr(rnd(2))*rnd(350)}
end

function initplayer(nr)
 local player = { 
		id = nr,
		type = "player", 
		x = bounds[nr].x+100, 
		y = bounds[nr].y+50, 
		rad = 3, 
		vx = 0, 
		vy = 0, 
		energy = 0, 
		invulnerable = 0, 
		cam = {
			x = bounds[nr].x+100, y = bounds[nr].y+50 
		},
		shield = false, 
		death = false, 
		ready = false, 
		shieldrad = 8, 
		projdir = vectors[nr], 
		cooldown = -1, 
		rateoffire = {0,0.3},
		callsign = {flr(rnd(25)),flr(rnd(25)),"\139 CHOOSE \145","\148 CALLSIGN \131"}
	}
	return player
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

function vec(x,y)
	return {x=x,y=y} 
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
	local factor = 1/(abs(vector.x)+abs(vector.y))
	return vec(mid(-1,vector.x*factor,1),mid(-1,vector.y*factor,1))
end

function sloppysqrt(x)
    s=((x/2)+x/(x/2)) / 2
    for i = 1,3 do
        s=(s+x/s)/2
		end
    return s
end

function every(duration,offset,period)
	local frames = flr(time * 60)
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

function wavesystem()
	local enemiesdb = {"alien","robot","orb","trash","snake"}
	local spawn = false
	if every(60*15,14) then
		difficulty += 1
	end
	local things = {}

	if #enemies == 0 then
		difficulty += 1
		spawn = true
	end
	while (every(60*(mid(2,difficulty,15))) or spawn) and #enemies+#things < 0+mid(5,difficulty,30) and stat(1) < 0.9 do
	 	local origin = generatespawnpoint()
		 if difficulty < 2 then
	 		add(things,spawnenemy(origin,"robot"))
		
	 	elseif difficulty < 4 then
	 		local enemy = enemiesdb[1+flr(rnd(2))]
			add(things,spawnenemy(origin,enemy))
								things = generatespacetrash(3+min(5,flr(rnd(difficulty))),origin,things)

		elseif difficulty < 5 then
			things = generatesnake(3+min(5,flr(rnd(difficulty))),origin,vectornormalized(vectora2b(origin,origo)),things)
		elseif difficulty < 6 then
			add(things,spawnenemy(origin,"alien"))
			add(things,spawnenemy(origin,"alien"))
			things = generatespacetrash(3+min(5,flr(rnd(difficulty))),origin,things)
		elseif difficulty < 9 then
			add(things,spawnenemy(origin,"robot"))
			add(things,spawnenemy(origin,"orb"))
		elseif difficulty < 10 then
			things = generatespacetrash(3+min(5,flr(rnd(difficulty))),origin,things)
		else
			local enemy = enemiesdb[1+flr(rnd(#enemies))]
			if enemy == "trash" then things = generatespacetrash(3+min(5,flr(rnd(difficulty))),origin,things)
			elseif enemy == "snake" then things = generatesnake(3+min(5,flr(rnd(difficulty))),origin,vectornormalized(vectora2b(origin,origo)),things)
			else
				add(things,spawnenemy(origin,enemy))
			end
		end
	end
	for thing in all(things) do
		if thing.id then
			add(enemies,thing)
		end
	end
end

-->8
--update functions below
function _update60()
	if screen == "game" then
		updategame()
	elseif screen == "title" then
		updatetitle()
	elseif screen == "highscores" then
		updatehighscores()
	elseif screen == "gameover" then
	 updategameover()
	end
end

function updatetitle()
	time += 1/60
	for p in all(players) do
		if btnp(4,p.id-1) and p.ready == false  then 
			p.ready = true
			sfx(23)
			
			time = 0
		elseif p.ready and btnp(5,p.id-1) then 
			p.ready = false 
			sfx(18)
		end
	end
	if time > 30 then
	 screen = "highscores"
	 xoffset = 0
	 time = 0
	end
	if players[1].ready and players[2].ready and time > 3 then
		screen = "game"
		music(0)
		time = 0
		initgame()
	end
end


function updategameover()
	time += 1/60
	updatecallsigns()
	if players[1].ready and players[2].ready 	then
		score += timebonus * 10
		timebonus = 0
	end
	if timebonus > 0 then
		score += 5
		timebonus -= 0.5
	end
	if players[1].ready and players[2].ready and time > 4 then
		screen = "highscores"
		xoffset = 0
		music(21)
		time = 0
		players[1].ready = false
		players[2].ready = false
		scores = isnewscore()
		setscores()
	end
end

function sort(a,cmp)
  for i=1,#a do
    local j = i
    while j > 1 and cmp(a[j-1],a[j]) do
        a[j],a[j-1] = a[j-1],a[j]
    j = j - 1
    end
  end
end

function getcallsigntostring(i,nr)
	local words = callsign[i]
	local sub1 = 0
	local sub2 = 0
	for n = 1,#words do
		if tonum(sub(words,n,n+1)) == nr then
			sub1 = n
		end 
		if tonum(sub(words,n,n+1)) == nr+1 then
			sub2 = n
		end 
	end
	return sub(words,sub1+2,sub2-1)
end

function getscores(newscore)
	local lscores = {}
	local newscoreoffset = 0
	if newscore ~= nil then add(lscores,newscore) newscoreoffset = 5 end
	for s = 1,50-newscoreoffset,5 do
		
		if dget(s) == nil then dset(s,0) end
		if dget(s+1) == nil then dset(s+1,0) end
		if dget(s+2) == nil then dset(s+2,0) end
		if dget(s+3) == nil then dset(s+3,0) end
		if dget(s+4) == nil then dset(s+4,0) end

		local score = dget(s)
		add(lscores,{
			score,
			{dget(s+1),dget(s+2),getcallsigntostring(1,dget(s+1)),getcallsigntostring(2,dget(s+2))},
			{dget(s+3),dget(s+4),getcallsigntostring(1,dget(s+3)),getcallsigntostring(2,dget(s+4))},
			false
		})
		
	end
	
	sort(lscores, function(a, b)
		return a[1] < b[1]
	end)

	return lscores
end

function setscores()
	for i = 1,#scores do
		local nr = (i*5)-4
		local score = scores[i][1]
		local callsign1 = scores[i][2]
		local callsign2 = scores[i][3]
		dset(nr,score)
		dset(nr+1,callsign1[1])
		dset(nr+2,callsign1[2])
		dset(nr+3,callsign2[1])
		dset(nr+4,callsign2[2])
	end
end

function isnewscore()
	lscores = scores
	for s in all(scores) do
		if score > s[1] then
			lscores = getscores({
				flr(score),
				players[1].callsign,
				players[2].callsign,
				true
			})
			break
		end
	end
	if score > sessionscore[1] then 
		sessionscore = {
			flr(score),
			players[1].callsign,
			players[2].callsign,
			true
		}
	else sessionscore[4] = false end

	return lscores
end


function updatehighscores()
	xoffset += xvelocity
	xvelocity = lerp(xvelocity,0.5,0.1)
	xvelocity = mid(-2,xvelocity,2)
	xoffset = xoffset % (1000)
	time += 1/60
	for p in all(players) do
		if btn(1) then
			xvelocity += 0.1
		end
		if btn(0) then
			xvelocity-= 0.1
		end
		if btnp(4,p.id-1) then 
			p.ready = true
			sfx(23)
		elseif p.ready and btnp(5,p.id-1) then 
			p.ready = false 
		end
	end
	if players[1].ready and players[2].ready then
		screen = "title"
		time = 0
		players[1].ready = false
		players[2].ready = false
	end
	if time > 25 then
	 screen = "title"
	 time = 0
	end
end


function  updategame()
	if every(44*60) then music(musics[1+flr(rnd(#musics))]) end
	local events = {}
	local sectors = initsectors(20,20)
	sectors = updatesectors(sectors, players)
	sectors = updatesectors(sectors, enemies)
	sectors = updatesectors(sectors, projectiles)

	players = updateplayers(players, events, sectors, time)
	enemies = updateenemies(enemies, events, sectors)
	projectiles = updateprojectiles(projectiles, sectors)
	wavesystem()
	events = returncollisions(events, sectors)
	events = updateevents(events)
	animations = updateanims(animations)
	projectiles = cleanupprojs(projectiles)
	time += 1/60
	if players[1].death and players[2].death or time >= 60 * 5 then
		screen = "gameover"
		sfx(-1,1)
		music(19)
		players[1].ready = false
		players[2].ready = false
		timebonus = flr(time)
		time = 0
	end
end

function updatecallsigns()
	for p in all (players) do
		if p.ready == false then
			if btnp(0,p.id-1) then
				sfx(18)
				p.callsign[1] -= 1
				p.callsign[3] = getcallsigntostring(1,p.callsign[1])
			elseif btnp(1,p.id-1) then
				sfx(18)
				p.callsign[1] += 1
				p.callsign[3] = getcallsigntostring(1,p.callsign[1])
			elseif btnp(2,p.id-1) then
				sfx(18)
				p.callsign[2] -= 1
				p.callsign[4] = getcallsigntostring(2,p.callsign[2])
			elseif btnp(3,p.id-1) then
				sfx(18)
				p.callsign[2] += 1
				p.callsign[4] = getcallsigntostring(2,p.callsign[2])
			end
			if p.callsign[1] < 1 then p.callsign[1] = 26 end
			if p.callsign[2] < 1 then p.callsign[2] = 26 end
			p.callsign[1] = max(1,p.callsign[1] % 27)
			p.callsign[2] = max(1,p.callsign[2] % 27)
			if btnp(4,p.id-1) then p.ready = true time = 0 sfx(25) end
		elseif p.ready and btnp(5,p.id-1) then p.ready = false 	sfx(18) end
	end
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
			if sectors[sector.x] == nil then
				sectors[sector.y] = {}
			end
			if sectors[sector.x][sector.y] == nil then
				sectors[sector.x][sector.y] = {}
			end
			add(sectors[sector.x][sector.y],i)
		end
	end
	return sectors
end

function isinsector(x,y)
	local lx = mid(flr(x/25),-20,20)
	local ly = mid(flr(y/25),-20,20)
	return vec(lx,ly)
end

function myneighbours(ex,ey,sectors)
	local vector = isinsector(ex,ey)
	local entities = {}
	for x = vector.x-1,vector.x+1 do
		if x > 0 and x < 21 then
			for y = vector.y-1,vector.y+1 do
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


function cleanupprojs(projectiles)
	lprojectiles = filter(projectiles, function(i)
		return i.death == false
	end)
	return lprojectiles
end

function respawn(p)
	sfx(19,-2)
	sfx(25)
	lp = p
	lp.death = false
	lp.energy = 0
	lp.invulnerable = time
	return lp
end

-- player
function updateplayers(players, events, sectors, time)
	lplayers = funmap(players, function(lp)
		lp.energy += (multiplier/10)/60
		local lbounds = bounds[lp.id]
		lp.x += lp.vx
		lp.y += lp.vy
		lp.vx = lerp(lp.vx, 0, 0.05)
		lp.vy = lerp(lp.vy, 0, 0.05)
		if btn(2,lp.id-1) then 
			if btn(5,lp.id-1) then 
				lp.vy = -2
				if lp.death == false then
					poof = spawngfx("poof",lp.x,lp.y,lp.id)
					add(animations, poof)
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
					poof = spawngfx("poof",lp.x,lp.y,lp.id)
					add(animations, poof)
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
						poof = spawngfx("poof",lp.x,lp.y,lp.id)
						add(animations, poof)
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
					poof = spawngfx("poof",lp.x,lp.y,lp.id)
					add(animations, poof)
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
			if every(4,lp.id) and playercolcheck(lp,neighbours) and isinvulnerable(lp) == false then
				if lp.shield == true then 
					lp.shield = false
					lp.energy = 0
					lp.invulnerable = time
					local loseshield = spawngfx("loseshield",lp.x,lp.y)
					add(animations,loseshield)
					sfx(24)
				elseif isinvulnerable(lp) == false then
					lp.death = true
					multiplier = 10
					lp.energy = 0
					sfx(24)
					sfx(17)
					local deathgfx = spawngfx("death",lp.x,lp.y)
					add(animations,deathgfx)
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
	return players
end

function isinvulnerable(p)
	return (time - p.invulnerable) < 2
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
	local lbounds = bounds[p.id]
	lcam.x = flr(lerp(lcam.x,p.x,0.2))
	lcam.y = flr(lerp(lcam.y,p.y,0.2))
	return lcam
end

-- collisions
function returncollisions(events, sectors)
	local levents = {}
	local nr = 0
	each(projectiles, function(i)
		local offset = 0
		nr += 1
		if #projectiles > 20 then offset = 3 end
		if every(4+offset,nr % 4+offset) then
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
	local neighbours = {} 
	if proj.origin == "player" then
		neighbours = myneighbours(proj.x,proj.y,sectors)
	elseif proj.origin == "enemy" then
		neighbours = players
	end
	each(neighbours, function(i)
		local lrad = i.rad
		if i.shield then lrad = i.shieldrad end
		if collisioncheck(i.x,i.y,proj.x,proj.y,lrad,proj.rad) and (i.id ~= proj.id) and i.type ~= "projectile" and i.death ~= true then
			collision = {
				x = proj.x,
				y = proj.y,
				hit = i,
				id = proj.id
			}
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
	proj.x += proj.vector.x * 8
	proj.y += proj.vector.y * 8
	return proj
end

function updateprojectiles(projs, sectors)
	local lprojs = {}
	if #projs > 0 then
		lprojs = funmap(projs, function(lproj)
			lproj.x += lproj.vector.x * lproj.velocity
			lproj.y += lproj.vector.y * lproj.velocity
			return lproj
		end)
		lprojs = filter(lprojs, function (i)
			return outofbounds(i,limits) == false
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
function spawnenemy(pos,type)
	local enemy = {}
	if type == "orb" then
		enemy = { 
			id = flr(rnd(1000)),
			points = 100,
			type ="enemy",
			subtype = type,
			hp = 30, 
			hit = {false, nil},
			x = pos.x, 
			y =  pos.y,
			rad = 8,   
			vector = vectornormalized(vectora2b(vec(pos.x,pos.y),vec(noise(origo.x,200),noise(origo.y,200)))),
			velocity = 0.1,
			movement = function(enemy, events)	
					if enemy.hit[1] then 
						enemy.velocity += 0.05 
						if enemy.hit[2] == 1 then
							enemy.vector.y -= 0.05
						else
							enemy.vector.y += 0.05
						end
						enemy.vector.y = mid(enemy.vector.y,-1,1)
					end

			
					if enemy.x > (combinedbounds.x2) then enemy.vector.x -= 0.03 end
					if enemy.x < (combinedbounds.x1) then enemy.vector.x += 0.03 end
					if enemy.y > (combinedbounds.y2) then enemy.vector.y -= 0.03 end
					if enemy.y < (combinedbounds.y1) then enemy.vector.y += 0.03 end
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
			x = pos.x, 
			y =  pos.y,
			rad = 6,   
			vector = vec(0,0),
			projdir = vec(1,0),
			velocity = 0.3,
			movement = function(enemy, events)	
				if every(120) or enemy.vector.x == 0 and enemy.vector.y == 0 then
					enemy.vector = vectors[1+flr(rnd(4))]
					enemy.projdir = vec(-enemy.vector.x,-enemy.vector.y)
				end
				if outofbounds(enemy,combinedbounds) then
					enemy.vector = vec(-enemy.vector.x,-enemy.vector.y)
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
			x = pos.x, 
			y =  pos.y,
			rad = 6,   
			vector = vec(0,0),
			projdir = vec(0,0),
			velocity = 0.3,
			movement = function(enemy, events)
				local closestplayer = getclosestplayer(enemy.x,enemy.y)
				local directionofplayer = vectornormalized(vectora2b(enemy,closestplayer))
				enemy.vector = vec(lerp(enemy.vector.x,directionofplayer.x,0.01),lerp(enemy.vector.y,directionofplayer.y,0.01))
				if every(160,(enemy.id%160)) and stat(1) < 0.9 then
					enemy.projdir = directionofplayer
					local projgfx = function(proj) 
						local color = 7
						if every(3,0,2) then color = proj.color end
						circfill(proj.x,proj.y,proj.rad,color)
					end
					local lproj = spawnprojectile(enemy,projgfx,8,1,0.5)
					add(events,{type = "projectile", object = lproj}) 
					sfx(20)
				end
			end,
			gfx = function(enemy, time)
				palt(0,false)
				palt(15,true)
				if every(160,(enemy.id%160)+30,30) == false then
					pal(8,0)
				end
				spr(6,enemy.x-3,enemy.y-4) 
			end
		}
	end

	return enemy
end

function generatesnake(size,origin,direction,enemies)
  local generatedsize = 1
	local construct = {}
 
	local master = {
		sprite = 7,
		points = 15,
		id = flr(rnd(1000)),
		type = "enemy",
		subtype = "head",
		snakeid = 0,
		x = origin.x,
		y = origin.y,
		velocity = 1,
		vector = vectornormalized(vectora2b(origin,origo)),
		hp = 2,
		hit = {false, nil},
		rad = 3,
		movement = function(enemy,events) 
			if every(10) then
				local target = getclosestplayer(enemy.x,enemy.y)
				if outofbounds(enemy,combinedbounds) then
					target = vectornormalized(vectora2b(enemy,origo))
				end
				enemy.velocity += 0.01
				local directionoftarget = vectornormalized(vectora2b(enemy,target))
				enemy.vector = vec(
					lerp(enemy.vector.x,directionoftarget.x,0.05),
					lerp(enemy.vector.y,directionoftarget.y,0.05)
				)
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
			x = master.x - direction.x*generatedsize*8,
			y = master.y - direction.y*generatedsize*8,
			velocity = 1,
			hit = {false, nil},
			vector = master.vector,
			hp = 2,
			rad = 3,
			movement = function(enemy,events) 

				local target = nil
				local targetid = enemy.id -1
				for i in all(enemies) do
					if targetid == i.id then 
						target = i 				
					end
				end
				if target == nil then target = getclosestplayer(enemy.x,enemy.y) end
				enemy.velocity = target.velocity
				if collisioncheck(enemy.x,enemy.y,target.x,target.y,enemy.rad*2,target.rad) then
					-- enemy.vector = vec(0,0)
				else
					local directionoftarget = vectornormalized(vectora2b(enemy,target))
					enemy.vector = vec(
						lerp(enemy.vector.x,directionoftarget.x,0.04),
						lerp(enemy.vector.y,directionoftarget.y,0.04)
					)
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

function noise(nr,range)
	return nr+(rnd(range)-(range/2))
end

function generatespacetrash(size,origin,enemies)
  local generatedsize = 1
  local master = {
    sprite = 20+flr(rnd(4)),
		points = 5,
		flipy = coinflip(),
		flipx = coinflip(),
    id = flr(rnd(1000)),
    type = "enemy",
    subtype = "master",
    x = origin.x,
		y = origin.y,
		velocity = 0.1,
    vector = vectornormalized(vectora2b(vec(origin.x,origin.y),vec(noise(origo.x,200),noise(origo.y,200)))),
    hp = 2,
		hit = {false, nil},
    rad = 3,
		movement = function(i,events) end,
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
          movement = function(slave,events)
          end,
          gfx = master.gfx
        }
        local crash = true
        while crash do
					crash = false
          local offset = vectors[1+flr(rnd(4))]
          slave.x += offset.x*8
          slave.y += offset.y*8
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
	local p = {x = bounds[2].x + rnd(200), y = bounds[2].y + rnd(200)}
	local p1 = players[1]
	local p2 = players[2]
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
	return vec((entityb.x-entitya.x),(entityb.y-entitya.y))
end

function updateenemies(e, events, sectors)
	local les = {}
	les = filter(e, function(le)
		le.x += le.vector.x * le.velocity
		le.y += le.vector.y * le.velocity
		le.movement(le,events)
		le.hit = {false, nil}
		if le.hp <= 0 then
			add(events,{type="animation", object = spawngfx("explosion",le.x,le.y)})
		end
		if le.hp <= 0 then
			score += le.points * (multiplier/10)
			multiplier += 1
			lastpoints = le.points
			sfx(15)
		end
		return le.hp > 0 and outofbounds(le,limits) == false
	end)
	return les
end

--events

function updateevents(events)

	local enemy = filter(events, function (i)
	return i.type == "enemy"
	end)
	each (enemy, function (i)
	 local e = spawnenemy({i.object.x,i.object.y},i.object.type)
	 add(enemies,e)
	end)
	
	local newprojs = filter(events, function (i) 
		return i.type == "projectile"
	end)

	each (newprojs, function (i)
		add(projectiles, i.object)
		local object = spawngfx("flare",i.object.x,i.object.y)
		
		if i.object.color == 8 then
			object = spawngfx("eflare",i.object.x,i.object.y)
		end
		add(animations,object)
	end)


	local collisions = filter(events, function (i) 
		return i.type == "collision"
	end)

	each (collisions, function (i)
		local projcolgfx = spawngfx("projcol",i.object.x,i.object.y)
		add(animations,projcolgfx)
		local hitgfx = spawngfx("ehit",i.object.hit.x,i.object.hit.y)
		add(animations,hitgfx)
		
		if i.object.hit.type == "player" then
			for p in all(players) do
				if i.object.hit.id == p.id then
					if p.shield == true and isinvulnerable(p) == false then 
						p.shield = false
						p.energy = 0
						p.invulnerable = time
						local loseshield = spawngfx("loseshield",i.object.hit.x,i.object.hit.y)
						add(animations,loseshield)
						sfx(24)
					elseif isinvulnerable(p) == false then
						p.death = true
						multiplier = 10
						sfx(24)
						sfx(17)
						sfx(19)
						p.energy = 0
						local deathgfx = spawngfx("death",i.object.hit.x,i.object.hit.y)
						add(animations,deathgfx)
					end	
				end
			end
		end
		if i.object.hit.type == "enemy" then
			for e in all(enemies) do
				if i.object.hit.id == e.id then
					e.hp -= 1
					e.hit = {true, i.object.id}
					for p in all(players) do
						p.energy += 1 * (multiplier/10)
					end
				end
			end
		end
		if i.object.hit.type ~= "player" then
			score += 1
		end
	end)

		local anims = filter(events, function (i) 
		return i.type == "animation"
	end)

	each (anims, function (i)
		add(animations,i.object)
	end)
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

function spawngfx(type, lx, ly, id)
	gfx = {}
	local flipy = false
	if id == 2 then flipy = true end
	if type == "poof" then 
		gfx = {
			frame = 0,
			runtime = 8,
			x = lx,
			y = ly,
			flipy = flipy,
			gfx = function(gfx)
				local clrs = {14,11}
				if every(6,-gfx.frame,1) then
					local clr = clrs[1+flr(rnd(#clrs))]
					pal(7,clr)
					palt(15,true)
					spr(46,gfx.x-4,gfx.y-8,2,2,false,gfx.flipy)
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
	if type == "eflare" then
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
	if screen == "game" then
		drawgame()
	elseif screen == "title" then
		drawtitle()
	elseif screen == "highscores" then
		drawhighscores()
	elseif screen == "gameover" then
	 	drawgameover()
	end
		--debug
	camera()
	-- local percent = flr(stat(1)*100)
	-- print(percent .. "%", 4 , 4 , stat(1)*10)
end

function drawgame()
	drawplayerviewport(players[2],0,61,-16)
	drawplayerviewport(players[1],68,128,-112)
	clip()
	camera(0,0)
	drawui()
end

function multilineprint(string,width,x,y,clr)
	local lines = #string % width
	local clr = clr or 7
	for l = 1,lines+1 do
		print(sub(string,(l-1)*width,l*width-1),x,y+l*6,clr)
	end
end

function drawtitle()
	multilineprint("THIS IS A COOPERATIVE GAME.EACH PLAYER HAS A SHIP.     FRIENDLY FIRE IS ON! SHOOT  ENEMIES BUT NOT YOUR FRIEND!SURVIVE FOR 5 MINUTES AND   GET AS MANY POINTS POSSIBLE.                            PRESS \142 ON EACH CONTROLLER  WHEN READY.",28,10,24)

	if players[2].ready and every(3) then 
		print("PLAYER 2 READY",36,10,11)
	end	
	if players[1].ready and every(3) then
		print("PLAYER 1 READY",36,100,11)
	end


	camera()
	
	
	pal()
end

function drawhighscores()

	local starcolors = {5,6,7}
	for l = 1,#stars do
			for s in all(stars[l]) do
					local x = ((xoffset / (4-l)+5)*0.9+s[1]-128) % 127 
					pset(x,(0 /l+5)*0.9+s[2]-128,starcolors[l])
			end
	end
	

	local mapoffset = - 80+ xoffset - (xoffset*0.5)
	drawtextfrommap(0,11,33,-mapoffset,-50)
	
	camera(-50+xoffset)
	drawascore(0, 84,70)
	print("all time",84*2.5,70-12,5)
	for i = 1, #scores do
		drawascore(i, (i+1.5)*84,70)
	end
	pal()
end

function drawtextfrommap(mx,my,length,sx,sy)
	local sx, sy = sx or 0, sy or 0
	for x = mx+length ,mx,-1 do
		for y = my,my+4 do
			if every(33,x,4) == false then  pal(7,0) pal(14,7) pal(11,5) end
			if every(16,-x,6) then   pal(11,0) pal(14,11) end
			local i = x * 7 - (time *60)
			map(x,y,sx + x*7,sy+y*6-sin(i/128)*5,1,1)
			pal()
		end
	end
end

function drawascore(nr,x,y)
	local clrs = {7,8,14,11}
	new = false
	local score = ""
	if nr == 0 then 
		score = sessionscore
		new = sessionscore[4]
		print("session",x,y-12,5)
	else
		score = scores[nr]
		new = scores[nr][4]
	end
	clr = 7
	drawscore(""..score[1],x,y)
	if every(16,0,8) and new then 
			clr = clrs[1+flr(rnd(#clrs))] 
			print("new",x,y-6,clr)
	end
	local number = nr.."."
	drawmini(sub(number,1,2),x-10,y+5,7)

	drawcallsign(score[2],x,y+10)
	drawcallsign(score[3],x,y+16)
	pal()
end

function drawgameover()
	drawplayerviewport(players[2],0,61,-16)
	drawplayerviewport(players[1],68,128,-112)
	clip()
	camera()
	rect(-1,61,128,67,5)
	
	local scorestring = "" .. flr(score)
	drawscore(scorestring, 4,60)
	drawmini("+" .. flr(timebonus),4+(#scorestring*10),63,14)
	drawmini(minutesseconds(timebonus),101,63,7)
	local clr1, clr2 = 7
	if players[1].ready then clr1 = 11 end
	if players[2].ready then clr2 = 11 end
	
	drawcallsign(players[2].callsign,4,50,clr2)
	drawcallsign(players[1].callsign,4,74,clr1)
	camera()
	drawtextfrommap(0,16,36,12,-82)
	drawtextfrommap(0,20,36,12,-38)
end

function drawcallsign(signs,x,y,clr)
	clr = clr or 7
	print(signs[3] .. " " .. signs[4],x,y,clr)
end

function drawplayerviewport(p,y1,y2,yoffset)
	clip(0,y1,128,y2)
	
	camera(p.cam.x-64,p.cam.y+yoffset)
	pal()
	local cambounds = {x1 = p.cam.x-64, x2 = p.cam.x+64, y1 = p.cam.y+y1+yoffset, y2 = p.cam.y+y2+yoffset}

	drawgrid(p)
	drawstars(p)
	drawenemies(p,cambounds,y1,y2,yoffset)
	for player in all(players) do
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
	for anim in all(animations) do
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
			-- line(p.x-4,p.y,p.x-6,p.y,clr)
			-- line(p.x+4,p.y,p.x+6,p.y,clr)
			-- line(p.x,p.y+7,p.x,p.y+9,clr)
			-- line(p.x,p.y-7,p.x,p.y-9,clr)
			rect(p.x-4,p.y-7,p.x+4,p.y+7,clr)
			rectfill(p.x-4,p.y+7,p.x+4,p.y+7-flr(p.energy*0.14),clr)
			palt(15,true) palt(0,false) spr(3,p.x-3,p.y-8+yoffset,1,2,false,flipy) palt() 
			drawmini(""..flr(max(100-p.energy),0),p.x+6,p.y+5,clr)
		end
end

function drawstars(p)
	local starcolors = {5,6,7}
	for l = 1,#stars do
		if #enemies < 10*(l+1) then
			for s in all(stars[l]) do
					pset((p.cam.x / l+5)*0.9+s[1]-128,(p.cam.y / l+5)*0.9+s[2]-128,starcolors[l])
			end
		end
	end
end

function drawgrid(p)
	local box = bounds[p.id]
		if every(2,0) or stat(1) >= 1 then 
			for x = box.x,box.x+box.w,50 do
				line(x,box.y,x,box.y+box.h,5)
			end
			for y = box.y,box.y+box.h,50 do
				line(box.x,y,box.x+box.w,y,5)
			end
			-- rect(box.x,box.y,box.x+box.w,box.y+box.h,11) 
		end
		if every(30,3,5) then rect(combinedbounds.x1, combinedbounds.y1, combinedbounds.x2, combinedbounds.y2 ,14) end
end		

function drawenemies(p, cambounds,y1,y2,yoffset)
	for enemy in all(enemies) do
		if outofbounds(enemy,cambounds) then
			local x = mid((enemy.x),p.cam.x-66,p.cam.x+64)
			local y = mid((enemy.y),p.cam.y+y1+yoffset-1,p.cam.y+y2+yoffset)
			if enemy.velocity > 0.4 and every(8-enemy.velocity) then pal(8,7) end
			if every(30-enemy.velocity*10,0,enemy.velocity*10) then spr(14,x-1,y-1) end
			pal()
		end
		if enemy.hit[1] then pal(0,7+flr(rnd(2))) pal(7,0) sfx(16) end
		enemy.gfx(enemy,time)
		
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
		drawmini(""..flr(max(100-p1.energy),0),p1.x+6,p1.y+4,clr)
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
	
	for proj in all(projectiles) do

		if outofbounds(proj,cambounds) then 
			local x = mid((proj.x),p.cam.x-64,p.cam.x+63)
		 	local y = mid((proj.y),p.cam.y+y1+yoffset,p.cam.y+y2+yoffset-1)
			local color = proj.color
			if proj.color == 8 then color = 2 end
			if every(30-proj.velocity*10,0,proj.velocity*10) and p.id ~= proj.id then circfill(x,y,0,color) end
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
		elseif nr == "0+" then
			spr(77,((n-1)*5)+x,y)
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
	
	local scorestring = "" .. flr(score)
	drawscore(scorestring, 4,60)
	local multiplier = "" .. multiplier
	if #multiplier == 2 then multiplier = sub(multiplier,1,1) .. "." .. sub(multiplier,2,2) end
	drawmini("x" .. multiplier,4+(#scorestring*10),63,5)
	drawmini(minutesseconds(time),101,63,5)
	pal()
end


__gfx__
00000000ffffffffffffffffffffffffff7777fff77777ffff777fffff77ffffffffffffffffff7777ffffff00000000f0000ffff00000ff88880000ff0000ff
00000000fffffffffffffffffffffffff777777f7000007ff77777fff7787fffff77ffffffff77000077ffff000000000bbbb0ff0bbbbb0f88880000f088880f
00700700fff7fffffff7fffffff0ffff770000777070707f7877787f777887fff7e87ffffff7000000007fff00000000f0bbb0fff0bbbb0f888800000880880f
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
eeeeee0077777777777707777777777777777777777777777777077777777777777777777777777777777777000000000000000000000000ff7fff7fffffffff
ebbbbeb07000700070070707707007077000700770070707700707070700007070007000700070077ebbbbe7000000000000000000000000ff7fff7fffffffff
eb777eb07000700070077707777007777000700770070707700777070700007070007000700070077bebbeb7000000000000000000000000f7fffff7ffffffff
eb777eb07000077007700070007007007000777070070707700707070700007070007000700070077bbeebb70000000000000000000000007fff7fff7fffffff
eeeeeeb07000700070077707007007007000700770077707700707070700007070007000700070077bebbeb70000000000000000000000007ff7f7ff7fffffff
0bbbbbb07000700070070707007007007000700770070707700707070700007070007000700070077ebbbbe70000000000000000000000007f7fff7f7fffffff
0000000077777777777707770077770077777007777707777777077777777777777777777777777777777777000000000000000000000000f7fffff7ffffffff
77770000777000007770000077770000707700000777000070000000777700007777000077770000077000007007000000000000007000000700000000000000
70070000077000000770000007770000777700000770000077770000077700007777000077770000000000000770000000000000077700007000000000000000
77770000777700000777000077770000007700007770000077770000077700007777000000070000077000007007000007700000007000000700000000000000
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
3000300030303000303030003030301b3030301b303000003030300030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
300030000030000030000000301b1b1b301b301b301b30003030000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300000300000003030003000001b301b301b303000003000000000303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000300030303000303030003030301b3030301b300030003030300030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001b001b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300030303000303030003030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000030003000303030003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000300030303000303030003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300030003000300030003030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300030003000303030003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000300030003000303000003000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000300030003000300000003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030300000300000303030003000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

