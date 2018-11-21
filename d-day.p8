pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- d-day
-- by projectsam

-- to do:
-- levels and monsters
-- title / restart logic
-- block loot
-- top-solid ground
-- better duping

music(0, 0, 3)

sprtype = {[1] = 48, [3] = 65, [4] = 64, [5] = 112}
sprstates = {
     ["soldier"] = {
     	 ["standing"] = {48},
		 ["running"] = {48,48,48,48,49,49,49,49,50,50,50,50,51,51,51,51,52,52,52,52,53,53,53,53},
		 ["exploding"] = {54,54,54,55,55,55,56,56,56,57,57,57,58,58,58,59,59,59,60,60,60},
		 ["drowning"] = {38,38,38,39,39,39,40,40,40,41,41,41,42,42,42,43,43,43,44,44,44,45,45,45}
	},
	["nazi"] = {
	    ["standing"] = {112},
		["running"] = {112,112,112,112,113,113,113,113,114,114,114,114,115,115,115,115,116,116,116,116,117,117,117,117},
		["exploding"] = {118,118,118,119,110,119,56,56,56,57,57,57,58,58,58,59,59,59,60,60,60},
		["drowning"] = {96,96,96,97,97,97,98,98,98,99,99,99,100,100,100,101,101,101}
	}
}

sprites = {}
bullets = {}
player = {}
nazis = {}
nazi_spawn_rate = {5, 2}

function bulletf(type, x, y, vx, vy, shooter)
 local b = {}
 b.shooter = shooter
 b.x = x
 b.y = y
 b.type = type
 b.basesprite = sprtype[type]
 b.sprite = sprtype[type]
 b.vx = vx
 b.vy = vy
 b.range = 128
 b.dt = 0
 b.hashit = false
 define_bounding_box(b, 3, 4, 4, 7)
 return b
end

function define_bounding_box(o, x1, y1, x2, y2)
  o.bounds = {["x1"] = x1, ["x2"] = x2, ["y1"] = y1, ["y2"] = y2}
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
 end
end

function soldierf(type, x, y, maxspeed, acc)
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
 define_bounding_box(s, 1, 2, 6, 7)
 return s
end

function kill_soldier(o)
  if o.tick > #o.state then
	  if o == player then
      player = spawn()
	  end
	  del(nazis, o)
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
  if player.x < o.x and o.x > o.confines[1] then
	left = true
  end
  if player.x > o.x and o.x < o.confines[2] then
    right = true
  end
  if player.y > o.y then
    down = true
  end
  if player.y < o.y then
    up = true
  end
  if abs(player.x - o.x) < 4 then
    fire = true
  end
  update_soldier(o, left, right, up, down, fire)
end

function update_soldier(o, left, right, up, down, fire1)
  if o.busy then
    kill_soldier(o)
	return
  end
  local lx = o.x
  local ly = o.y 
  if o.fire > 0 then
   o.fire -= 1
  end
  if left then
	if abs(o.dx) < o.maxspeed then
		o.dx -= o.acc    
    end
  elseif right then 
	if abs(o.dx) < o.maxspeed then
		o.dx += o.acc
	end
  else
    if o.dx < 0 then
		o.dx += o.acc
	elseif o.dx > 0 then
	    o.dx -= o.acc
	end
  end
  if up then
	if abs(o.dy) < o.maxspeed then
		o.dy -= o.acc	
    end
  elseif down then 
	if abs(o.dy) < o.maxspeed then
		o.dy += o.acc
	end
  else
    if o.dy < 0 then
		o.dy += o.acc
	elseif o.dy > 0 then
	    o.dy -= o.acc
	end
  end
  
  o.x += o.dx
  o.y += o.dy
  o.tick += 1
  if cmap(o) then
    o.x = lx
	o.y = ly
  end
  if o.dx == 0 and o.dy == 0 then
    o.state = o.states.standing
  else
   o.state = o.states.running
  end
  if fire1 and o.fire == 0 then
    o.fire = o.f_throttle
    add(bullets, bulletf(3, o.x, o.y+(o.shoot_dir*8), 0, o.shoot_dir * 2, o))
  end
  if cmap(o, 1) then
    o.state = o.states.exploding
	o.tick = 1
	o.busy = true
	kill_soldier(o)
  end
  if cmap(o, 2) then
    o.state = o.states.drowning
	o.tick = 1
	o.busy = true
	kill_soldier(o)
  end
  local h = false
  local bullcheck = function(b)
    if not h then
      h = beenhit(o, b)
      if h then
        del(bullets, bullet)
      end
    end
  end
  foreach(bullets, bullcheck)
  if h then
    o.state = o.states.exploding
    o.tick = 1
    o.busy = true
    kill_soldier(o)
  end
  setsprite(o)
end

function setsprite(o)
  if o.tick > #o.state then
     o.tick = 1
  end
  o.sprite = o.state[o.tick]
end

function draw_thing(thing)
  if not cmap(thing, 3) then
    spr(thing.sprite, thing.x, thing.y)
  end
end

function cmap(o, f)
  f = f or 0
  local ct=false
  local cb=false
  local x1=(o.x+o.bounds.x1)/8
    local y1=(o.y + o.bounds.y1)/8
    local x2=(o.x+o.bounds.x2)/8
    local y2=(o.y+o.bounds.y2)/8
    local a=fget(mget(x1,y1),f)
    local b=fget(mget(x1,y2),f)
    local c=fget(mget(x2,y2),f)
    local d=fget(mget(x2,y1),f)
    ct=a or b or c or d
  return ct
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
  return yh
end

function spawn()
  return soldierf(1,64,336,1.5,0.25)
end

function spawn_nazis()
  for i=0,nazi_spawn_rate[2] do
    local spawnx = 16 + (i*(96 / nazi_spawn_rate[2]))
    local spawny = player.y - 112
    local s = soldierf(5, spawnx, spawny, 1.25, 0.25)
    s.states = sprstates.nazi
    s.state = s.states.standing
    s.shoot_dir = 1
    s.confines = {spawnx - 16, spawnx + 16}
    add(nazis, s)
  end
end

player = spawn()
cam_x = 0
cam_y = 0
cam_positions = {player.y - 64, player.y - 64, player.y - 64, player.y - 64, player.y - 64, player.y - 64, player.y - 64}

function _init()
  add(sprites, player)
  spawn_nazis()
end

function _update()
  update_soldier(player, btn(0), btn(1), btn(2), btn(3), btn(4))
  foreach(nazis, make_decision)
  foreach(bullets, update_bullet)
  add(cam_positions, player.y - 64)
  cam_y = cam_positions[1]
  del(cam_positions, cam_y)
end

function _draw()
  cls()
  camera(cam_x, cam_y);
  map(0, 0, 0, 0, 128, 64)
  draw_thing(player)
  foreach(nazis, draw_thing)
  foreach(bullets, draw_thing)
end

__gfx__
00000000cccccccc9999999a9999999999999999996ccccc99ccccccccccc6999999999999d5555555555555555d99992000000025522552cc5ccccc20000000
00000000cccccccc999999999999499999999999996ccccc996cccccccccc699999999999d5d65d6d6d6d6d666d55d995200000052255225c55555cc50000000
00000000cccccccc999999999949ff49999999999966cccc9996cccccccc699999999999d5d5dd6666666666666665d9252000002552255255555ccc20000000
00000000cccccccc999f9a9994999f999999fff9999ccccc999fc6c6cccc6999699f99991dd6d6dd6666666666666d595252000052255225c555cccc52020000
00000000c676c6769999999999499f499996f7cf9996cccc9999f969cccc6f996f9c69995d5d5d5d666666666666665d2525200025522552cc5ccccc25252000
00000000cccccccc9f9999999499ff99996ccccc9996cccc99999999ccccc999cccc999915d5d5d5d6d6d6d6d66d65d5525252005225522555cccccc52525000
00000000cccccccc9999999999494949996ccccc9996cccc99999999ccc69f99ccc6f9995d6d6d6d15151515d6d5d65525252520255225525ccccccc25252500
00000000cccccccc9999a999949499999966cccc996ccccc99999999ccccc999ccccc9991d66666551115111556566555252525252255225cccccccc52525250
cccccccccccccccc99999999999999999999999999999999ccccccccccccc699cc9c9c9c5dd5d5d5998998990000000ddddd2525dddddddd000000002525252d
ccccccccc6776ccc99999999999999999999999999999999ccccccccccccc699ccccc9c91d6d6d6d99999999000000dd5ddd5252dddddddd000000005252525d
cccccccccccccccc99999999999999999999999999999999c6c6f6cccc6669999c9c9c9c5d6666658989452900000dd525d5dd252ddddd2500000000252525dd
cccccccccccccccc999999999999fff9999999999999999969ff69c6699f9999c9ccc9c91d66666598445f590000ddd252ddddd252dddd520000000052525ddd
cccccccccccccccc99999999fff677cffff999cf6c66c6669999999999999999cc9c9c9c5d6d6d6d99914498000dddd5252ddd252525d5250000000025252ddd
cccccccccccccccc9999999967ccccc6cccc9ccccccccccc9999999999999999c9c9ccc915d6d6d69248184900dddd52525d52525252525200000000525252dd
cccccccccccccccc99999999cccccccccccccccccccccccc9999999999999999cc9c9c9c5d5d5d5d299498990dd5d525252525252525252500000000252525dd
cccccccccccccccc99999999cccccccc676ccccccccccccc9999999999999999c9ccc9cc10d0d0d099899299000000000000000052525252000000005252525d
9999999999999999999999999999999999999999cc9ccc9c00033000000000000000000000000000000000000000000000000000000000000000000000000000
9999999949994999999944999449944949994499c9c9ccc900333300000330000000000000000000000000000000000000000000000000000000000000000000
99999949949499499944664446644664d44466499c999c9c00055010003333000003300000000000000000000000000000000000000000000000000000000000
949494949949499994d6446dddddddddd4d64459c9ccccc900555010000550100033330000033000000000000000000000000000000000000000000000000000
994999499494949995dd4d4d4d4dd4d4d5dd4d59cccc9c9c05335510005550100005501000333300000330000000000000000000000000000000000000000000
49949494494949499554d4d5d5d55d5d4554d459c9c9ccc900355000053355100055501000055010003333000003300000000000000670000000000000000000
9449494994944999999545555555555555954599cc9ccc9c00505000003550000533551000555010000550100033330000033000005007000000000000000000
99949499994999499999999999999999999959999cc9c9c900000000005050000035500005335510005550100005501000333300000560000000000000000000
00033000000330000003300000033000000330000003300000033000000330000048840000000000000000000000000000000000000000000000000000000000
00333300003333000033330000333300003333000033330000333300003333000488880000000000000000000005000000000000000000000000000000000000
0005501000055010000550100005501000055010000550100005501000058880088a8880048a8840005050000500050000000000000000000000000000000000
005550100055501000555010005550100055501000555010005550100089981008aaaa90089aaa90000009000000000000000000000000000000000000000000
05335510053355100533551005335510053355100533551005335510089a991089a7aa9089aaaa900909a9900050009000500050777700000000000000000000
0035500000355000003550000035500000355000003550000488840089aaa90099aaa9809aaaa9a404aa9aa00480080000000500777777000000000000000000
00505000005050000050000000505000000050000050500004998400049a8800899a9a80849a9a88049a9a800494848004545550777777700000000000000000
00505000005000000050000000000000000050000000500000484000004840008948484044484844004848400040040000505500777777770000000000000000
00000000000000000077770000777700e7e7e7e7e7e7e7e7000000000000000000000000000000000000000000000000000000000eeeee000eeeee0000000000
00000000000000000700007007000070222222222222222200000000000000000000000000000000000000000eeeee000eeeee00eeeeeee0eeeeeee00eeeee00
000660000000000070099007700990072ff22fff2fff2f220000000000000000000000000000000000000000eeeefee0eeeeeee0ef1ff1e0ef1ff1e0eeeeeee0
005dd6000000000070999907709999072f222f2f2f2f2f220000000000000000000000000000000000000000ef1ff1e0ef1ff1e0eeffffe0eeffffe0ef1ff1e0
005556000000000079999997799999972f2f2f2f2fff2f220000000000000000000000000000000000000000eeffffe0eeffffe0eeccce00eeccce00eeffffe0
005dd6000005d00070099007700990072fff2fff2f2f2ff20000000000000000000000000000000000000000eeccce00eeccce000077780008777000eeccce00
005dd600000d60000709907007099070222222222222222200000000000000000000000000000000000000000077700000777800008000000000080008777000
00555600000d60000077770000777700e7e7e7e7e7e7e7e700000000000000000000000000000000000000000080800000800000000000000000000000008000
0000000000000000000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000de000000ef0000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d17e0000ed7f000994399000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d1de7e00edef7f099a9979900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0efed1d00f7fede0949999a9aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ef1d0000f7de0094499999a0aaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ed000000fe00009449990a0a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000999900aaa000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00878800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00281200008788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ff000002812000087880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001f5000000ff0000028120000878800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05444510001f5000000ff00000281200008788000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0544411005444510001f5000000ff000002812000087880000000000000000000000000000000000000000000000000000000000000000000000000000000000
015050100544411005444510001f5000000ff0000028120000000000000000000000000000000000000000000000000000000000000000000000000000000000
00878800008788000087880000878800008788000087880000878800008788000000000000000000000000000000000000000000000000000000000000000000
00281200002812000028120000281200002812000028120000281200002812000000000000000000000000000000000000000000000000000000000000000000
000ff000000ff000000ff000000ff000000ff000000ff000000ff000000f88800000000000000000000000000000000000000000000000000000000000000000
001f5000001f5000051f5000001f5000001f5510001f5510001f5000008998100000000000000000000000000000000000000000000000000000000000000000
05444510054445100544451005444510054441100544411005444510089a99100000000000000000000000000000000000000000000000000000000000000000
0544411005444110014441100544411005444010054440100488841089aaa9100000000000000000000000000000000000000000000000000000000000000000
01505010015050100000501001505010015000100150501004998410049a88100000000000000000000000000000000000000000000000000000000000000000
00505010000050100000501000000010005000000050000000484010004840100000000000000000000000000000000000000000000000000000000000000000
21212121212121212121212121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21212121212121212232323242212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21212121212121212121122121212121000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
21212121202121211221212130212121000000000000000000000000000000000000c3d300c3c300d30000c3d300050000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120212121212121212120212121212100000000000000000000000000000000000000a300a3b300a30000a3b300c30000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121302121212130212121212130202100000000000000000000000000000000000000a300a3c300a3c300a30000a30000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3141415151314151514131315151314100000000a1a200000000000000000000000000a300c3c3c3c3c3c3c3c3c3c30000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101815281815252818181818101010100a1a2a1a3a3a200000000000000000000a3a3a300000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010181815281815252815201010101a1a3a3a3a3a3a3a2a1a20000a1a200000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101015281528152810101010101a3a3a3a3a3a3a3a3a3a3a2a1a3a3a2a10000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010152525201010101010101a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101011101010110010101a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01011001010101010101010101010101a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01011101010110010101010101010101a3a3a3a3a3a3a3a3a3a3a3a3a3a3a3a30000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010110010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c2c3c000000000000000000000000
0101010101a00101010111a001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d2d3d000000000000000000000000
0101010101a001010101010101011001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e1e2e3e000000000000000000000000
011101010101110101a0010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f1f2f3f000000000000000000000000
01010101010101010101010110010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01110101010101011001010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101011001010101100101110101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01110101010101010111010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101110101010101010101110101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010101010101011001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101010110010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0004000200000100000108010000010004040000000000000001000000000000000001010100000000000100000000000000000000000000000000000000000020002000010100000000000000000000200020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121a12121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121212121212121202121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212021212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121212021212121212120212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212121212121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1204131408121212121212222323232300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1205011107121202121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1205110107121212121203120212031200000000000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1206161617121212121212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000500050005000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
121212121212090a0b0212031212031200000000000000000000000000000000000000000000000000000000000000000000505050505040000000000009000900090009000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1202121212121900191212121212121200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009090708090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23232323232319121923232323232323000000000000000000000000004b4c00000000000000000000000000000000000000000000000000000000000009090a0a0a0a0a070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1212021212121212120212121212121a000000000000000000000000005b5c000000000000003629293700000000000000000000000015000000000000090a530a0a0a0a0a0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015000000
12121212121212121212121212121212000000000000000000000000000000000000000000002728262700000000000000000000000014250000000000090a0a0a0a520a0b1900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014150000
12121212121212121212121212121212000000000000000000000036292929293700000000002728272800000000000000000303030303030000000000090a0a0a700a0b190900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014140000
1221201221202223240322240322232400000000000000000000002827282726270000000000282728270000000000003918020222222202391800000009070809070809070800000000000000000000000000000000000000000000000000000000000000001500000000000000000000000000000000000000000044450000
2120212020211212121212121212121200000050000000000000002726282827280000000000383838380039183918392828222023232421282839391803030303030303030303030015000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000014140000
2021202120121212121212121212121200000000000000000000002828272827260000000070001213003938060638382828232324232323282728282820202320202020202020203914000000000000000000000000000000000000000000001500000000001415000000000000000000000000000000000603030303030303
2120212012121212121212121212121200000606060000000000002628282828270000000003030303030303030303032828282828282827282728282823232323232323232323232739000300000000000000000000000606000000000015001415000000151414000000000000000000000000000000030302020202020202
2021201204131408121212121212121200000000000000000000003838383838380000000002020202020222220202022828282828282728272828282828282828282828282828272828180203030303030300000070000606000000150014001414000000145014000000000000700000000000700000020202020202020202
1220211205101007122223232412121200001500000000000000000000121300000070000002022222222023232102023838383838383838383838383838380606060606060638383838380202020202020203030303030303007000140414001414000404141414000000000303030303030303030303020202020202020202
1212121206161617121212121212121225001400000000007000030303030303030303030302202323232323232321020303030303030303030303030303030303030303030303700370030202020202020202020202020202030303030303030303030303030303030303030202020202020202020202020202020202020202
1212121212121212031212121212031203030303030303030303020202020222020202022220232323232323232323212202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
2323242223232412121212121212121222222222020202020202020202202323212222202323232323232323232323232321220202020222222202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
2012121212121212121212121212121223232323212222020202022220232323232323232323232323232323232323232323232122222023232321222222222202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
2120211212121212121212121212121224232323242323212121202323232323232323232323232323232323232323232323232323232323232323232323232322220202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
1212121212121212121212121212121223232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323230202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202000200020000000000
1212121212121212121212121212121223232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232302020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000
1202122223242012121212201212121223232323232323232323232323232323232323232323232323232323232323232323232323232323232302020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000
1220121212122112121212121212021223232323232323232323232323232323232323232323232302232323232302020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01030000185701c5701f57024570185701c5701f57024560185601c5601f56024560185501c5501f550245501a5501d5501f540245401a5301d5301f530235301a5301d5301f5301a5201d510215102451023515
01100000240452400528000280452b0450c005280450000529042240162d04500005307553c5252d000130052b0451f006260352b026260420c0052404500005230450c00521045230461f0450c0051c0421c025
01100000187451a7001c7001c7451d745187001c7451f7001a745247001d7451d70021745277002470023745217451f7001d7001d7451a7451b7001c7451f7001a745227001c7451b70018745187001f7451f700
01100000305453c52500600006003e625006000c30318600355250050000600006003e625006000060018600295263251529515006003e625006000060018600305250050018600006003e625246040060000600
01100000004750c47518475004750a475004750a4750c475004750a4750c475004750a4750c4751147513475004750c4750a475004750a475004750a4750c475004750c47516475004751647518475114750c475
01100000180721a0751b0721f0721e0751f0751e0721f075270752607724075200721f0751b0771a0751b07518072180621805218042180350000000000000000000000000000000000000000000000000000000
011000000c37518375243751f3751b3721a372193711b372183721837217371163511533114311133001830214302143021830218302003000030000300003000030000300003000030000300003000030000300
011000000c37300300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000000001e0701f070220702a020340103f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002b7602e7503a73033740377302e75033730337303372035710377103a710337103a7103c7103c7003f700007000070000700007000070000700007000070000700007000070000700007000070000700
00020000276501d65013650106500c6400e63022620116300b63004630026101b6100861003610076101260013600106000d60010600116000e6001160012600116000a600066000960003600026000260002600
000100002257524575275652455527555275552b54524525225352252527525275252b5252e515305152e515305052e505305052e5053050530505335052b5052e5052b5052e5052e5053350530505335052e505
000200002005325043160231002304013030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102000013571165731b5751d5711157313575165711b5731b575225711b573185751b5711f573245751b5711f57324565295611f563185611d555245532b5552b5412b5433053137535335333a5212b5252e513
000200002b071270711b07118071100710b0710607104071040610606103061040510305101041010310102101011040110000000000000000000000000000000000000000000000000000000000000000000000
010200002e17029170171731a171231631d16111143141610c1230a11107110001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
01040000185702257024570225701f5701d5701f5701d57018570165701857016570135701157013570115700c5700d570135701457018560195501f550205302453024520225202452022510245102251024500
__music__
01 01434144
00 02434144
00 01034244
02 02034244
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
00 41414144
00 41414144

