pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
--map and objects

actions={}
objects={}

loadmsg='loading map'

function rpin(n)
	return peek(0x5f80+n)
end

function wpin(n,i)
	poke(0x5f80+n,i)
end

m={
	id=0,
	w=0,
	h=0,
	data={}
}

m.set=function()
	--writes mapdata to memory
	local ct=0
	for y=0,m.h-1 do
		for x=0,m.w-1 do
			local s=m.data[ct+1]
			--set sprite
			mset(x,y,s)
			ct+=1
		end
	end
end

m.startload=function(id)
	--reset the map
	m.id=id
	m.data={}
	m.w=0
	m.h=0
	wpin(1,m.id)--id to request
	wpin(0,1)--make req
end

m.load=function()
	local q=rpin(0)
	if q==2 then
		loadmsg='getting map dimensions'
		--get map dimensions
		m.w=rpin(1)
		m.h=rpin(2)
		wpin(0,3)
	elseif q==4 then
		--load in map data
		loadmsg='loading map data'
		for i=1,16 do
			add(m.data,rpin(i))
		end
		if #m.data==m.w*m.h then
			--done, req p.xy
			wpin(0,5)
		else
			--get more
			wpin(0,3)
		end
	elseif q==6 then
		loadmsg='loading player xy'
		p.x=rpin(1)*8
		p.y=rpin(2)*8
		wpin(0,0)
		m.set()
		state=1--done
	end
end
-->8
--player

p={
 x=32,
 y=32,
 d=2, --direction nesw
 moving=false,
 btim=0, --btn timer
 bdwn=-1 --btn down
}

p.draw=function()
	spr(p.d+64,p.x,p.y)
end

p.step=function(x,y)
	local c=cocreate(function()
			p.moving=true
			for i=1,8 do
				p.x+=x
				p.y+=y
				yield()
			end
			p.moving=false
	end)
	add(actions, c)
end

p.btnp=function(k)
	--button hold mechanic
	if p.bdwn==k then
		if k==-1 then
			return false
		end
		p.btim+=1
		if p.btim<10 then
			return false
		else
			return true
		end
	else
		if p.bdwn==-1 then
			p.btim=0
		end
		p.bdwn=k
		return false
	end
end

p.solid=function(dx,dy)
	--check map if solid
	--cell xy rel to player
	local qx=p.x/8+dx
	local qy=p.y/8+dy
	local ms=mget(qx,qy)
	return fget(ms,0)
	--todo: extend for water
end

p.move=function()
	if p.moving then
		return
	end
	local press=-1
	local dx=0
	local dy=0
	if btn(0) then
		p.d=3
		press=0
		dx=-1
	elseif btn(1) then
		p.d=1
		press=1
		dx=1
	elseif btn(2) then
		p.d=0
		press=2
		dy=-1
	elseif btn(3) then
		p.d=2
		press=3
		dy=1
	end
	--look if tapped,
	--walk if held
	local dstep=p.btnp(press)
	if dstep then
		--check for solid
		local sld=p.solid(dx,dy)
		if not sld then
			p.step(dx,dy)
		end
	end

end
-->8
--camera

cam={
	x=0,
	y=0
}

cam.move=function()
	cam.x=p.x-56
	cam.y=p.y-56
	if cam.x<0 then
		cam.x=0
	end
	if cam.y<0 then
		cam.y=0
	end
	if cam.x>m.w*8-128 then
		cam.x=m.w*8-128
	end
	if cam.y>m.h*8-128 then
		cam.y=m.h*8-128
	end
	camera(cam.x,cam.y)
end

cam.draw=function()
	map(0,0,0,0)
	p.draw()
end

cam.sees=function(o)
	return o.x>cam.x and
		o.x<=cam.x+128 and
		o.y>cam.y and
		o.y<=cam.y+128
end
-->8
--main

state=0
--0=load map
--1=game

function _init()
	m.startload(0)
end

function _update()
	if state==0 then
		--load map
		m.load()
	elseif state == 1 then
		--game loop
		p.move()
 	for c in all(actions) do
 		if costatus(c) then
 			coresume(c)
 		else
 			del(actions, c)
 		end
 	end
 	cam.move()
	end
	
end

function _draw()
	cls()
 if state==0 then
 print(loadmsg,8,8)
 elseif state==1 then
 	cam.draw()
 end
end
__gfx__
0000000033333333fff6ffff5555555511111111f444444411111111000000000000000000000000000000000000000000000000000000000000000000000000
00000000333333336fffffff56555565111111114f44444f12222221000999000009990000099900000999000009900000099900000990000009990000099900
0070070033333333fffff6ff55555555111111114444444412222221000009000009090000090900000909000009090000090000000909000009000000090000
0007700033333333ff6ffff65555555511111111444444f412222221000009000009990000099900000999000009900000090000000909000009900000099000
0007700033333333ffffffff555555551111111144444f4f12222921000090000009090000000900000909000009090000090000000909000009000000090000
0070070033333333fffff6ff555555551111111144f4444412222421000090000009990000000900000909000009990000099900000999000009990000090000
0000000033333333ff6fffff56555565111111114f4f444412222221000000000000000000000000000000000000000000000000000000000000000000000000
00000000333333336fff6fff55555555111111114444444412222221000000000000000000000000000000000000000000000000000000000000000000000000
33333333fff6ffff5555555511111111f44444441111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
333333336fffffff56555565111111114f44444f1222222100099900000999000009990000099900000999000009900000099900000990000009990000099900
33333333fffff6ff5555555511111111444444441222222100090000000009000009090000090900000909000009090000090000000909000009000000090000
33333333ff6ffff65555555511111111444444f41222222100099900000009000009990000099900000999000009900000090000000909000009900000099000
33333333ffffffff555555551111111144444f4f1222292100090900000090000009090000000900000909000009090000090000000909000009000000090000
33333333fffff6ff555555551111111144f444441222242100099900000090000009990000000900000909000009990000099900000999000009990000090000
33333333ff6fffff56555565111111114f4f44441222222100000000000000000000000000000000000000000000000000000000000000000000000000000000
333333336fff6fff5555555511111111444444441222222100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666600006666000066660000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666600006661000016610000166600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00666600006666000066660000666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000660000006600000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000660000006600000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000660000006600000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00066000000660000006600000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0100000102010000000000000000000000000102010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01040000180501c0501f05024050280502b0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
