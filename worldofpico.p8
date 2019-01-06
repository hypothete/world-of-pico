pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
--map and objects

actions={}
objects={}
warps={}

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
	px=0,--player start
	py=0,
	data={}
}

m.set=function(cl)
	--writes mapdata to memory
	--if cl is true, clears map
	local ct=0
	for y=0,m.h-1 do
		for x=0,m.w-1 do
			if cl then
				mset(x,y,0)
			else
				local s=m.data[ct+1]
 			--set sprite
 			mset(x,y,s)
 			ct+=1
			end
		end
	end
end


m.startload=function(id,x,y)
	state=0
	--reset the map
	m.set(true)
	m.id=id
	m.data={}
	m.w=0
	m.h=0
	m.px=x
	m.py=y
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
		for i=1,64 do
			add(m.data,rpin(i))
		end
		if #m.data>=m.w*m.h then
			--done, req warps
			--clear warps first
			warps={}
			wpin(0,5)
		else
			--get more
			wpin(0,3)
		end
	elseif q==6 then
		loadmsg='loading warps'
		local w={}
		w.x=rpin(1)
		w.y=rpin(2)
		w.to=rpin(3)
		w.tx=rpin(4)
		w.ty=rpin(5)
		add(warps,w)
		wpin(0,5)--req more
	elseif q==7 then
		wpin(0,0)
		m.set(false)
		p.x=m.px*8
		p.y=m.py*8
		state=1--done
	end
end
-->8
--player

p={
 x=0,
 y=0,
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
			p.cwarps()
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
		if p.btim<8 then
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

p.cwarps=function()
	--check warps when entering
	--a cell
	local wx=p.x/8
	local wy=p.y/8
	for i=1,#warps do
		local w=warps[i]
		if w.x==wx and w.y==wy then
			m.startload(w.to,w.tx,w.ty)
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
	if m.w>=16 then
		if cam.x<0 then
 		cam.x=0
 	elseif cam.x>m.w*8-128 then
 		cam.x=m.w*8-128
 	end
	else
		cam.x=m.w*8/2-64
	end
	if m.h>=16 then
 	if cam.y<0 then
 		cam.y=0
 	elseif cam.y>m.h*8-128 then
 		cam.y=m.h*8-128
 	end
 else
 	cam.y=m.h*8/2-64
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
--world of pico
--by hypothete

--an experiment using the gpio pins

state=0
--0=load map
--1=game

function _init()
	--pink is transparent
	palt(14, true)
 palt(0, false)
	m.startload(0,7,11)
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
 camera(0,0)
 print(loadmsg,0,0)
 elseif state==1 then
 	cam.draw()
 end
end
__gfx__
00000000ff7ffff7fffffffdd0d0d0d0fdfdfdfd00000000ddddddddfffffffffffffffffffff0dddddfffff7777f777d77ddddd7ddddddddd7ffff77dddddd7
00000000fffffffffdddddd0d0d0d0d0fdfdfdfd0dddddd0d770d770ffffdffffdffffffffffff0dddffffff777fff77dffdddddddddddddd07f777fdddddddd
00700700fffff7fffdddddd0d0d0d0d0fdfdfdfd0dddddd0d700d700fdfdffdffdffdfddffffff0ddd0fffff77fffff7dffdddddddddddddd07f777fdddddddd
000770007fffffffd0000000d0d0d0d0fdfdfdfd0dddddd0d000d000ffddfdffd0ff0dffffffff0d0d0fffff7fffffffddddddfdddddddddd07f777fdd00000d
00077000ffffffffffffdfffd0d0d0d0fdfdfdfd0ddddfd0ddddddddfff0dff0dffddffffffffd00ddd0fffffffffff7ddddddddddddddddd07f777fd07dfd7d
00700700ffff7fffdddd0fddd0d0d0d0fdfdfdfd0dddd0d0d770d770ffffd0fdffddffffffffd0d0d0ddffff7fffff77000000000dddddddd07ffff000f070f0
00000000f7ffffffdddd0fddfdfdfdfdfdfdfdfd0dddddd0d700d700fffffdfdf0dfffffffff0f00000d0fff77fff77770fff70700000000007f000000000000
00000000ffffff7f00000d00fdfdfdfddddddddd0dddddd0d000d000fffffddd0ddffffffffffff0ff0dffff777f77777d7f77d77007777777ff7007707f7707
0000000070dddddd7fffddddfddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d00000ddfdddddd7fffdddd7fdddddd7dd0000dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ddddddddffddddddffddddddd000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddd70ffdddd70fffddd70d000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ddd0000ddddd7fdfdddd7fdfffdd7fdd000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dd70dddddd70ddddffffddddd0000dfd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ddd0d7fdddddd7fdddddfffffdddd00dfffd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ddddddddddddddddffffffddffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
eeeddeeeeeeeddeeeeeddeeeeeddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeddddeeeeedd00eee0000eee00ddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eddddddeeeddd0feedf00fdeef0dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eddddddeeeddd00eed0000dee00dddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eddddddeeeddddeeedd00ddeeeddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
0dddddd0eedd0d0e0dddddd0e0d0ddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eddddddeeeddddeeeddddddeeeddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eddddddeeeddddeeeddddddeeeddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
__gff__
0100010101000101010101000101010103010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01040000180501c0501f05024050280502b0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
