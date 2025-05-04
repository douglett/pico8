pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--main pico-8 functions
function _init()
	keyb:init()
	game.current="crossroads"
 game:look()
end

function _update()
 keyb:update()
 if #keyb.cmd>0 do
  game:action(keyb.cmd,keyb.tar)
  keyb.cmd=""
 end
end

function _draw()
	cls()
 scrl:show()
 print(keyb.buf..keyb:cursor(),
  0,#scrl.lines*6)
end

-->8
--helper functions
--talking shortcut
function say(str,col)
 scrl:push(str)
end

--split string on whitespace
function splitstr(str)
 local t=split(str," ")
 while del(t,"")!=nil do end
 return t
end

--join table>string using glue
function joinstr(tbl,glue)
 local s=""
 glu=glu!=nil and glu or ", "
 for k,v in ipairs(tbl) do
  if k>1 do s=s..glu end
  s=s..tostring(v)
 end
 return s
end

--true if table contains value
function contains(tbl,val)
 for k,v in pairs(tbl) do
  if v==val do return true end
 end
 return false
end

-->8
--keyboard text input
keyb={
 txt="",
 buf="",
 cmd="",
 tar="",
 
 init=function(self)
  poke(0x5f2d,1) --keyboard on
  poke(0x5f30,1) --capture ret
 end,
 
 cret=function(self)
  poke(0x5f30,1) --capture ret
 end,

 cursor=function(self)
  local blink=flr(t()*2)%2
  return blink>0 and "_" or " "
 end,
 
 update=function(self)
  if not stat(30) do return end
  local c=stat(31)
  self.cret()
  if c>=" " and c<="z" do
   self.buf=self.buf..c
  elseif c=="\b" do
   self.buf=sub(self.buf,1,#self.buf-1)
  elseif c=="\r" do
   self.txt=self.buf
   self.buf=""
   local t=splitstr(self.txt)
   self.cmd=t[1]!=nil and t[1] or ""
   self.tar=t[2]!=nil and t[2] or ""
  end
 end
}
-->8
--scroll text box
scrl={
 lines={},
 maxh=128/6-1,
 
 clear=function(self)
  self.lines={}
 end,
 
 push=function(self,line)
  add(self.lines,line)
  if #self.lines>self.maxh do
   del(self.lines,self.lines[1])
  end
 end,

 show=function(self)
  for i=1,#scrl.lines do
   print(scrl.lines[i],0,(i-1)*6)
  end
 end
}

-->8
--game
game={
 inv={},
 current="cave",

 action=function(self,cmd,tar)
  cmd=self:normalize(cmd)
  printh("["..cmd.."]  ["..tar.."]")
  local room=self[self.current]
  if room:action(cmd,tar)==nil do
  --default actions
  elseif cmd=="look" do
   self:look()
  elseif cmd=="inv" and #self.inv>0 do
   say("you have: "..joinstr(self.inv))
  elseif cmd=="inv" do
   say("your inventory is empty")
  else
   say("you tried to "..cmd..", but it failed")
  end
 end,

 normalize=function(self,cmd)
  if cmd=="l" do return "look"
  elseif cmd=="i" do return "inv"
  elseif cmd=="n" do return "north"
  elseif cmd=="s" do return "south"
  elseif cmd=="e" do return "east"
  elseif cmd=="w" do return "west"
  elseif cmd=="u" do return "up"
  elseif cmd=="d" do return "down"
  else return cmd
  end
 end,

 look=function(self)
  local room=self[self.current]
  for k,v in ipairs(room.desc) do
   say("\fa"..v.."\f7")
  end
  if #room.items>0 do
   say("you see: "..joinstr(room.items))
  end
 end,

 go=function(self,place,dir)
  if dir!=nil then
   say("you go "..dir)
  end
  self.current=place
  self:look()
 end,

 addinv=function(self,item)
  add(self.inv,item)
 end,

 rminv=function(self,item)
  del(self.inv,item)
 end,

 hasinv=function(self,item)
  for k,v in ipairs(self.inv) do
   if v==item do return true end
  end
  return false
 end
}

-->8
--rooms
room={
 desc={"you are in some kinda room"},
 items={},
 flags={},

 new=function(self,tbl)
  tbl=tbl or {}
  setmetatable(tbl,{
   __index=self
  })
  return tbl
 end,

 action=function(self)
  return false
 end
}

game.cave=room:new({
 desc={"you are in a smelly cave",
  "there is an door north"},
 items={"key"},
 flags={unlocked=false},

 action=function(self,cmd,tar)
  if cmd=="north" and self.flags.unlocked do
   game:go("meadow")
  elseif cmd=="north" do
   say("the door is locked")
  elseif cmd=="get" and tar=="key" do
   game:addinv("key")
   del(self.items,"key")
   say("you get the key")
  elseif ((cmd=="use" and tar=="key") or cmd=="unlock") and game:hasinv("key") do
   game:rminv("key") --use up key
   self.flags.unlocked=true
   say("you unlock the door")
  else
   return false
  end
 end
})

game.meadow=room:new({
 desc={"you are in a lovely meadow",
  "there is: cave south,",
  "bridge north"},
 items={"troll"},

 action=function(self,cmd,tar)
  if cmd=="south" do
   game:go("cave")
  elseif cmd=="talk" do
   say("'i am the mighty trololol!")
   say(" answer me this riddle:")
   say(" why did the cheese?'")
  elseif cmd=="cheese" or cmd=="because" or cmd=="what" or cmd=="what?" do
   say("'correct!'")
   say("the troll explodes")
   del(self.items,"troll")
  elseif cmd=="north" and contains(self.items,"troll") do
   say("a troll is blocking it.")
   say("you want me to fight? no way!")
  elseif cmd=="north" do
   game:go("crossroads")
  else
   return false
  end
 end
})

game.crossroads=room:new({
 desc={"you are at a crossroads",
  "there are exits everywhere!"},

 action=function(self,cmd)
  if cmd=="north" or cmd=="south" or cmd=="east" or cmd=="west" do
   say("you go "..cmd.."...")
  else
   return false
  end
 end
})

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
