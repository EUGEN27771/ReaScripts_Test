--[[
   * ReaScript Name:Drums to MIDI(test version)
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.0
  ]]
--[[
   * Внимание, это тестовая версия!
   * В дальнейшем все будет переделываться.
]]
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Mcnt=0
function M(msg) 
 if Mcnt<500 then reaper.ShowConsoleMsg(tostring(msg).."\n"); Mcnt=Mcnt+1 end 
end
--------------------------------------------------------------------------------
--   Some Default Values   -----------------------------------------------------
--------------------------------------------------------------------------------
local srate = 44100     -- fix it, need get real srate from proj or source
local block_size = 1024*16--32 -- Block size
local n_chans = 2       -- num_chans(for track default,for take use source n_chans) 

--------------------------------------------------------------------------------
---   Simple Element Class   ---------------------------------------------------
--------------------------------------------------------------------------------
local Element = {}
function Element:new(x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val,norm_val2)
    local elm = {}
    elm.def_xywh = {x,y,w,h,fnt_sz} -- its default coord,used for Zoom etc
    elm.x, elm.y, elm.w, elm.h = x, y, w, h
    elm.r, elm.g, elm.b, elm.a = r, g, b, a
    elm.lbl, elm.fnt, elm.fnt_sz  = lbl, fnt, fnt_sz
    elm.norm_val = norm_val
    elm.norm_val2 = norm_val2
    ------
    setmetatable(elm, self)
    self.__index = self 
    return elm
end
--------------------------------------------------------------
--- Function for Child Classes(args = Child,Parent Class) ----
--------------------------------------------------------------
function extended(Child, Parent)
  setmetatable(Child,{__index = Parent}) 
end
--------------------------------------------------------------
---   Element Class Methods(Main Methods)   ------------------
--------------------------------------------------------------
function Element:update_xywh()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = math.ceil(self.def_xywh[1]* Z_w) , math.ceil(self.def_xywh[3]* Z_w) --upd x,w
  self.y, self.h = math.ceil(self.def_xywh[2]* Z_h) , math.ceil(self.def_xywh[4]* Z_h) --upd y,h
  if self.fnt_sz then --fix it!--
     self.fnt_sz = math.max(9,self.def_xywh[5]* (Z_w+Z_h)/2)
     self.fnt_sz = math.min(22,self.fnt_sz)
  end       
end
------------------------
function Element:pointIN(p_x, p_y)
  return p_x >= self.x and p_x <= self.x + self.w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Element:mouseIN()
  return gfx.mouse_cap&1==0 and self:pointIN(gfx.mouse_x,gfx.mouse_y)
end
------------------------
function Element:mouseDown()
  return gfx.mouse_cap&1==1 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseUp() -- its actual for sliders and knobs only!
  return gfx.mouse_cap&1==0 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseClick()
  return gfx.mouse_cap&1==0 and last_mouse_cap&1==1 and
  self:pointIN(gfx.mouse_x,gfx.mouse_y) and self:pointIN(mouse_ox,mouse_oy)         
end
------------------
function Element:mouseR_Down()
  return gfx.mouse_cap&2==2 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseM_Down()
  return gfx.mouse_cap&64==64 and self:pointIN(mouse_ox,mouse_oy)
end
------------------------
function Element:draw_frame()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  gfx.rect(x, y, w, h, 0)               --frame1
  gfx.roundrect(x, y, w-1, h-1, 3, true)--frame2         
end
----------------------------------------------------------------------------------------------------
---   Create Element Child Classes(Button,Slider,Knob)   -------------------------------------------
----------------------------------------------------------------------------------------------------
local Button, Slider, CheckBox, Frame = {},{},{},{}
  extended(Button,   Element)
  extended(Slider,   Element)
  extended(CheckBox, Element)
  extended(Frame,    Element)
--- Create Slider Child Classes(V_Slider,H_Slider) ----
local H_Slider, V_Slider = {},{}
  extended(H_Slider, Slider)
  extended(V_Slider, Slider)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Button Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Button:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Draw btn lbl(text) --
      gfx.set(0.7, 0.8, 0.4, 1)--set label color
      gfx.setfont(1, fnt, fnt_sz);--set label fnt
        local lbl_w, lbl_h = gfx.measurestr(self.lbl)
        gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
        gfx.drawstr(self.lbl)
end
---------------------
function Button:draw()
    self:update_xywh()--Update xywh(if wind changed)
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    -- Get L_mouse state -----
          --in element--
          if self:mouseIN() then a=a+0.1 end
          --in elm L_down--
          if self:mouseDown() then a=a+0.2 end
          --in elm L_up(released and was previously pressed)--
          if self:mouseClick() and self.onClick then self.onClick() end
    -- Draw btn(body,frame) --
    gfx.set(r,g,b,a)--set btn color
    gfx.rect(x,y,w,h,true)--body
    self:draw_frame()
    ------------------------
    self:draw_lbl()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Slider Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function H_Slider:set_norm_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local VAL,K = 0,10 --val=temp value;k=koof(when Ctrl pressed)
    if Ctrl then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    self.norm_val=VAL
end
function V_Slider:set_norm_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local VAL,K = 0,10 --val=temp value;k=koof(when Ctrl pressed)
    if Ctrl then VAL = self.norm_val + ((last_y-gfx.mouse_y)/(h*K))
       else VAL = (h-(gfx.mouse_y-y))/h end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    self.norm_val=VAL
end
----------------
function H_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true)--Hor Slider body
end
function V_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = h * self.norm_val
    gfx.rect(x,y+h-val, w, val, true) --Vert Slider body
end
----------------
function H_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl)--draw Slider label
end
function V_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+h-lbl_h-5
    gfx.drawstr(self.lbl)--draw Slider label
end
----------------
function H_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
end
function V_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+(w-val_w)/2; gfx.y = y+5
    gfx.drawstr(val)--draw Slider Value
end

---------------------
function Slider:draw()
    self:update_xywh()--Update xywh(if wind changed)
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    ---Get L_mouse state--
          --in element-----
          if self:mouseIN() then a=a+0.1 end
          --in elm L_down--
          if self:mouseDown() then a=a+0.2 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end
    --Draw (body,frame)--
    gfx.set(r,g,b,a)--set color
    self:draw_body()--body
    self:draw_frame()--frame
    ------------------------
    --Draw label,value--
    gfx.set(0.7, 0.8, 0.4, 1)--set labels color
    gfx.setfont(1, fnt, fnt_sz);--set labels fnt
    self:draw_lbl()
    self:draw_val()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   CheckBox Class Methods   -------------------------------------------------
--------------------------------------------------------------------------------
function CheckBox:set_norm_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val      -- current value,check
    local menu_tb = self.norm_val2 -- checkbox table
    local menu_str = ""
       for i=1, #menu_tb,1 do
         if i~=val then menu_str = menu_str..menu_tb[i].."|"
                   else menu_str = menu_str.."!"..menu_tb[i].."|" -- add check
         end
       end
    gfx.x = self.x; gfx.y = self.y + self.h
    local new_val = gfx.showmenu(menu_str)        -- show checkbox menu
    if new_val>0 then self.norm_val = new_val end -- change check(!)
end
--------
function CheckBox:draw_body()
    gfx.rect(self.x,self.y,self.w,self.h, true) -- draw checkbox body
end
--------
function CheckBox:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x-lbl_w-5; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl) -- draw checkbox label
end
--------
function CheckBox:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val2[self.norm_val]
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+5; gfx.y = y+(h-val_h)/2
    gfx.drawstr(val) -- draw checkbox val
end
------------------------
function CheckBox:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.1 end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.2 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() then self:set_norm_val()
             if self:mouseClick() and self.onClick then self.onClick() end
          end
    -- Draw ch_box body, frame -
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame()   -- frame
    -- Draw label --------------
    gfx.set(0.7, 0.9, 0.4, 1)   -- set label,val color
    gfx.setfont(1, fnt, fnt_sz) -- set label,val fnt
    self:draw_lbl()             -- draw lbl
    self:draw_val()             -- draw val
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Frame Class Methods  -----------------------------------------------------
--------------------------------------------------------------------------------
function Frame:draw()
   self:update_xywh()--Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   if self:mouseIN() then a=a+0.1 end
   gfx.set(r,g,b,a)--set color
   self:draw_frame()
end
----------------------------------------------------------------------------------------------------
---  Create Objects(Wave,Filter,Gate) --------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
local Wave = Element:new(10,10,1024,350)
------------------
local Filter_B = {}
local Gate_Gl  = {}
------------------
---------------------------------------------------------------
---  Create Frames   ------------------------------------------
---------------------------------------------------------------
local Fltr_Frame = Frame:new(10, 370,200,110,  0,0.5,0,0.2 )
local Gate_Frame = Frame:new(240,370,310,110,  0,0.5,0,0.2 )
local Mode_Frame = Frame:new(580,370,454,110,  0,0.5,0,0.2 )
local Frame_TB = {Fltr_Frame, Gate_Frame, Mode_Frame}

----------------------------------------------------------------------------------------------------
---  Create Objects(controls) and override some methods   ------------------------------------------
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--- Filter Sliders -----------------------------------------------------------------
------------------------------------------------------------------------------------
local HP_Freq = H_Slider:new(20,410,180,18, 0.3,0.5,0.7,0.3, "HP","Arial",15, 0.885 )
  function HP_Freq:draw_val()
    local sx = 16+(self.norm_val*100)*1.20103
    self.form_val = math.floor(math.exp(sx*math.log(1.059))*8.17742) -- form val(formula AppleFilter)
    -------------
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.form_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end
-------------
local LP_Freq = H_Slider:new(20,430,180,18, 0.3,0.5,0.7,0.3, "LP","Arial",15, 1 )
  function LP_Freq:draw_val()
    local sx = 16+(self.norm_val*100)*1.20103                   
    self.form_val = math.floor(math.exp(sx*math.log(1.059))*8.17742) -- form val(formula AppleFilter)
    -------------
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.form_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end
  
----------------
local Fltr_Gain = H_Slider:new(20,450,180,20,  0.3,0.5,0.5,0.3, "Filter Gain","Arial",15, 0 )
  function Fltr_Gain:draw_val()
    self.form_val = self.norm_val*24  -- form value
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.form_val).." dB"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end

----------------
  function Fltr_Sldrs_onUp() 
     reaper.Undo_BeginBlock() 
       if Wave.AA then
           Wave:DRAW()
           if Wave.State then
              Gate_Gl:Apply_toFiltered()
           end
       end
     reaper.Undo_EndBlock("~Change Filter~", -1) 
  end

HP_Freq.onUp = Fltr_Sldrs_onUp
LP_Freq.onUp = Fltr_Sldrs_onUp
Fltr_Gain.onUp = Fltr_Sldrs_onUp

------------------------------------------------------------------------------------
--- Gate Sliders -------------------------------------------------------------------
------------------------------------------------------------------------------------
-- ВСЕ Слайдеры нужно переименовать и расположить по-нормальному, путаница сейчас дикая получилась!!!

local Gate_Thresh = H_Slider:new(250,380,290,20, 0.3,0.5,0.7,0.3, "Threshold","Arial",15, 1 )
  function Gate_Thresh:draw_val()
    self.form_val = (self.norm_val-1)*57-3
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.form_val).." dB"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
    Gate_Thresh:draw_val_line() -- Draw GATE LINES !!!
  end
  ---------- 
  function Gate_Thresh:draw_val_line()
    if Wave.State then gfx.set(0.8,0.3,0,1)
      local val_line1 = Wave.y + Wave.h/2 - (10^(self.form_val/20))*Wave.Y_scale
      local val_line2 = Wave.y + Wave.h/2 + (10^(self.form_val/20))*Wave.Y_scale
      gfx.line(Wave.x, val_line1, Wave.x+Wave.w-1, val_line1 )
      gfx.line(Wave.x, val_line2, Wave.x+Wave.w-1, val_line2 )
    end
  end
----------------
local Gate_minDiff = H_Slider:new(250,405,290,18, 0.3,0.5,0.7,0.3, "Sensetive","Arial",15, 0.2 )
  function Gate_minDiff:draw_val()
    self.form_val = 2+(self.norm_val)*15
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.form_val).." dB"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end
---------------- ! It detect velo time !
local Gate_DetVelo = H_Slider:new(650,410,140,18, 0.3,0.5,0.5,0.3, "Detect Velo","Arial",15, 0.1 ) -- 250,405,220,18
  function Gate_DetVelo:draw_val()
    self.form_val  = 3+ self.norm_val * 7                   -- form_val
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.form_val).." ms"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end

----------------
local Gate_Retrig = H_Slider:new(250,425,290,18, 0.3,0.5,0.5,0.3, "Retrig","Arial",15, 0 )
  function Gate_Retrig:draw_val()
    self.form_val  = 20+ self.norm_val * 80                 -- form_val
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.form_val).." ms"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end

-- unused --------------
--local Gate_Pre  = H_Slider:new(250,450,100,20, 0.5,0.3,0.2,0.3, "Pre","Arial",14, 0 )
----------------
--local Gate_Post = H_Slider:new(370,450,100,20, 0.3,0.5,0.2,0.3, "Post","Arial",14, 0.10 )
----------------  
 
  ----------------------------------------
  -- onUp function for Gate sliders ---
  ----------------------------------------
  function Gate_Sldrs_onUp() 
      if Wave.State then
        reaper.Undo_BeginBlock() 
          Gate_Gl:Apply_toFiltered()
          --Wave:Create_Envelope()
        reaper.Undo_EndBlock("~Change Gete~", -1)
      end 
  end
  Gate_Thresh.onUp   = Gate_Sldrs_onUp
  Gate_minDiff.onUp  = Gate_Sldrs_onUp
  Gate_DetVelo.onUp  = Gate_Sldrs_onUp
  Gate_Retrig.onUp   = Gate_Sldrs_onUp
  --Gate_Pre.onUp     = Gate_Sldrs_onUp
  --Gate_Post.onUp    = Gate_Sldrs_onUp

-----------------------------------
--- Slider_TB ---------------------
-----------------------------------
local Slider_TB = {HP_Freq,LP_Freq,Fltr_Gain, Gate_Thresh, Gate_minDiff, Gate_DetVelo,Gate_Retrig }

------------------------------------------------------------------------------------
--- Buttons ------------------------------------------------------------------------
------------------------------------------------------------------------------------
local Detect = Button:new(20,380,180,25, 0.4,0.12,0.12,0.3, "Get Selection",    "Arial",15 )
  Detect.onClick = 
  function() 
      if Wave:Create_Track_Accessor() then
         reaper.Undo_BeginBlock() 
           Wave:DRAW()
           if Wave.State then
              Gate_Gl:Apply_toFiltered()
           end
         reaper.Undo_EndBlock("~Detect~", -1) 
      end 
  end
----------------------------------- 
local Create_MIDI = Button:new(590,380,200,25, 0.4,0.12,0.12,0.3, "Create_MIDI",    "Arial",15 )
  Create_MIDI.onClick = 
  function()
     if Wave.State then 
            reaper.Undo_BeginBlock() 
              Wave:Create_MIDI()
            reaper.Undo_EndBlock("~Create_MIDI~", -1) 
         end 
     end 
-----------------------------------
--- Button_TB ---------------------
-----------------------------------
local Button_TB = {Detect,Create_MIDI}

------------------------------------------------------------------------------------
--- CheckBoxes ---------------------------------------------------------------------
------------------------------------------------------------------------------------
    -- x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val = check, norm_val2 = checkbox table --
local VeloMode = CheckBox:new(590,410,50,18,   0.3,0.5,0.5,0.3, "","Arial",15,  1,
                              {"RMS","Peak"} )

VeloMode.onClick = Gate_Sldrs_onUp
--------------
local DrawMode = CheckBox:new(950,380,70,18,   0.3,0.5,0.5,0.3, "Draw: ","Arial",15,  3,
                              {"Very Slow","Slow", "Medium1","Medium2", "Fast","Very Fast"} )

DrawMode.onClick = Fltr_Sldrs_onUp
-----------------------------------
--- CheckBox_TB -------------------
-----------------------------------
local CheckBox_TB = {VeloMode,DrawMode}

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Gate  --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:Apply_toFiltered() -- Transient Gate variant
    -- Это переделывать - !!! Тут все нужно упрощать до предела !!!
    -- Это только сама идея, но оно уже работает. Вариант с  транзиент-гейтом !!!
    ---------------------------------------------------
    local start_time = reaper.time_precise()--time test
    ---------------------------------------------------
    ----------------------------
    -- local func work faster --
    ----------------------------
    local sqrt = math.sqrt  
    local abs  = math.abs
    local min  = math.min
    local max  = math.max
      -----------------------------------------------------
      -- GetSet Gate Vaules -------------------------------
      -----------------------------------------------------
      ------------------------------------- 
      -- Gate state tables ----------------
      self.State_Points = {}               -- State_Points table 
      self.State_Lines  = {}               -- State_Lines  table
      -------------------------------------
      ------------------------------------------------
      -- GetSet parameters ---------------------------
      ------------------------------------------------
      -- attack, release Thresholds -----
      local gain_fltr  = 10^(Fltr_Gain.form_val/20)     -- Gain from Fltr_Gain slider(need for gate Threshs)
      local Thresh  = 10^(Gate_Thresh.form_val/20) /gain_fltr * block_size   -- attThresh * fft scale(block_size)
      minDiff = 10^(Gate_minDiff.form_val/20)
      -- attack, release Time -----------
      -- Эти параметры нужно либо выносить в доп. настройки, либо подбирать тщательнее...
      local attTime1  = 0.001                            -- Env1 attack(sec)
      local attTime2  = 0.007                            -- Env2 attack(sec)
      local relTime1  = 0.010                            -- Env1 release(sec)
      local relTime2  = 0.015                            -- Env2 release(sec)
      -- -- -- -- -- -- -- -- -- -- -- -- 
      local retrigSmpls  = Gate_Retrig.form_val/1000*srate      -- Retrig slider to samples
      local retrig       = retrigSmpls+1                        -- Retrig counter
      local det_velo_sec = Gate_DetVelo.form_val/1000
      local detVelo      = math.floor(det_velo_sec*srate + 1)   -- samples -- detVelo slider(time to samples) 
      -----------------------------------
      -- Init counters etc --------------
      -----------------------------------
      rms_val, maxRMS = 0, 0          -- init rms_val, RMS, maxRMS
      peak_val, maxPeak = 0, 0        -- peak_val, maxPeak
      -------------------
      local smpl_cnt  = 0                   -- gate sample counter
      local st_cnt    = 1                   -- gate State_Points counter 
      -------------------
      local sel_start = Wave.sel_start - det_velo_sec -- sel_start(and compensation  det_velo_sec)
      local last_trig = -retrigSmpls*2
      -------
      local envOut1 = Wave.out_buf[1]                      -- Peak envelope1 follower
      local envOut2 = envOut1                              -- Peak envelope2 follower
      local Trig,GetSmpls = false, false              -- trigger output 
      -- Compute sample frequency related coeffs
      local ga1 = math.exp(-1/(srate*attTime1))   -- attack coeff
      local gr1 = math.exp(-1/(srate*relTime1))   -- release coeff
      local ga2 = math.exp(-1/(srate*attTime2))   -- attack coeff
      local gr2 = math.exp(-1/(srate*relTime2))   -- release coeff
      -- if not XXX then XXX = 0 else XXX = XXX + 1 end
       -----------------------------------------------------------------
       -- Gate main for ------------------------------------------------
       -----------------------------------------------------------------
       for i = 1, Wave.Samples*2, 2 do
           local envIn = abs(Wave.out_buf[i]) -- abs smpl val(abs envelope)
           --------------------------------------
           -- Envelope1(fast) --------------------------
           if envOut1 < envIn then 
                   envOut1 = envIn + ga1 * (envOut1 - envIn) --!!! 
              else envOut1 = envIn + gr1 * (envOut1 - envIn)
           end
           -- Envelope2(slow) --------------------------
            if envOut2 < envIn then 
                    envOut2 = envIn + ga2 * (envOut2 - envIn) --!!! 
               else envOut2 = envIn + gr2 * (envOut2 - envIn)
            end
           
           --------------------------------------
           -- Trigger ---------------------------  
           if retrig>retrigSmpls then
              if envOut1>Thresh and (envOut1/envOut2) > minDiff then
                 Trig = true; GetSmpls = true; retrig = 0; rms_val,peak_val = 0, 0 -- reset
              end
            else envOut2 = envOut1; -- !!!          
           end
           --------------------------------------
           -- Get velo --------------------------
           if GetSmpls then
              if smpl_cnt<=detVelo then 
                 rms_val  = rms_val + Wave.out_buf[i] * Wave.out_buf[i]
                 peak_val = max(peak_val, Wave.out_buf[i])
                 smpl_cnt = smpl_cnt+1 
                 ---------------------------     
                 else 
                      local RMS = sqrt(rms_val/detVelo)
                      local Peak = peak_val
                      -- -- -- -- -- --
                      GetSmpls = false
                      smpl_cnt = 0
                      rms_val = 0    
                      --- open point -----
                      self.State_Points[st_cnt] = true                             -- State
                      self.State_Points[st_cnt+1] = sel_start + ((i-1)/2)/srate    -- Time point(sec)
                      if VeloMode.norm_val==1 then
                             self.State_Points[st_cnt+2] = RMS                     -- RMS var
                        else self.State_Points[st_cnt+2] = Peak                    -- Peak var
                      end
                      --- open line ------
                      self.State_Lines[st_cnt] = true                                  -- State
                      self.State_Lines[st_cnt+1] = ((i-1)/2 - detVelo) * Wave.X_scale  -- Time point in gfx
                      if VeloMode.norm_val ==1 then
                             self.State_Lines[st_cnt+2] = RMS                      -- RMS var
                        else self.State_Lines[st_cnt+2] = Peak                     -- Peak var
                      end
                      --------
                      maxRMS = max(maxRMS, RMS) -- save maxRMS for scaling
                      maxPeak = max(maxPeak, Peak)                
                      --------
                      st_cnt = st_cnt+3
                      -------------
               end
           end       
           --------------------------------------     
           retrig = retrig+1;
       end
    --------------------------
    self.maxRMS  = maxRMS   -- store maxRMS for scaling MIDI velo
    self.maxPeak = maxPeak  -- store maxPeak for scaling MIDI velo  
    -----------------------------
    --reaper.ShowConsoleMsg("Gate time = " .. reaper.time_precise()-start_time .. '\n')--time test
end

----------------------------------------------------------------------
---  Gate - Draw Gate Lines  -----------------------------------------
----------------------------------------------------------------------

function Gate_Gl:draw_Lines() -- simple variant without close lines
  if not self.State_Lines then return end -- return if no lines
    -- Velocity scale --
    local scale
    if VeloMode.norm_val == 1 then 
            scale = 1/Gate_Gl.maxRMS  -- velocity scale RMS
       else scale = 1/Gate_Gl.maxPeak   -- velocity scale Peak
    end
    -- line color ------
    gfx.set(1, 1, 0) -- gate line, point color
    ----------------------------
    for i=1, #self.State_Lines, 3 do
       -- draw line, velo ------ 
       local line_x   = Wave.x + (self.State_Lines[i+1] - Wave.Pos) * Wave.Zoom*Z_w    -- line x coord
       local velo_y   = (Wave.y + Wave.h) -  Wave.h*self.State_Lines[i+2] *scale       -- velo y coord    
          ----------------------
          gfx.a = 0.6     -- gate line a
          gfx.line(line_x, Wave.y, line_x, Wave.y + Wave.h-1 )
          ----------------------
          gfx.a = 0.8     -- velo point a
          gfx.circle(line_x, velo_y, 2,1,1) -- Velocity point
    end
end


----------------------------------------------------------------------------------
--[[------------------------------------------------------------------------------
function Gate_Gl:Apply_toFiltered() -- Simple Gate variant
    -- Это переделывать - !!! Тут все нужно упрощать до предела !!!
    -- Это только сама идея, но оно уже работает. Вариант с обычным гейтом !!!
    ---------------------------------------------------
    local start_time = reaper.time_precise()--time test
    ---------------------------------------------------
    ----------------------------
    -- local func work faster --
    ----------------------------
    local sqrt = math.sqrt  
    local abs  = math.abs
    local min  = math.min
    local max  = math.max
      -----------------------------------------------------
      -- GetSet Gate Vaules -------------------------------
      -----------------------------------------------------
      ------------------------------------- 
      -- Gate state tables ----------------
      self.State_Points = {}               -- State_Points table 
      self.State_Lines  = {}               -- State_Lines  table
      -------------------------------------
      -------------------------------------
      -- attack, release Thresholds -------
      local gain_fltr  = 10^(Fltr_Gain.form_val/20)     -- Gain from Fltr_Gain slider(need for gate Threshs)
      local attThresh  = 10^(Gate_attThresh.form_val/20) /gain_fltr * block_size   -- attThresh * fft scale(block_size)
      local relThresh  = 10^(Gate_relThresh.form_val/20) /gain_fltr * block_size   -- relThresh * fft scale(block_size)
      -- attack, release Time -----------
      local attTime  = 0.0001                           -- Need attTime slider??!!!
      local relTime  = 0.015                            -- Need relTime slider??!!!
      -- -- -- -- -- -- -- -- -- -- -- -- 
      local retrigSmpls = Gate_Retrig.form_val/1000*srate      -- Retrig slider to samples
      local retrig      = retrigSmpls+1                        -- Retrig counter
      local det_velo_sec = Gate_DetVelo.form_val/1000
      local detVelo     = math.floor(det_velo_sec*srate + 1)  -- samples -- detVelo slider(time to samples) 
      -----------------------------------
      -- Init counters etc --------------
      local rms_val, maxRMS = 0, 0          -- init rms_val, RMS, maxRMS 
      -------------------
      local smpl_cnt  = 0                   -- gate sample counter
      local st_cnt    = 1                   -- gate State_Points counter 
      -------------------
      local sel_start = Wave.sel_start - det_velo_sec -- sel_start(and compensation  det_velo_sec)
      local last_trig = -retrigSmpls*2
      local envOut = 0                                -- Peak envelope follower
      local Trig,GetSmpls = false, false              -- trigger output 
      -- Compute sample frequency related coeffs
      local ga = math.exp(-1/(srate*attTime))   -- attack coeff
      local gr = math.exp(-1/(srate*relTime))   -- release coeff
       
       -----------------------------------------------------------------
       -- Gate main for ------------------------------------------------
       -----------------------------------------------------------------
       for i = 1, Wave.Samples*2, 2 do
           local envIn = abs(Wave.out_buf[i]) -- abs smpl val(abs envelope)
           --------------------------------------
           -- Envelope --------------------------
           if envOut < envIn then envOut = envIn -- If need attTime>0 -> envOut = envIn + ga * (envOut - envIn) !!! 
              else envOut = envIn + gr * (envOut - envIn)
           end
           
           --------------------------------------
           -- Trigger ---------------------------  
           if (not Trig) and retrig>retrigSmpls then
              -- open ------
              if envOut > attThresh then
                 Trig = true; GetSmpls = true; retrig = 0; -- reset
              end
              -- close -----
            else if envOut < relThresh then 
                    Trig = false;
                 end            
           end
           --------------------------------------
           -- Get velo --------------------------
           if GetSmpls then
              if smpl_cnt<=detVelo then 
                 rms_val  = rms_val + Wave.out_buf[i] * Wave.out_buf[i]
                 smpl_cnt = smpl_cnt+1 
                 ---------------------------     
                 else 
                      local RMS = sqrt(rms_val/detVelo)
                      GetSmpls = false
                      smpl_cnt = 0
                      rms_val = 0    
                      --- open point -----
                      self.State_Points[st_cnt] = true                                -- State
                      self.State_Points[st_cnt+1] = sel_start + ((i-1)/2)/srate       -- Time point sec
                      self.State_Points[st_cnt+2] = RMS
                      --- open line ------
                      self.State_Lines[st_cnt] = true                                  -- State
                      self.State_Lines[st_cnt+1] = ((i-1)/2 - detVelo) * Wave.X_scale  -- Time point in gfx
                      self.State_Lines[st_cnt+2] = RMS 
                      --------
                      maxRMS = max(maxRMS, RMS) -- save maxRMS for scaling                
                      --------
                      st_cnt = st_cnt+3
                      -------------   
               end
           end       
           --------------------------------------     
           retrig = retrig+1;
       end
    --------------------------
    self.maxRMS = maxRMS  -- store maxRMS for scaling MIDI velo 
    -----------------------------
    --reaper.ShowConsoleMsg("Gate time = " .. reaper.time_precise()-start_time .. '\n')--time test
end--]]

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
---   Wave   -----------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
---   MIDI  --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Create_MIDI()
    local tracknum = reaper.GetMediaTrackInfo_Value(self.track, "IP_TRACKNUMBER")
    reaper.InsertTrackAtIndex(tracknum, false)
    local midi_track = reaper.GetTrack(0, tracknum)
    reaper.TrackList_AdjustWindows(0)
    local sel_start,sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
    local item = reaper.CreateNewMIDIItemInProj(midi_track, self.sel_start, self.sel_start+self.sel_len, false)
    local take = reaper.GetActiveTake(item)
    -----------
    local sel, mute, chan, pitch = 1, 0, 0, 36
    local startppqpos, endppqpos, vel
    local len = 60
    -- Velocity scale --
    local scale
    if VeloMode.norm_val == 1 then 
           scale = 1/Gate_Gl.maxRMS  -- velocity scale RMS
      else scale = 1/Gate_Gl.maxPeak   -- velocity scale Peak
    end
    -----------
    for i=1, #Gate_Gl.State_Points, 3 do
        startppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, Gate_Gl.State_Points[i+1] )
        endppqpos   = startppqpos + len
        vel = math.floor(Gate_Gl.State_Points[i+2] *scale*127)
        reaper.MIDI_InsertNote(take, sel, mute, startppqpos, endppqpos, chan, pitch, vel, true)
    end
    -----------
    reaper.MIDI_Sort(take)
end


--------------------------------------------------------------------------------
---  Accessor  -----------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Create_Track_Accessor() 
 self.track = reaper.GetSelectedTrack(0,0)
    if self.track then self.AA = reaper.CreateTrackAudioAccessor(self.track) 
         self.AA_Hash = reaper.GetAudioAccessorHash(self.AA, "")
         self.AA_start = reaper.GetAudioAccessorStartTime(self.AA)
         self.AA_end   = reaper.GetAudioAccessorEndTime(self.AA)
         self.buffer   = reaper.new_array(block_size*2)--L,R main buffer
         self.buffer.clear()
         return true
    end
end
--------
function Wave:Destroy_Track_Accessor()
 if self.AA then reaper.DestroyAudioAccessor(self.AA) 
    self.buffer.clear() --self.buffer_l.clear(); self.buffer_r.clear()
 end
end
--------
function Wave:Verify_Track_Accessor()
   if self.AA and reaper.ValidatePtr2(0, self.track, "MediaTrack*") then
       local AA = reaper.CreateTrackAudioAccessor(self.track)
       if self.AA_Hash == reaper.GetAudioAccessorHash(AA, "") then
          reaper.DestroyAudioAccessor(AA) -- destroy temporary AA
          return true 
       end
   end 
end
--------
function Wave:Get_Selection_SL()
 local curs_pos = reaper.GetCursorPositionEx(0)
 local sel_start,sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
 local sel_len = sel_end - sel_start
    if sel_len>0 then 
            self.sel_start, self.sel_len = sel_start, sel_len         --selection start and lenght
       else self.sel_start, self.sel_len = curs_pos, block_size/srate --cur_pos and one block lenght 
    end
end


----------------------------------------------------------------------------------------------------
---  Wave - Draw(Set_coord > DRAW(inc. draw_block) = full update gfx buffer  -----------------------
----------------------------------------------------------------------------------------------------
------------------------------------------------------------
-- Filter_FFT ----------------------------------------------
------------------------------------------------------------  
function Wave:Filter_FFT(lowband, hiband, out_scale) -- Filter
  local buf = self.buffer
    ----------------------------------------
    -- Filter ------------------------------
    ----------------------------------------
    buf.fft(block_size,true)       -- FFT
    --------------------------------
    --lowband = 0; hiband = 16384 -- ITS FOR DRAW TEST ONLY(Del it !!!)
    -- Clear lowband bins --
    buf.clear(0, 1, lowband)                      -- clear start part
    buf.clear(0,  block_size*2 - lowband + 1 )    -- clear end part
    -- Clear hiband bins  --
    buf.clear(0, hiband+1, (block_size-hiband)*2 ) -- clear mid part
       --------------------------
       -- Scale other bins ------
       --[[-- Масштабирование не выполняется! ------------------------------
       ------ Сигнал на выходе в  block_size раз выше по уровню! ----------- 
       ------ Масштабирование просто нужно учесть в дальнейшей обработке! --
       --------------------------------]]
    buf.ifft(block_size,true)      -- iFFT
end  

--------------------------------------------------------------------------------
-- Wave:Set_Coord --------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Set_Coord()
  -- gfx buffer always used def coord! --
  local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4] 
  gfx.dest = 1            -- dest buffer1
  gfx.a    = 1            -- for buf    
   gfx.setimgdim(1,-1,-1) -- clear buf1(wave)
   gfx.setimgdim(1,w,h)   -- set w,h
   -------------
   Wave.Zoom = Wave.Zoom or 1  -- init Zoom 
   Wave.Pos  = Wave.Pos  or 0  -- init src position
   -------------
   Wave:Get_Selection_SL()
   -------------
    self.sel_len = math.min(self.sel_len,47)  -- limit lenght(deliberate restriction) 
    self.Samples    = math.floor(self.sel_len*srate)      -- Lenght to samples
    self.Blocks     = math.ceil(self.Samples/block_size)  -- Lenght to sampleblocks
    -- pix_dens - Нужно выбрать оптимум!!!
    --self.pix_dens   = math.ceil(self.Samples/(1024*256)*4)*2   -- Pixel density for wave drawing
    --self.pix_dens   = math.ceil(self.Samples/(1024*1024*2))   -- Pixel density for test speed wave drawing 1
    self.pix_dens   = math.ceil(self.Samples/(1024*1024*2))*2     -- Pixel density for test speed wave drawing 2
    self.pix_dens   = math.ceil(self.Samples/(1024*1024*2))*2*DrawMode.norm_val -- Pixel density for test speed wave drawing 3(from DrawMode)
    self.X, self.Y  = x, h/2                            -- waveform position(X,Y axis)
    self.X_scale    = w/self.Samples                    -- X_scale = w/lenght in samples
    self.Y_scale    = h/2                               -- Y_scale for waveform drawing
    -- Its not real Gain - only visual :) !!!
    self.Y_scaleFltr   = h/2/block_size *10^(Fltr_Gain.form_val/20)   -- from Fltr_Gain Sldr!-- Y_scale for filtered waveform drawing

end

--------------------------------------------------------------------------------
--- Draw Original --------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:draw_block(r,g,b,a) -- Mod Draw(for A_Blocks)
  -- Это все нужно оптимизировать и переделывать !!!
  -- local - Чуть быстрее, незначительно, но все же...
  local crsx = block_size/8                                  -- It must def in future
  local Xblock = block_size-crsx*2                           -- active part of full block
  local block_X = self.block_X
  local Xsc  = self.X_scale * (self.pix_dens/2) 
  local Ysc  = self.Y_scale
  local Y = self.Y
  local X = block_X -- start position
  ---------
  local setpixel = gfx.setpixel -- немного быстрее, совсем чуток 5-11%, по-разному - но закономерно
  ---------
  ---------
  local buf
  -- здесь тоже с таблицей работает чуть быстрее, чем с reaper.array(но на низкой плотности даже медленне)
  if self.pix_dens<=6 then buf = self.buffer.table() else buf = self.buffer end
  ---------   
  gfx.a = a
  for i = crsx+1, Xblock*2+crsx, self.pix_dens do 
     gfx.x = X                     -- set x coord
     gfx.y = Y - buf[i] *Ysc       -- set y coord
     setpixel(r,g,b)               -- setpixel
     X = X + Xsc                   -- to next smpl (Вычисление(по оси x) через сложение, чуть быстрее !!!)
  end
end
--------------------------------------------------------------------------------
--- Draw Filtered --------------------------------------------------------------
--------------------------------------------------------------------------------
--- Draw Filtered(Variant with full buffer) ------------------
function Wave:draw_Filtered(r,g,b,a) -- New Mod Draw
  -- local - Чуть быстрее, незначительно, но все же...
  local Xsc  = self.X_scale * (self.pix_dens/2) 
  local Ysc  = self.Y_scaleFltr
  local Y = self.Y
  ---------
  local setpixel = gfx.setpixel -- немного быстрее, совсем чуток 5-11%, по-разному - но закономерно
  ---------
  local X = 0 -- start position
  ---------
  gfx.a = a
  for i = 1, #self.out_buf, self.pix_dens do 
      gfx.x = X                          -- set x coord
      gfx.y = Y - self.out_buf[i] *Ysc   -- set y coord
      setpixel(r,g,b)                    -- setpixel
      X = X + Xsc                        -- to next smpl (Вычисление(по оси x) через сложение, чуть быстрее !!!)
  end
end

------------------------------------------------------------------------------------------------------------------------
-- Wave - MAIN DRAW Function(inc. filtering) ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function Wave:DRAW() -- New variant
 local start_time = reaper.time_precise()--time test
  ---------------------------------
  self:Set_Coord() -- set dest buf, coord etc
  ---------------------------------
  local crsx = block_size/8   -- one side crossX - use for discard some FFT artefacts(it non-native crossX!)
  local Xblock = block_size-crsx*2                               -- active part of full block
  self.A_Blocks  = math.ceil( self.Samples/Xblock )              -- sel_len to active sampleblocks 
  local out_buf = reaper.new_array(self.A_Blocks*Xblock*n_chans) -- max size array for out samples rnd to blocks:)
  out_buf.clear(0)                                               -- clear 
  self.block_start = self.sel_start - (crsx/srate)/n_chans       -- first block start(regard crsx)
    -------------------------------
    -- Filter values --------------
    -- Тут путаница с определениями - LP = HiFreq, HP = LowFreq - фигня
    -- Тоже нужно оптимизировать и переделывать !!!
    local Low_Freq, Hi_Freq =  HP_Freq.form_val, LP_Freq.form_val
    local bin_freq = srate/(block_size*2)          -- freq step 
    local lowband  = Low_Freq/bin_freq             -- low bin
    local hiband   = Hi_Freq/bin_freq              -- hi bin
    local Out_Gain  = 1                            -- it mast be user value
    local out_scale = 1/block_size * Out_Gain      -- scale output
    -- lowband, hiband to valid values(need even int) ------------
    lowband = math.floor(lowband/2)*2
    hiband  = math.ceil(hiband/2)*2  
   
  ------------------------------------------------
  for block=1, self.A_Blocks do reaper.GetAudioAccessorSamples(self.AA,srate,n_chans,self.block_start,block_size,self.buffer)
      -- Draw Original ---
      self.block_X = (block-1)* Xblock * self.X_scale  -- X-offs for draw each block
      self:draw_block(0.3,0.4,0.7,1)     -- draw original wave
      --------------------
      self:Filter_FFT(lowband, hiband, out_scale)      -- Filter(note: don't use out of range freq!)
      out_buf.copy(self.buffer, crsx+1, n_chans*Xblock, (block-1)* n_chans*Xblock + 1   ) -- copy block to main out buffer
      ---------------
      ---------------
      self.block_start = self.block_start + Xblock/srate  -- next block start_time
  end
  out_buf.resize(self.Samples*n_chans) -- resize, if need
  ---------------------------------------------------------------------------------------------------------
  -- Дальнейшие операции быстрее(примерно на 35-45%) происходят с таблицей !!!
  -- Поэтому лучше преводить в таблицу, это сильно ускоряет работу гейта - почти в два раза. 
  -- А гейт используется гораздо чаще. На перевод в таблицу уходит совсем немного - И СРАЗУ ЖЕ ОКУПАЕТСЯ.
  ---------------------------------------------------------------------------------------------------------
  self.out_buf = out_buf.table()  -- Table variant
  -- MEM2 = collectgarbage ("count") -- garbage test 
  ------------------------------------------------------
  --  Draw Filtered(Variant with full buffer) ----------
  ------------------------------------------------------
  self:draw_Filtered(0.7,0.1,0.3,1) -- New Mod Draw
  ------------------------------------------------------
  --reaper.ShowConsoleMsg("Filter time = " .. reaper.time_precise()-start_time .. '\n')--time test 
  -------------------------
  self.State = true
  gfx.dest   = -1 -- set main dest
  -------------------------
end 


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---  Wave - Get - Set Cursors  ---------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Cursor() 
  local E_Curs = reaper.GetCursorPosition()
  --- edit cursor ---
  local insrc_Ecx = (E_Curs - self.sel_start) * srate * self.X_scale    -- cursor in source!
     self.Ecx = (insrc_Ecx - self.Pos) * self.Zoom*Z_w                  -- Edit cursor
     if self.Ecx >= 0 and self.Ecx <= self.w then gfx.set(0.7,0.7,0.7,1)
        gfx.line(self.x + self.Ecx, self.y, self.x + self.Ecx, self.y+self.h -1 )
     end
  --- play cursor ---
  if reaper.GetPlayState()&1 == 1 then local P_Curs = reaper.GetPlayPosition()
     local insrc_Pcx = (P_Curs - self.sel_start) * srate * self.X_scale -- cursor in source!
     self.Pcx = (insrc_Pcx - self.Pos) * self.Zoom*Z_w                  -- Play cursor
     if self.Pcx >= 0 and self.Pcx <= self.w then gfx.set(0.5,0.5,0.5,1)
        gfx.line(self.x + self.Pcx, self.y, self.x + self.Pcx, self.y+self.h -1 )
     end
  end
end 
--------------------------
function Wave:Set_Cursor()
  if self:mouseDown() then  
    if self.insrc_mx then local New_Pos = self.sel_start + (self.insrc_mx/self.X_scale )/srate
       --reaper.SetEditCurPos(New_Pos, false, false) -- no seekplay
       reaper.SetEditCurPos(New_Pos, false, true)    -- seekplay
    end
  end
end 
----------------------------------------------------------------------------------------------------
---  Wave - Get Mouse  -----------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Mouse()
   --------------------
   self.insrc_mx = self.Pos + (gfx.mouse_x-self.x)/(self.Zoom*Z_w) -- its current mouse position in source!
   -------------------- 
   --- Wave get-set Cursors ---
   self:Get_Cursor()
   self:Set_Cursor()   
   --- Wave Zoom --------------
   if self:mouseIN() and gfx.mouse_wheel~=0 and not(Ctrl or Shift) then 
      M_Wheel = gfx.mouse_wheel; gfx.mouse_wheel = 0
      ----------------
      if     M_Wheel>0 then self.Zoom = math.min(self.Zoom*1.2, 10) 
      elseif M_Wheel<0 then self.Zoom = math.max(self.Zoom*0.8, 1) 
      end                 
      -- correction Wave Position from src --
      self.Pos = self.insrc_mx - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)  -- mouse var(for mouse cursor)
      self.Pos = math.max(self.Pos, 0)
      self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
   end
   --- Wave Move --------------
   if self:mouseM_Down() then 
      self.Pos = self.Pos + (last_x - gfx.mouse_x)/(self.Zoom*Z_w)
      self.Pos = math.max(self.Pos, 0)
      self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
   end
end

--------------------------------------------------------------------------------
---  Insert from buffer(inc. Get_Mouse) ----------------------------------------
--------------------------------------------------------------------------------
function Wave:from_gfxBuffer()
  self:update_xywh() -- update coord
  -- draw frame, axis ---
  gfx.set(0,0.5,0,0.2)
  gfx.line(self.x, self.y+self.h/2, self.x+self.w-1, self.y+self.h/2 )
  self:draw_frame() 
  -- Insert from buf ----
  if Wave.State then gfx.a = 1 -- gfx.a for blit
     -- wave from gfx buffer 1 --
     local srcw, srch = Wave.def_xywh[3], Wave.def_xywh[4] -- its always def values 
     gfx.blit(1, 1, 0, self.Pos,0, srcw/self.Zoom,srch,  self.x,self.y,self.w,self.h)
     self:Get_Mouse()   -- get mouse(for zoom,move etc)
  else self:show_help()
  end
end  

--------------------------------------------------------------------------------
---  show_help -----------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:show_help()
 gfx.setfont(1, "Arial", 15)
 gfx.set(0.7, 0.7, 0.4, 1)
 gfx.x, gfx.y = self.x+10,self.y+10
 gfx.drawstr(
  [[
  Select track, set time selection.
  Press "Get Selection" button.
  Use sliders for change detection setting.
  Ctrl + drag - fine tune.
  
  On waveform:
  Mouswheel - zoom, 
  Middle drag - move waveform,
  Left click - set edit cursor.
  Space - Play. 
  ]]) 
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---   MAIN   ---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function MAIN()
  -- Wave from buffer --
  Wave:from_gfxBuffer()
  -- Draw gate lines --
  Gate_Gl:draw_Lines()
  -- Draw sldrs,btns etc ---
  draw_controls()
end

--------------------------------------------------------------------------------
--   Draw controls(buttons,sliders,knobs etc)  ---------------------------------
--------------------------------------------------------------------------------
function draw_controls()
    for key,btn   in pairs(Button_TB) do btn:draw()   end 
    for key,sldr  in pairs(Slider_TB) do sldr:draw()  end
    for key,ch_box  in pairs(CheckBox_TB) do ch_box:draw() end
    for key,frame in pairs(Frame_TB)  do frame:draw() end       
end

--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
    -- Some gfx Wnd Default Values ---------------
    local R,G,B = 20,20,20              -- 0...255 format
    local Wnd_bgd = R + G*256 + B*65536 -- red+green*256+blue*65536  
    local Wnd_Title = "TEST"
    local Wnd_Dock,Wnd_X,Wnd_Y = 0,100,320 
    Wnd_W,Wnd_H = 1044,490 -- global values(used for define zoom level)
    -- Init window ------
    gfx.clear = Wnd_bgd         
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )
    -- Init mouse last --
    last_mouse_cap = 0
    last_x, last_y = 0, 0
    mouse_ox, mouse_oy = -1, -1
end
----------------------------------------
--   Mainloop   ------------------------
----------------------------------------
function mainloop()
    -- zoom level -- 
    Z_w, Z_h = gfx.w/Wnd_W, gfx.h/Wnd_H
    if Z_w<0.6 then Z_w = 0.6 elseif Z_w>2 then Z_w = 2 end 
    if Z_h<0.6 then Z_h = 0.6 elseif Z_h>2 then Z_h = 2 end 
    -- mouse and modkeys --
    if gfx.mouse_cap&1==1   and last_mouse_cap&1==0  or   --L mouse
       gfx.mouse_cap&2==2   and last_mouse_cap&2==0  or   --R mouse
       gfx.mouse_cap&64==64 and last_mouse_cap&64==0 then --M mouse
       mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y 
    end
    Ctrl  = gfx.mouse_cap&4==4   -- Ctrl  state
    Shift = gfx.mouse_cap&8==8   -- Shift state
    Alt   = gfx.mouse_cap&16==16 -- Shift state
    -------------------------
    -- DRAW,MAIN functions --
      MAIN() 
    -------------------------
    -------------------------
    last_mouse_cap = gfx.mouse_cap
    last_x, last_y = gfx.mouse_x, gfx.mouse_y
    char = gfx.getchar() 
    if char==32 then reaper.Main_OnCommand(40044, 0) end -- play
    if char~=-1 then reaper.defer(mainloop)              -- defer
       else Wave:Destroy_Track_Accessor()
    end          
    -----------  
    gfx.update()
    -----------
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------
--reaper.ClearConsole()
Init()
mainloop()
