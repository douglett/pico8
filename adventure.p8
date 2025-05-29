pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--todo
-- done!

--main pico-8 functions
function _init()
	keyb:init()
 game:go("cave")
 -- game:go("forestpath")
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
function say(...)
 local arg={...}
 for k,ln in ipairs(arg) do
  scrl:push(ln)
 end
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
   say("you failed to "..cmd)
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
  -- run entry condition
  local room=self[self.current]
  if room.entry!=nil do
   room:entry()
  end
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
--room class
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

-->8
--game rooms

--cave
game.cave=room:new({
 desc={"you are in a smelly cave",
  "there is an door north"},
 items={"key"},
 flags={unlocked=false},

 action=function(self,cmd,tar)
  if cmd=="north" and self.flags.unlocked do
   game:go("river")
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

--river
game.river=room:new({
 desc={"you are at a river bank",
  "there is: cave south,",
  "bridge north"},
 items={"troll"},

 action=function(self,cmd,tar)
  if cmd=="south" do
   game:go("cave")
  elseif cmd=="talk" do
   say("'i am the mighty trololol!",
    " answer me this riddle:",
    " what comes up but never comes",
    " down?'")
  elseif cmd=="age" or cmd=="spaceship" or cmd=="rocket" do
   say("'correct!'",
    "the troll explodes")
   del(self.items,"troll")
  elseif cmd=="north" and contains(self.items,"troll") do
   say("a troll is blocking it.",
    "you want me to fight? no way!")
  elseif cmd=="north" do
   game:go("forestpath")
  else
   return false
  end
 end
})

--forest-path
game.forestpath=room:new({
 desc={"you are on a forest path",
  "a path goes north, south"},
 items={"witch"},
 flags={tries=0,hint=3},

 action=function(self,cmd)
  if contains(self.items,"witch") do
   if cmd=="kiss" do
    say("you turn into a handsome pr...",
     "well a human. the witch melts!")
    del(self.items,"witch")
   else
    self.flags.tries=self.flags.tries+1
    say("you hop helplessly. ribbit!")
    if self.flags.tries%self.flags.hint==0 do
     say("how do you turn a frog into",
      " a prince again?")
    end
   end
  elseif cmd=="north" do
   game:go("logcabin")
  elseif cmd=="south" do
   game:go("river")
  else
   return false
  end
 end,

 entry=function(self,cmd)
  if contains(self.items,"witch") do
   say("you are turned into a frog!")
  end
 end
})

--log-cabin
game.logcabin=room:new({
 desc={"you are in a log cabin",
  "there is a door south"},
 items={"grandma"},

 action=function(self,cmd)
  if cmd=="south" do
   game:go("forestpath")
  elseif cmd=="talk" do
   say("'grandma, what big ??? you have'")
  elseif cmd=="ears" or cmd=="ear" do
   say("'grandma, what big ears'",
    "'all the better to hear you'")
  elseif cmd=="eyes" or cmd=="eye" do
   say("'grandma, what big eyes'",
    "'all the better to see you'")
  elseif cmd=="hands" or cmd=="hand" do
   say("'grandma, what big hands'",
    "'all the better to hug you'")
  elseif cmd=="teeth" or cmd=="tooth" do
   say("'grandma, what big teeth!'",
    "'all the better to eat you!!'",
    "oh no, it was really a wolf!",
    "he eats you! nomnomnom")
   game:go("belly")   
  else
   return false
  end
 end
})

--wolfs-belly
game.belly=room:new({
 desc={"you are in a wolfs belly!",
  "there are 'exits' up, down"},
 flags={sure=0},

 action=function(self,cmd)
  if cmd=="up" do
   say("his teeth are firmly closed")
  elseif cmd=="down" and self.flags.sure==0 do
   say("are we really going out that",
    "way?")
   self.flags.sure=1
  elseif cmd=="down" and self.flags.sure==1 do
   say("really? know what that will make",
    "you?")
   self.flags.sure=2
  elseif cmd=="down" and self.flags.sure==2 do
   say("ok fine. you 'exit' the wolf.")
   game:go("crossroads")
  else
   return false
  end
 end
})

--crossroads
game.crossroads=room:new({
 desc={"you are at a crossroads",
  "there are exits everywhere!"},
 solution={"east","south","east","north"},
 flags={pos=1},

 action=function(self,cmd)
  if cmd=="north" or cmd=="south" or cmd=="east" or cmd=="west" do
   local hint=""
   local ok=self.solution[self.flags.pos]==cmd
   if ok and self.flags.pos==#self.solution do
    self.flags.pos=1
    game:go("meadow")
    return nil
   elseif ok do
    hint="warmer"
    self.flags.pos=self.flags.pos+1
   else
    self.flags.pos=1
   end
   say("you go "..cmd.."... "..hint)
  else
   return false
  end
 end
})

--meadow
game.meadow=room:new({
 desc={"you are at a lovely meadow",
  "there is an exit south."},
 items={"excalibur"},

 action=function(self,cmd,tar)
  if cmd=="south" do
   game:go("crossroads")
  elseif cmd=="get" and tar=="excalibur" do
   game:addinv("excalibur")
   del(self.items,"excalibur")
   say("you get excalibur!",
    "",
    "well done brave adventurer!",
    "you have won!")
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
