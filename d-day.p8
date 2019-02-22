pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- d-day
-- by projectsam

music(0, 0, 3)

function bossf(template)
  local boss = {}
  boss.x = template.x
  boss.y = template.y
  boss.dx = 0;
  boss.dy = 0;
  boss.maxspeed = template.maxspeed
  boss.acc = template.acc or 0.5
  boss.f_throttle = 5
  boss.fire = 0
  boss.tick = 1
  boss.states = template.spritedef
  boss.state = boss.states.standing
  boss.busy = false
  boss.shoot_dir = 1
  boss.hp = template.hp
  define_bounding_box(boss, 1, 2, 6, 7)
  boss.update = template.updater
  boss.shoot_func = template.shoot_func
  boss.collection = template.collection
  boss.height = template.sprh or 1
  function boss:shoot()
    add(self.collection, self.shoot_func(self.x, self.y, 0, 4, 1, self))
  end
  return boss
end

function cannonf(template)
  local c = {}
  c.x = template.x
  c.y = template.y
  c.vx = template.vx
  c.vy = template.vy
  c.sprite = template.sprite
  c.shoot = function()
    add(template.collection, template.shoot_func(c.x, c.y, c.vx, c.vy, 1, c))
  end
  c.f_throttle = flr(template.hertz * 30)
  c.fire = c.f_throttle
  c.hp = template.hp
  c.boomcount = template.hp
  define_bounding_box(c, 1, 0, 7, 6)
  return c
end

function grenadef(x, y, vx, vy, dir, shooter)
  local g = {}
  g.sprite = 66
  g.x = x
  g.y = y
  g.vx = vx
  g.vy = vy * dir
  g.deaccel = 0.1
  g.dir = dir
  g.boomcount = 3
  g.shooter = shooter
  return g
end

function bulletf(x, y, vx, vy, dir, shooter)
 local b = {}
 b.shooter = shooter
 b.x = x
 b.y = y
 b.basesprite = 65
 b.sprite = 65
 b.vx = vx
 b.vy = vy
 b.range = 128
 b.dt = 0
 b.hashit = false
 define_bounding_box(b, 3, 4, 4, 7)
 return b
end

function make_smoke(x,y, vx, vy, max_radius)
  local s = {}
  s.x = x
  s.y = y
  s.vx = vx or -1 + rnd(2)
  s.vy = vy or -1 + rnd(2)
  s.radius = 0.5 + rnd(4)
  s.max_radius = max_radius or 4 + rnd(8)
  s.growth = 0.25 + rnd(0.25)
  s.alive = true
  function s:update()
    self.x = self.x + self.vx
    self.y = self.y + self.vy
    self.radius = self.radius + s.growth
    if self.radius > self.max_radius then
      self.alive = false
    end
  end
  function s:draw(offset)
    local col = 5
    if self.radius > s.max_radius / 2 then
      col = 6
    end
    circfill(self.x + offset, self.y, self.radius, col)
  end
  return s
end

function boss_update(boss)
  if abs(cam_y - boss.y) > 128 then
    return
  end
  local left = false
  local right = false
  local shoot = true
  if boss.x < 104 then
    if boss.dx >= 0 then
      right = true
    else
      left = true
    end
  else
    left = true
  end
  if boss.x < 16 then
    left = false
    right = true
  end
  update_soldier(boss, left, right, false, false, false)
  for b in all(bosses) do
    if b.y > boss.y then
      shoot = false
    end
  end
  if shoot and boss.fire == 0 then
    boss:shoot()
    boss.fire = boss.f_throttle
  end
end

function hitler_update(h)
  if abs(cam_y - h.y) > 128 then
    return
  end
  local shoot = true
  for b in all(bosses) do
    if b.y > h.y then
      shoot = false
    end
  end
  update_soldier(h, false, false, false, false, false)
  if shoot and h.fire == 0 then
    h:shoot()
	for i = 0,1 do
	  add(grenades, grenadef(h.x - 4 + (i * 8), h.y + 8, -1 + rnd(2), 1 + rnd(2), 1, h))
	end
	h.fire = h.f_throttle
  end
end

sprtype = {[1] = 48, [3] = 65, [4] = 64, [5] = 112, [6] = 96}
sprstates = {
     ["soldier"] = {
     	 ["standing"] = {48},
		 ["running"] = {48,48,48,48,49,49,49,49,50,50,50,50,51,51,51,51,52,52,52,52,53,53,53,53},
		 ["exploding"] = {54,54,54,55,55,55,56,56,56,57,57,57,58,58,58,59,59,59,60,60,60},
		 ["drowning"] = {38,38,38,39,39,39,40,40,40,41,41,41,42,42,42,43,43,43,44,44,44,45,45,45},
     ["shot"] = {12,12,12,13,13,13,14,14,14,15,15,15,27,27,27},
     ["hit"] = {28,28,29,29,28,28}
	},
	["nazi"] = {
	  ["standing"] = {112},
	  ["running"] = {112,112,112,112,113,113,113,113,114,114,114,114,115,115,115,115,116,116,116,116,117,117,117,117},
	  ["exploding"] = {118,118,118,119,119,119,56,56,56,57,57,57,58,58,58,59,59,59,60,60,60},
	  ["drowning"] = {96,96,96,97,97,97,98,98,98,99,99,99,100,100,100,101,101,101},
      ["shot"] = {12,12,12,13,13,13,14,14,14,15,15,15,27,27,27},
      ["hit"] = {28,28,29,29,28,28}
	},
  ["general"] = {
    ["standing"] = {90},
	["running"] = {90,90,90,90,90,91,91,91,91,91,92,91,92,92,92,92,92,92},
	["exploding"] = {106,106,106,107,107,107,56,56,56,57,57,57,58,58,58,59,59,59,60,60,60},
	["drowning"] = {96,96,96,97,97,97,98,98,98,99,99,99,100,100,100,101,101,101},
    ["shot"] = {122,122,122,123,123,123,14,14,14,15,15,15,27,27,27},
    ["hit"] = {28,28,29,29,28,28}
  },
  ["hitler"] = {
    ["standing"] = {78},
	["running"] = {78},
	["exploding"] = {78,79,79,79,79,79,79,79,109,109,109,109,109,109,109,110,110,110,110,110,110,110,110,111,111,111,111,111,111,111,112,112,112,112,112,112,112,112},
	["shot"] = {78,79,79,79,79,79,79,79,109,109,109,109,109,109,109,110,110,110,110,110,110,110,110,111,111,111,111,111,111,111,112,112,112,112,112,112,112,112},
	["hit"] = {78,79,78,79,78}
	},
  ["boom"] = {80,80,80,81,81,81,82,82,82,83,83,83,84,84,84,85,85,85,86,86,86}
}

game_modes = {
  {["name"] = "easy", ["hp"] = 8, ["grenades"] = 32, ["spawn"] = 0},
  {["name"] = "tougher", ["hp"] = 6, ["grenades"] = 20, ["spawn"] = 1},
  {["name"] = "mad", ["hp"] = 4, ["grenades"] = 12, ["spawn"] = 2},
  {["name"] = "brexit", ["hp"] = 1, ["grenades"] = 4, ["spawn"] = 3},
  {["name"] = "cheat", ["hp"] = 100, ["grenades"] = 4, ["spawn"] = 3}
}

bullets = {}
grenades = {}
booms = {}
player = {}
nazis = {}
cannons = {}
bosses = {}
smokes = {}
casualties = 0
kills = 0
current_level = {}

player = {}
cam_x = 0
cam_y = 0
cam_positions = {}
high_scores = {}
game_mode = game_modes[1]

levelstates = {
  {
    ["number"] = 1,
    ["offset"] = 0,
    ["nazi_spawn_rate"]= 2,
    ["overheads"]={{["sprite"] = 10,["x"] = 56, ["y"] = 88}},
    ["cannons"]={ {["sprite"]=102, ["x"]=64, ["y"]=0, ["shoot_func"]=grenadef, ["collection"]=grenades, ["hertz"]=1, ["hp"]=5, ["vx"] = 0, ["vy"] = 3} },
    ["bosses"]={}
  },
  {
    ["number"] = 2,
    ["offset"]=128,
    ["nazi_spawn_rate"]= 3,
    ["overheads"]={
      {["sprite"] = 10,["x"] = 8, ["y"] = 256},
      {["sprite"] = 10,["x"] = 16, ["y"] = 256},
      {["sprite"] = 10,["x"] = 40, ["y"] = 256},
      {["sprite"] = 10,["x"] = 64, ["y"] = 256},
      {["sprite"] = 10,["x"] = 72, ["y"] = 256},
      {["sprite"] = 10,["x"] = 96, ["y"] = 256}
      },
    ["cannons"]={
      {["sprite"]=102, ["x"]=32, ["y"]=400, ["shoot_func"]=grenadef, ["collection"]=grenades, ["hertz"]=1, ["hp"]=5, ["vx"] = 0, ["vy"] = 3},
      {["sprite"]=102, ["x"]=80, ["y"]=400, ["shoot_func"]=grenadef, ["collection"]=grenades, ["hertz"]=1, ["hp"]=5, ["vx"] = 0, ["vy"] = 3},
      {["sprite"]=103, ["x"]=40, ["y"]=272, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=0.75, ["hp"]=5, ["vx"] = 0, ["vy"] = 3},
      {["sprite"]=103, ["x"]=96, ["y"]=272, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=0.75, ["hp"]=5, ["vx"] = 0, ["vy"] = 3},
      {["sprite"]=102, ["x"]=24, ["y"]=0, ["shoot_func"]=grenadef, ["collection"]=grenades, ["hertz"]=0.5, ["hp"]=5, ["vx"] = 0, ["vy"] = 3},
      {["sprite"]=103, ["x"]=64, ["y"]=0, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=0.5, ["hp"]=5, ["vx"] = 0, ["vy"] = 3},
      {["sprite"]=102, ["x"]=104, ["y"]=0, ["shoot_func"]=grenadef, ["collection"]=grenades, ["hertz"]=0.5, ["hp"]=5, ["vx"] = 0, ["vy"] = 3},
      {["sprite"]=104, ["x"]=-4, ["y"]=24, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=0.5, ["hp"]=5, ["vx"] = 3, ["vy"] = 0},
      {["sprite"]=105, ["x"]=124, ["y"]=12, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=0.5, ["hp"]=5, ["vx"] = -3, ["vy"] = 0}
    },
    ["bosses"]={}
  },
  {
    ["number"] = 3,
    ["offset"]=256,
    ["nazi_spawn_rate"]= 4,
    ["overheads"]={},
    ["cannons"]={
      {["sprite"]=103, ["x"]=56, ["y"]=384, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=0.75, ["hp"]=7, ["vx"] = 0, ["vy"] = 3},
      {["sprite"]=104, ["x"]=0, ["y"]=408, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=0.75, ["hp"]=5, ["vx"] = 3, ["vy"] = 0},
      {["sprite"]=102, ["x"]=128, ["y"]=456, ["shoot_func"]=grenadef, ["collection"]=grenades, ["hertz"]=0.5, ["hp"]=5, ["vx"] = -2.5, ["vy"] = -2.5},
      {["sprite"]=102, ["x"]=-8, ["y"]=456, ["shoot_func"]=grenadef, ["collection"]=grenades, ["hertz"]=0.5, ["hp"]=5, ["vx"] = 2.5, ["vy"] = -2.5},
      {["sprite"]=103, ["x"]=32, ["y"]=232, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=1.5, ["hp"]=5, ["vx"] = 0, ["vy"] = 2},
      {["sprite"]=103, ["x"]=48, ["y"]=232, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=1, ["hp"]=5, ["vx"] = 0, ["vy"] = 3},
      {["sprite"]=103, ["x"]=64, ["y"]=232, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=2, ["hp"]=5, ["vx"] = 0, ["vy"] = 4},
      {["sprite"]=102, ["x"]=120, ["y"]=104, ["shoot_func"]=grenadef, ["collection"]=grenades, ["hertz"]=0.5, ["hp"]=8, ["vx"] = 0, ["vy"] = 3}
	  },
    ["bosses"]={
      {["spritedef"] = sprstates.general, ["x"] = 8, ["y"]=8, ["shoot_func"]=bulletf, ["collection"]=bullets, ["maxspeed"]=4, ["acc"]=1, ["updater"] = boss_update, ["hp"]=10},
      {["spritedef"] = sprstates.general, ["x"] = 112, ["y"]=20, ["shoot_func"]=bulletf, ["collection"]=bullets, ["maxspeed"]=3.5, ["acc"]=1, ["updater"] = boss_update, ["hp"]=8},
      {["spritedef"] = sprstates.general, ["x"] = 8, ["y"]=32, ["shoot_func"]=bulletf, ["collection"]=bullets, ["maxspeed"]=3, ["acc"]=1, ["updater"] = boss_update, ["hp"]=6},
      {["spritedef"] = sprstates.general, ["x"] = 112, ["y"]=44, ["shoot_func"]=bulletf, ["collection"]=bullets, ["maxspeed"]=3, ["acc"]=1, ["updater"] = boss_update, ["hp"]=4}
    }
  },
  {
    ["number"] = 4,
    ["offset"] = 384,
    ["nazi_spawn_rate"] = 5,
    ["overheads"] = {},
    ["cannons"]= {
	  {["sprite"]=102, ["x"]=128, ["y"]=448, ["shoot_func"]=grenadef, ["collection"]=grenades, ["hertz"]=0.5, ["hp"]=5, ["vx"] = -2.5, ["vy"] = 2.5},
      {["sprite"]=102, ["x"]=-8, ["y"]=448, ["shoot_func"]=grenadef, ["collection"]=grenades, ["hertz"]=0.5, ["hp"]=5, ["vx"] = 2.5, ["vy"] = 2.5},
	  {["sprite"]=104, ["x"]=0, ["y"]=368, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=0.75, ["hp"]=5, ["vx"] = 3, ["vy"] = 0},
	  {["sprite"]=105, ["x"]=120, ["y"]=384, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=0.75, ["hp"]=5, ["vx"] = -3, ["vy"] = 0},
	  {["sprite"]=104, ["x"]=0, ["y"]=408, ["shoot_func"]=bulletf, ["collection"]=bullets, ["hertz"]=0.75, ["hp"]=5, ["vx"] = 3, ["vy"] = 0},
	  
	},
    ["bosses"] = {
      {["spritedef"] = sprstates.general, ["x"] = 8, ["y"]=8, ["shoot_func"]=bulletf, ["collection"]=bullets, ["maxspeed"]=4, ["acc"]=1, ["updater"] = boss_update, ["hp"]=10},
      {["spritedef"] = sprstates.general, ["x"] = 112, ["y"]=20, ["shoot_func"]=grenadef, ["collection"]=grenades, ["maxspeed"]=3.5, ["acc"]=1, ["updater"] = boss_update, ["hp"]=8},
      {["spritedef"] = sprstates.general, ["x"] = 8, ["y"]=32, ["shoot_func"]=bulletf, ["collection"]=bullets, ["maxspeed"]=3, ["acc"]=1, ["updater"] = boss_update, ["hp"]=6},
      {["spritedef"] = sprstates.general, ["x"] = 112, ["y"]=44, ["shoot_func"]=bulletf, ["collection"]=bullets, ["maxspeed"]=3, ["acc"]=1, ["updater"] = boss_update, ["hp"]=4},
	  {["spritedef"] = sprstates.hitler, ["x"] = 64, ["y"]=7, ["shoot_func"]=bulletf, ["collection"]=bullets, ["maxspeed"]=0, ["acc"]=0, ["updater"] = hitler_update, ["hp"]=16, ["sprh"]=2}
    }
  }
}

function update_boss(boss)
  boss.update(boss)
end

function define_bounding_box(o, x1, y1, x2, y2)
  o.bounds = {["x1"] = x1, ["x2"] = x2, ["y1"] = y1, ["y2"] = y2}
end

function update_cannon(c)
  if abs(cam_y - c.y) > 128 then
    return
  end
  c.fire = c.fire-1
  if (c.fire < 1) then
    c.shoot()
    c.fire = c.f_throttle
	add(smokes, make_smoke(c.x, c.y, c.vx / 2, c.vy / 2, 5))
  end
  local hit = false
  local hitters = {}
  local hitcheck = function(b)
    if not hit then
       hit = beenhit(c, b)
       if hit then add(hitters, b) end
    end
  end
  foreach(booms, hitcheck)
  foreach(bullets, hitcheck)
  foreach(hitters, function(b) del(bullets, b) end)
  if hit then
    c.hp = c.hp - 1
    c.flash = true
  end
  if c.hp == 0 then
    del(cannons, c)
    createbooms(c)
  end
end

function update_bullet(bullet)
 bullet.x += bullet.vx
 bullet.y += bullet.vy
 bullet.dt += bullet.vx + bullet.vy
 if bullet.dt > bullet.range then
  del(bullets, bullet)
 end
 if cmap(bullet) then
   del(bullets, bullet)
   add(smokes, make_smoke(bullet.x, bullet.y, 0 - bullet.vx, 0 - bullet.vy, 5))
 end
end

function update_grenade(g)
  g.x += g.vx
  g.y += g.vy
  if g.vx > 0 then
    g.vx -= g.deaccel
    if g.vx < 0 then g.vx = 0 end
  end
  if g.vx < 0 then
    g.vx += g.deaccel
    if g.vx > 0 then g.vx = 0 end
  end
  if g.vy > 0 then
    g.vy -= g.deaccel
    if g.vy < 0 then g.vy = 0 end
  end
  if g.vy < 0 then
    g.vy += g.deaccel
    if g.vy > 0 then g.vy = 0 end
  end
  -- stopped moving so boom
  if g.vy == 0 and g.vx == 0 then
    createbooms(g)
    del(grenades, g)
  end
end

function createbooms(g)
  for i = 0, g.boomcount do
    local boom = {}
    boom.x = g.x + (rnd(16) - 8)
    boom.y = g.y + (rnd(16) - 8)
    boom.state = sprstates.boom
    boom.sprite = boom.state[1]
    boom.tick = 1
    define_bounding_box(boom, -2, -2, 10, 10)
    add(booms, boom)
  end
end

function update_boom(boom)
  boom.tick += 1
  boom.sprite = boom.state[boom.tick]
  if boom.tick > #boom.state then
    del(booms, boom)
	  add(smokes, make_smoke(boom.x, boom.y))
  end
end

function update_smoke(s)
  s:update()
  if not s.alive then
	del(smokes, s)
  end
end

function soldierf(type, x, y, maxspeed, acc, hp)
 local s = {}
 s.x = x
 s.y = y
 s.type = type
 s.basesprite = sprtype[type]
 s.sprite = sprtype[type]
 s.dx = 0;
 s.dy = 0;
 s.maxspeed = maxspeed
 s.acc = acc or 0.5
 s.f_throttle = 10
 s.fire = 0
 s.tick = 1
 s.states = sprstates.soldier
 s.state = s.states.standing
 s.busy = false
 s.shoot_dir = -1
 s.hp = hp or 5
 define_bounding_box(s, 1, 2, 6, 7)
 return s
end

function kill_soldier(o)
  if o.tick > #o.state then
    if o == player then
	  player = spawn()
	  casualties = casualties + 1
    end
    del(nazis, o)
    del(bosses, o)
    if (#nazis < 2) then
      spawn_nazis()
    end
	  return
  end
  setsprite(o)
  o.tick +=1
end

function make_decision(o)
  local left = false
  local right = false
  local up = false
  local down = false
  local fire = false
  local xrand = rnd(10)
  local yrand = rnd(10)
  local frand = rnd(10)
  local decisionthresh = 3
  if xrand > decisionthresh then
    if player.x < o.x then
	    left = true
    end
    if player.x > o.x then
      right = true
    end
  end
  if yrand > decisionthresh then
    if player.y > o.y + 8 and not obstacle_in_front(o) then
      down = true
    end
    if player.y < o.y + 8 then
      up = true
    end
  end
  if abs(player.x - o.x) < 4 and frand > decisionthresh then
    fire = true
  end
  update_soldier(o, left, right, up, down, fire)
end

function jostle(n)
  local innerjostle = function(n2)
     if n2 == n then return end
     local diffx = n.x - n2.x
     local diffy = n.y - n2.y
     if abs(diffx) < 4 and abs(diffy) < 8 then
        if (diffx < 0) then n.x -= 1 else n.x +=1 end
     end
  end
  foreach(nazis, innerjostle)
end

function update_soldier(o, left, right, up, down, fire1, fire2)
  if o.busy then
    kill_soldier(o)
	return
  end
  local lx = o.x
  local ly = o.y
  local flashing = false
  if o.fire > 0 then
    o.fire -= 1
  end
  if left and o.dx > 0-o.maxspeed then
		o.dx -= o.acc
  end
  if right and o.dx < o.maxspeed then 
		o.dx += o.acc
	end
  if not left and not right then
      if o.dx < 0 then
		    o.dx += o.acc
	    elseif o.dx > 0 then
	      o.dx -= o.acc
	    end
  end
  if up and o.dy > 0 - o.maxspeed then 
		o.dy -= o.acc	
  end
  if down and o.dy < o.maxspeed then 
		o.dy += o.acc
	end
  if not up and not down then
    if o.dy < 0 then
		  o.dy += o.acc
	  elseif o.dy > 0 then
	    o.dy -= o.acc
	  end
  end
  
  o.x += o.dx
  o.y += o.dy
  jostle(o)
  o.tick += 1
  if cmap(o) then
    o.x = lx
	  o.y = ly
  end
  if o.state == o.states.hit and o.tick <= #o.states.hit then
    flashing = true
  end
  if not flashing then
    if o.dx == 0 and o.dy == 0 then
      o.state = o.states.standing
    else
     o.state = o.states.running
    end
  end
  if fire1 and o.fire == 0 then
    o.fire = o.f_throttle
    add(bullets, bulletf(o.x, o.y+(o.shoot_dir*8), 0, o.shoot_dir * 2, o.shoot_dir, o))
  end
  if fire2 and o.fire == 0 then
    o.fire = o.f_throttle
    add(grenades, grenadef(o.x, o.y+ o.shoot_dir * 4, 0, 3, o.shoot_dir, o))
  end
  if cmap(o, 1) then
    o.state = o.states.exploding
	  o.tick = 1
	  o.busy = true
	  kill_soldier(o)
	  add(smokes, make_smoke(o.x, o.y))
	  add(smokes, make_smoke(o.x, o.y))
  end
  if cmap(o, 2) then
    o.state = o.states.drowning
	  o.tick = 1
	  o.busy = true
	  kill_soldier(o)
  end
  local boomhit = false
  local boomcheck = function(b)
    if not boomhit then
       boomhit = beenhit(o, b)
    end
  end
  foreach(booms, boomcheck)
  if boomhit then
    o.state = o.states.exploding
    o.tick = 1
    o.busy = true
  end
  local h = false
  local bullcheck = function(b)
    if not h then
      h = beenhit(o, b)
      if h then
        del(bullets, b)
      end
    end
  end
  foreach(bullets, bullcheck)
  if h then
    o.hp = o.hp - 1
    if o.hp == 0 then
      o.state = o.states.shot
      o.tick = 1
      o.busy = true
      kill_soldier(o)
    else
      o.state = o.states.hit
      o.tick = 1
    end
  end
  handle_bounds(o)
  setsprite(o)
end

function setsprite(o)
  if o.tick > #o.state then
     o.tick = 1
  end
  o.sprite = o.state[o.tick]
end

function draw_thing(thing)
  if thing.flash then
    for i=1,15 do
      pal(i, 7)
    end
  end
  local height = thing.height or 1
  spr(thing.sprite, thing.x + current_level.offset, thing.y, 1, height)
  thing.flash = false
  pal()
end

function del_all(entities)
  for entity in all(entities) do
    del(entities, entity)
  end
end

function obstacle_in_front(o)
  local offset_x = current_level.offset + o.x + 2
  local x1=offset_x / 8
  local x2=(offset_x + 4) / 8
  local y=(o.y+o.bounds.y2 + 5)/8
  local obstacle = fget(mget(x1,y), 0) or fget(mget(x1,y), 1) or fget(mget(x1,y), 2) or fget(mget(x2,y), 2)
  return obstacle
end

function cmap(o, f)
  f = f or 0
  local offset_x = current_level.offset + o.x
  local ct=false
  local cb=false
  local x1=(offset_x + o.bounds.x1)/8
  local y1=(o.y + o.bounds.y1)/8
  local x2=(offset_x + o.bounds.x2)/8
  local y2=(o.y+o.bounds.y2)/8
  local ct = fget(mget(x1,y1),f) or fget(mget(x1,y2),f) or fget(mget(x2,y2),f) or fget(mget(x2,y1),f)
  return ct
end

function handle_bounds(o)
  if o.x < 0 then
    o.x = 0
  end
  if o.x > 120 then
    o.x = 120
  end
end

function beenhit(o, b)
  if o == b.shooter then
    return
  end
  local cb=false
  local xa = (o.x + o.bounds.x1) - (b.x + b.bounds.x1)
  local xh = false 
  if xa < 0 then
    xh = abs(xa) <= o.bounds.x2
  else
    xh = xa <= b.bounds.x1
  end
  if not xh then
    return
  end
  local ya = (o.y + o.bounds.y1) - (b.y + b.bounds.y1)
  local yh = false
  if ya < 0 then
    yh = abs(ya) <= o.bounds.y2
  else
    yh = ya <= b.bounds.y2
  end
  if yh and b.shooter == player then
    kills = kills + 1
  end
  return yh
end

function spawn()
  return soldierf(1,64,61*8,1.5,0.25, game_mode.hp)
end

function spawn_nazis()
  local spawny = player.y - 104
  if spawny < 8 then
    return
  end
  for i=0,current_level.nazi_spawn_rate + game_mode.spawn do
    local spawnx = 16 + (i*(96 / current_level.nazi_spawn_rate))
    
    local s = soldierf(5, spawnx, spawny, 1 + rnd(1), 0.1 + rnd(0.5), 1)
    while cmap(s) do
       s.y = s.y-4
    end
    s.states = sprstates.nazi
    s.state = s.states.standing
    s.shoot_dir = 1
    -- s.confines = {max(0, spawnx - 64), min(112, spawnx + 64)}
    add(nazis, s)
  end
end

function draw_hud()
  rectfill(2+current_level.offset, cam_y +119, 9+current_level.offset, cam_y+125, 0)
  spr(31, 2 + current_level.offset, cam_y + 118)
  prtext(tostr(player.hp).." - kills: "..tostr(kills).." - deaths: "..tostr(casualties), current_level.offset+12, cam_y + 120, 7, 0)
end

function update_high_scores()
  local new_score = {["name"] = "anon", ["score"] = kills - casualties}
  if #high_scores == 0 then
    add(high_scores, new_score)
    return
  end
  local sorted_scores = {}
  local added_score = false
  for high_score in all(high_scores) do
    if high_score.score > new_score.score then
      add(sorted_scores, high_score)
    else
      add(sorted_scores, new_score)
      add(sorted_scores, high_score)
      added_score = true
    end
  end
  if not added_score then
    add(sorted_scores, new_score)
  end
  high_scores = sorted_scores
end

function end_level(level)
  del_all(bullets)
  del_all(grenades)
  del_all(booms)
  del_all(nazis)
  del_all(cannons)
  level += 1
  if level <= #levelstates then
    init_level(level)
  else
    update_high_scores()
    _draw = draw_title
    _update = update_title
    camera(0,0)
  end
end

function _init()
  _update = update_title
  _draw = draw_title
end
function _draw()
end
function _update()
end

function game_update()
  foreach(nazis, make_decision)
  foreach(cannons, update_cannon)
  foreach(bullets, update_bullet)
  foreach(grenades, update_grenade)
  foreach(booms, update_boom)
  foreach(bosses, update_boss)
  foreach(smokes, update_smoke)
  update_soldier(player, btn(0), btn(1), btn(2), btn(3), btn(4), btn(5))
  local present_cam = max(min(player.y - 96, 424), 0)
  add(cam_positions, present_cam)
  cam_y = cam_positions[1]
  del(cam_positions, cam_y)
  if player.y < 0 and #bosses == 0 then
    end_level(current_level.number)
  end
end

function game_draw()
  cls()
  camera(cam_x, cam_y);
  map(0, 0, 0, 0, 128, 64)
  draw_thing(player)
  foreach(nazis, draw_thing)
  foreach(cannons, draw_thing)
  foreach(bullets, draw_thing)
  foreach(grenades, draw_thing)
  foreach(booms, draw_thing)
  foreach(current_level.overheads, draw_thing)
  foreach(bosses, draw_thing)
  fillp(0b0101101001011010.1)
  foreach(smokes, function(s)
      s:draw(current_level.offset)
    end
  )
  fillp()
  draw_hud()
end

function init_level(level)
  current_level = levelstates[level]
  player.y = 488
  cam_x = current_level.offset
  cam_y = 0
  cam_positions = {392, 392, 392, 392, 392, 392, 392}
  spawn_nazis()
  cannons = {}
  bosses = {}
  foreach(current_level.cannons, function(c) add(cannons, cannonf(c)) end)
  foreach(current_level.bosses, function(b) add(bosses, bossf(b)) end)
end

function prtext(text, x, y, colour, back)
 back = back or 0
 for x_ = -1,1 do
   for y_ = -1,1 do
      print(text, x + x_, y + y_, back)
   end
 end
 print(text, x, y, colour)
end

function draw_title()
  cls()
  prtext("tuesday 6th june, 1944", 20, 32, 7, 3)
  prtext("d-day", 54, 40, 7, 3)
  prtext("press fire to start", 26, 48, 7, 3)
  local line = 64
  for gm in all(game_modes) do
    if gm == game_mode then
      prtext(">"..gm.name.."<", 44, line, 7, 3)
    else prtext(gm.name, 44, line, 8, 1)
    end
    line += 8
  end
  prtext("high score", 44, line + 8, 7, 3)
  if #high_scores == 0 then
    prtext("---- ----", 44, line + 16, 7, 3)
  else
    prtext(tostr(scores[1].score), 44, line + 16, 7, 3)  
  end

end

function update_title()
  local gmcount = 1
  local gmindex
  for gm in all(game_modes) do
    if gm == game_mode then
      gmindex = gmcount
    end
    gmcount +=1
  end
  if btnp(2) and gmindex > 1 then
    game_mode = game_modes[gmindex-1] 
  end
  if btnp(3) and gmindex < #game_modes then
    game_mode = game_modes[gmindex+1]
  end
  if btnp(4) then
    _update = game_update
    _draw = game_draw
    casualties = 0
    kills = 0
    player = spawn()
    init_level(1)
  end
end

__gfx__
00000000cccccccc9999999a9999999999999999996ccccc99ccccccccccc6999999999999d5555555555555555d999900003000000000030000000000000000
00000000cccccccc999999999999499999999999996ccccc996cccccccccc699999999999d5d65d6d6d6d6d666d55d9900282300082003000000000000000000
00000000cccccccc999999999949ff49999999999966cccc9996cccccccc699999999999d5d5dd6666666666666665d900025010300052800000000300000000
00000000cccccccc999f9a9994999f999999fff9999ccccc999fc6c6cccc6999699f99991dd6d6dd6666666666666d5900555010085228000850800000000000
00000000c676c6769999999999499f499996f7cf9996cccc9999f969cccc6f996f9c69995d5d5d5d666666666666665d05335510853355102582858005000500
00000000cccccccc9f9999999499ff99996ccccc9996cccc99999999ccccc999cccc999915d5d5d5d6d6d6d6d66d65d500355000003550000825882028802882
00000000cccccccc9999999999494949996ccccc9996cccc99999999ccc69f99ccc6f9995d6d6d6d15151515d6d5d65500505000005050000050500088585880
00000000cccccccc9999a999949499999966cccc996ccccc99999999ccccc999ccccc9991d666665511151115565665500000000000000000000000000000000
cccccccccccccccc99999999999999999999999999999999ccccccccccccc699cc9c9c9c5dd5d5d5998998990000000000833800008368000000000000000000
ccccccccc6776ccc99999999999999999999999999999999ccccccccccccc699ccccc9c91d6d6d6d999999990000000008333380083636800011110000000000
cccccccccccccccc99999999999999999999999999999999c6c6f6cccc6669999c9c9c9c5d666665898945290000000000855810008568100122261008877880
cccccccccccccccc999999999999fff9999999999999999969ff69c6699f9999c9ccc9c91d66666598445f590000000008555810085658100126661008888880
cccccccccccccccc99999999fff677cffff999cf6c66c6669999999999999999cc9c9c9c5d6d6d6d999144980000000085335510856365100126221008788780
cccccccccccccccc9999999967ccccc6cccc9ccccccccccc9999999999999999c9c9ccc915d6d6d6924818490000000008355880083658800122261008777780
cccccccccccccccc99999999cccccccccccccccccccccccc9999999999999999cc9c9c9c5d5d5d5d299498990258582008585800086868000011110008777780
cccccccccccccccc99999999cccccccc676ccccccccccccc9999999999999999c9ccc9cc10d0d0d0998992990000000008505800085058000000000000000000
4999999499999994999999999999999999999999cc9ccc9c0003300000000000000000000000000000000000000000000000000000000000000000009ccccccc
9999499949994999999944999449944949994499c9c9ccc9003333000003300000000000000000000000000000000000000000000000000000111100c9cccccc
99999949949499499944664446644664d44466499c999c9c0005501000333300000330000000000000000000000000000000000000000000013333109c9c9ccc
949494949949499994d6446dddddddddd4d64459c9ccccc9005550100005501000333300000330000000000000000000000000000000000001366310c9c9cccc
994999499494949995dd4d4d4d4dd4d4d5dd4d59cccc9c9c0533551000555010000550100033330000033000000000000000000000000000013333109c9c9c9c
49949494494949499554d4d5d5d55d5d4554d459c9c9ccc9003550000533551000555010000550100033330000033000000000000006700001366310c9c9c9cc
9449494994944999999545555555555555954599cc9ccc9c0050500000355000053355100055501000055010003333000003300000500700001111009c9c9c9c
49949494994999949999999999999999999959999cc9c9c9000000000050500000355000053355100055501000055010003333000005600000000000c9c9c9c9
00033000000330000003300000033000000330000003300000033000000330000048840000000000000000000000000000000000cccccccc9c9c9c9c9c9c9c9c
00333300003333000033330000333300003333000033330000333300003333000488880000000000000000000005000000000000ccccc9c9c9c9c9c9c9c9c9cc
0005501000055010000550100005501000055010000550100005501000058880088a8880048a8840005050000500050000000000cccccc9ccc9c9c9c9c9c9ccc
005550100055501000555010005550100055501000555010005550100089981008aaaa90089aaa90000009000000000000000000ccccc9c9ccc9c9c9c9c9c9cc
05335510053355100533551005335510053355100533551005335510089a991089a7aa9089aaaa900909a9900050009000500050cccc9c9ccc9c9c9c9c9c9ccc
0035500000355000003550000035500000355000003550000488840089aaa90099aaa9809aaaa9a404aa9aa00480080000000500c9c9c9c9ccccc9c9c9cccccc
00505000005050000050000000505000000050000050500004998400049a8800899a9a80849a9a88049a9a800494848004545550cc9c9c9ccccc9c9c9c9ccccc
00505000005000000050000000000000000050000000500000484000004840008948484044484844004848400040040000505500c9c9c9c9ccccccc9c9cccccc
05050505000000000000000044000000000000000000004944444444955ddd5995dddd5999999999999999999c9c9c9c9c9c9c99999999990011111100000000
5050505000000000001010009400000000000000000000444545454594dd5d5991ddd41999555599999999c999c9c9c9c9c9c9c9c99999990111166100011110
040404040000000001535100445050505050505050505049505050509555555995dddd59954dd45999999c9c999c9c9c9c9c9cc99c9999990111ffff00111110
404040400005d00000351510945555555555555555555544050505059454454994dddd5994dddd599999c9c99999c9c9c9c9c999c9c9c99901f5ff5f01111f11
040404040005d000015153004454545454545454545454490000000095dddd59914ddd1991dddd4999999c9c999c9c9c9c9c99999c9c99990ff6ff6f0115f561
4040404000000000001535109445454545454545454545440000000095dddd4994dddd4994ddd41999c9c9c9999999c9c9c99999c9c9999904ff1ff401f515f1
0505050500000000000101004944444444444444444444490000000094dddd5995dddd4995dddd499c9c9c9c9999999c999999999c9c9c9900ff6ff000f616f0
505050500000000000000000949494949494949494949494000000009944449995dddd5995dddd5999c9c9c999999999c9999999c9c9c9c90046664000ff1ff0
000000000000000000000000000000000000000000000000000000004444444444444449789987990055550000555500005555003333bb331122221100ff5ff0
00000000000000000000000000a09a000a8008080a00080000000400954545454545454477889898002812001028120000281201333333334124421400245240
00000000000000000800008008779a800a788aaa9990000a090000044450505050505049878997980001f1005001f1000001f1053b33333b4144441405444445
000000000000000080898900907777a9a0a997a999a007a940900040940505050505054499998989501f5f05551f5f05501f5f5533333b334144441455444445
0000000000000000089aaa809aa7778a9a9997999a909090090000004400000000000049978987790588451005884510058845503b3333331011111050144415
000000000009900089aa7a9899aa7aa89984849890800999408000909400000000000044897979880588451005884510058845003b33b33b0055055055554450
00000000009a89000889898089998999884000490000004000000000440000000000004979897897015505500055055001550550333333330055055044488845
000890000008900000989800089848984800000498000009400000049400000000000044897997870055055005500550005500553333b3330011011048888888
00000000000000000000000000000000000000000000000015555551155555511000000000000001005555000055550033333333000000000000000000000000
008788000000000000000000000000000000000000000000015dd5100155d510511111000011111500281200002812003b3333b3000000000000000000000000
002812000087880000000000000000000000000000000000015dd510015d551055551000000155550001f1000888810033333333000110000000000000000000
000ff0000028120000878800000000000000000000000000015dd5100155d51055d555d55d555d55501f5f058999988933b33433001111100000000000000000
001f5000000ff0000028120000878800000000000000000001155110011551105d5d555dd555d5d50588451089aaa99833334433011111110001100000000000
05444510001f5000000ff000002812000087880000000000015005100105501055551000000155550899881089a7aa9834349944011111110011111000000000
0544411005444510001f5000000ff000002812000087880000500500000510005111110000111115089a998009a7a98049499999011515110111111000000000
015050100544411005444510001f5000000ff0000028120000155100000150001000000000000001008a988009a798809999999900f515500011111000110110
00878800008788000087880000878800008788000087880000878800008788005446664599999956005555000005040000000000005555500001110000010008
00281200002812000028120000281200002812000028120000281200002812004867006899999956002812000028080000000000002f5f500005550000000108
000ff000000ff000000ff000000ff000000ff000000ff000000ff000000f8880460f0f7699999956000884000488080000000000000f4f000005550480000000
001f5000001f5000051f5000001f5000001f5510001f5510001f5000008998104600000699999956584888455888084500000000000f4f0804444f4400010040
05444510054445100544451005444510054441100544411005444510089a9910467f0f06999999560488488004840880000000000805585888fffff880f800f8
0544411005444110014441100544411005444010054440100488841089aaa9104860076899994956058808400484048000000000585588858855888548004000
01505010015050100000501001505010015000100150501004998410049a88104886668899499946015405500180008000000000588888485880084854000848
00505010000050100000501000000010005000000050000000484010004840105444444599949994005505500050055000000000488888884800008808000080
2121212121212121212121212121212190a0a0b090a0b090a0a0b090a0b090b0212121212121a4f3d42121212121212121212121212121212121212121212121
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3232323232422121223232324221223291021291910291911202919112919191528152815281528152815281528152812121212121212121212121212190a0b0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212112212121212191120291911291910212919102919191010101e3810101010101010152f3010132323232423022423022423030910091
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30212130203021211230212130213021213021212121212121302121212121210101010152010101010101018101010121212121212121212121212121211291
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21202121212121212121202121212121212121212121212121212121212121218152815281528152815281525281528121943030303030303030303030303091
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121302130212130212130212130202175646464852121756464852121756464212021b452c42121212121b481c4212121743021212121212121212121212191
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31414151513141515141313151513141344444445421213444445421213444443021213021302121302121302130212121224221303030303030303030302191
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01f28152818152528181818181f30101212121212121212121212121212121212121212121212121212121212121212121302121942121212121212194212191
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
810101818152818152528152f3010101212121212121212121212121212121213242202232323232323232324220223221302130842194223242942184212191
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
81f20101e3528152815281f301d38101219421942102129421943002309421942194219434444444444444549421942121212121842184218721842184212191
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8181816101e3525252f3010181816101218421840212028421840212028421842184218421212121212121218421842132323232742174219721842184218791
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
61616121616161616161616161612121218421841202128421843002128421842184208421212121212121218420842187212121212121212121842174219791
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21212121212121212021212021a12121218421840230028421840230028421842184218421212121212121218420840297021202120212022121740212021291
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21212021a12121212020212121212121218421843012308421841202218421841274207421212121212121217421741232323232323232420222323232323232
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21212020212020212121212121212121217421740212217421740221217421740221212121212121212121212121210264646464646464851275646464646464
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21212120212121212121202120212121212121212121212121212121212121211202120221212121212121210212021204919191919191542134919191919104
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121a121212121212021a12121212120212121212121212121212121212121213232323232324212223232323232323204040404040402022112020404040404
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121202121212121a121212120212121212121212121212121212121212121212121212121212121212121212121212104919191919191912191919191919104
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212140314180212232323242a122323232422122323232323232323232422121212232323232323204919191919191912191919191919104
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c2c3c000000000000000000000000
21202121a12021212120501011702121120212029502120212021202120202121202120212022120211202120212021204040404040402122112020404040404
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d2d3d000000000000000000000000
323232422020212121215011017021222121a12102122121a1212121952102212121212121212121212121212121212004919191919191912191919191919104
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e1e2e3e000000000000000000000000
212121212121212121a1601081712121212121211221a1212121a12121212121202121a4d4212232422121a42121212104919191919191912191919191919104
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f1f2f3f000000000000000000000000
212232323242212121214001702021212121952121952121211221212121a1212121a452c42121212121a452d421212004040404040402122112020404040404
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
212021212121212121215010702121200212301202212195212121a130212121212121b4212021202121b4c42121212104040404040404852175040404040404
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21213021a12121302121500170302021212021a11230202121123002212095210221213021212121212121302121210244444444444444542134444444444444
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31414151513141515141500170513141212120212020214051802020408020211221302121202121212120213021211221212121212121212121212121212121
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01e38152818152528181818181f3010102120220408181f301818181018181810230213021212121212121302130210221212121212121212121212121212121
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101e3818152818152528152f30101011240818181e352f2d38181f3018181811221302130212120212130213021301221212121212121212121212121212121
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101e3528152815281f3010101014081f3010101e3818181f301018181810220212121212121212121212121210221212121212121212121212121212121
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110010101e3525252f301010101010181f301010101d38181815281528152521275646485212121212175646485211221218721212121212121212187212121
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010101010101e381f3010101010110015201d3528152818152f301528152815202344444542190a0b02134444454210221219721202020212121212197212121
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010110010101010101323232323232422022323232323232323232323232329120913232323232323232323232323242212232323232323232
__gff__
0004000200000000000108010000000004040000000000000001000000000000000001010100000000000100000000000000000000000000000000000000000004002000000004010101000000000000002020202020200404000000000000000000000000000000000000000000000000000000000000000101000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2323232323232319001923232323232323232403222323242022232324032223232323232323241222232323232323235d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121a12121202020212121212121221202120212021202120212021202120781212121212121212121212121212785d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121212121202031202121212121220212021202120212021202120212021781212121212121212121212121212786c786c6c6c6c6c6c6c6c6c6c6c786c6c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212021212120312031203121212121202120212021202021202120202020212781212121212121212121212021212781279121212121212121212121279121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121212021212121212120212121202121212121212121212121212121212781212121212121212121212121212781212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121203121203120312120312121212121212121212120212021212121212781212121212121202121212121212781212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121212121212121212121212121212121202121212121212121212021212781212021212121212121212121212781212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1204131408121212121212222323232312121212121212121222232324121212787812121212121212121212121278781212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1205011107121202121212121212121212121212121202021212121202121212797878781212121212121212787878791212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1205110107121212121203120212031224124912491202491249030249124903127979787878781212787878787979121212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
120616161712121212121212121212121203480248222448124802024812481212121279797979121279797979121212787878787878090a0b7878787878787850005000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
121212121212090a0b0212031212031212124712470212470247120347124712121212121212121212121212121212127979797979791900197979797979797900090009000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
12021212121219001912121212121212121212020212121212020202020212121212121212121a1212121212121212121921192119211921192119211921192108090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
232323232323192119232323232323231212020202121222241212120212121223240222232323240322232323232403030312191203121212191212120312120a0a0a0a070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212021212121212120212121212121a1202021212121212121212020212121220212057464646464646464646464646031212031212190312121203121203120a0a0a0a0a0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015000000
121212121212121212121212121212124d12121212121212121212121212121221202143444444444444444444444444031912121912191203121912121912120a0a520a0b1900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014150000
12121212121212121212121212121212254d120212120202024a254d12120212202120201212121a1212121212121212031212121212121212191212031212120a700a0b190900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014140000
12212012212022232403222403222324182518252518251825253f3e25184d02212021202112121212121212121212121912191219121912191219121912191909070809070800000000000000000000000000000000000000000000000000000000000000001500000000000000000000000000000000000000000044450000
21202120202112121212121212121212101010103e252518253f1010103e1825202120212020121212121212121212121212121212121212121212121212121203030303030303030015000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000014140000
2021202120121212121212121212121210101010103e182518182f1010101010232323232323232323232323232324121212121212121249121212121212121220202020202020203914000000000000000000000000000000000000000000001500000000001415000000000000000000000000000000000603030303030303
212021201212121212121212121212121010101010101025024b252f10101010121212121212121212121212121212121212121212121248121212121212121223232323232323232739000300000000000000000000000606000000000015001415000000151414000000000000000000000000000000030302020202020202
202120120413140812121212121212122518252f10103d1812124b25252f1010121212121212121212121212121212121278121278121248121278121278121228282828282828272828180203030303030300000070000606000000150014001414000000145014000000000000700000000000700000020202020202020202
1220211205101007122223232412121212124b251825184c121212124b252525122223232323232323232323232323231279121279121248121279121279121206060606060638383838380202020202020203030303030303007000140414001414000404141414000000000303030303030303030303020202020202020202
121212120616161712121212121212121222241212121212121212121212124b121212121202120312121212121221031212121212121248121212121212121203030303030303700370030202020202020202020202020202030303030303030303030303030303030303030202020202020202020202020202020202020202
1212121212121212031212121212031212121212121212121212020222232323030212021212121212121212121212211212121202021248020212121212020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
2323242223232412121212121212121212030212122223241212120212120312232323232323232323232323232324121212121202121247121202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
2012121212121212121212121212121212121212021212031222232402121212031212121212120312121212121212121212121212121212121212121212121202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
2120211212121212121212122120212112021212121212121212121212121212121212121212121212121212121212031212121212121212121212121212121222220202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
1212121212121212121212121220212012222323241212121212121212121212122223232323232323232323232323231212211221121212121212211212121223230202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000200020000000000
1212121212121212121212121212121212121212121212021212121222232412121212121212121212121212121212121212122012121212121212201220211202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000
1202122223242012121212201212121212021212121212121212021212120212121212121212121212121212121212121220122112121212121212122002020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000
1220121212122112121212121212021212121212121a12121a12121212121212121212121212121202121212121202020221201202120202021212211212120202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0003000000000000000000000000000000000000000185701c5701f57024570185701c5701f57024560185601c5601f56024560185501c5501f550245501a5501d5501f540245401a5301d5301f530235301a530
001000000c575240050c57001515015150c00501545015550c572015060c57501535015350150501550015550c5450c5560c5350c5260c5420c5550c5450c5550e575015050d57501546015450c0050154201525
001000001057501100105700154501545187000154501550115752470011575015500154527700015500154511545115501155011545115451155011545115501357522700105750152001545015500154501550
001000000d545015250d550015500d555015500d553015500d525015500d550015500d525015500d550015500d556015550d555015500d525015500d550015500d525015500d550015500d525015540d55001550
00100000143750100514375094550b4551045513455155051435514305143550a4550c47511475134750a4550c47511475134750a4550c45511475134750c405143550c405143550b4550d45512455144550c405
01100000180721a0751b0721f0721e0751f0751e0721f075270752607724075200721f0751b0771a0751b07518072180621805218042180350000000000000000000000000000000000000000000000000000000
011000000c37518375243751f3751b3721a372193711b372183721837217371163511533114311133001830214302143021830218302003000030000300003000030000300003000030000300003000030000300
011000000c37300300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000000001e0701f070220702a020340103f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002b7602e7503a73033740377302e75033730337303372035710377103a710337103a7103c7103c7003f700007000070000700007000070000700007000070000700007000070000700007000070000700
00020000190501d65013650310500c6400e63022620116300b63004630026101b6100861003610076101260013600106000d60010600116000e6001160012600116000a600066000960003600026000260002600
000100002257524575275652455527555275552b54524525225352252527525275252b5252e515305152e515305052e505305052e5053050530505335052b5052e5052b5052e5052e5053350530505335052e505
000200002005325043160231002304013030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102000013571165731b5751d5711157313575165711b5731b575225711b573185751b5711f573245751b5711f57324565295611f563185611d555245532b5552b5412b5433053137535335333a5212b5252e513
000200002b071270711b07118071100710b0710607104071040610606103061040510305101041010310102101011040110000000000000000000000000000000000000000000000000000000000000000000000
010200002e17029170171731a171231631d16111143141610c1230a11107110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
01040000185702257024570225701f5701d5701f5701d57018570165701857016570135701157013570115700c5700d570135701457018560195501f550205302453024520225202452022510245102251024500
__music__
00 01434144
00 01434144
00 02434244
00 02434244
00 03414144
02 03414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144
00 41414144

