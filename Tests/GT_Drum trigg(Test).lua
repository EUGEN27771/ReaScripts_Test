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

  ----------------------------------------
  -- onUp function for Filter sliders ----
  ----------------------------------------
  function Fltr_Sldrs_onUp() 
     if Wave.AA then
         Wave:Processing()
         if Wave.State then
            Gate_Gl:Apply_toFiltered()
         end
     end
  end
----------------
HP_Freq.onUp   = Fltr_Sldrs_onUp
LP_Freq.onUp   = Fltr_Sldrs_onUp
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
local Gate_DetVelo = H_Slider:new(650,440,140,18, 0.3,0.5,0.5,0.3, "Detect Velo","Arial",15, 0.1 ) -- 250,405,220,18
  function Gate_DetVelo:draw_val()
    self.form_val  = 3+ self.norm_val * 7                   -- form_val
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.form_val).." ms"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end

----------------
local Gate_Retrig = H_Slider:new(250,425,290,18, 0.3,0.5,0.5,0.3, "Retrig","Arial",15, 0.15 )
  function Gate_Retrig:draw_val()
    self.form_val  = 20+ self.norm_val * 80                 -- form_val
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.form_val).." ms"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end
 
  ----------------------------------------
  -- onUp function for Gate sliders ------
  ----------------------------------------
  function Gate_Sldrs_onUp() 
      if Wave.State then Gate_Gl:Apply_toFiltered() end 
  end
----------------
Gate_Thresh.onUp   = Gate_Sldrs_onUp
Gate_minDiff.onUp  = Gate_Sldrs_onUp
Gate_DetVelo.onUp  = Gate_Sldrs_onUp
Gate_Retrig.onUp   = Gate_Sldrs_onUp

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
    local start_time = reaper.time_precise() 
      if Wave:Create_Track_Accessor() then 
           Wave:Processing()
           if Wave.State then
              Gate_Gl:Apply_toFiltered()
           end
      end 
    --reaper.ShowConsoleMsg("Full Process time = " .. reaper.time_precise()-start_time .. '\n')--time test 
  end
----------------------------------- 
local Create_MIDI = Button:new(590,380,200,25, 0.4,0.12,0.12,0.3, "Create_MIDI",    "Arial",15 )
  Create_MIDI.onClick = 
  function()
     if Wave.State then Wave:Create_MIDI() end 
  end 
-----------------------------------
--- Button_TB ---------------------
-----------------------------------
local Button_TB = {Detect,Create_MIDI}

------------------------------------------------------------------------------------
--- CheckBoxes ---------------------------------------------------------------------
------------------------------------------------------------------------------------
    -- x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val = check, norm_val2 = checkbox table --
--------------
local CreateMIDIMode = CheckBox:new(650,410,140,18,   0.3,0.5,0.3,0.3, "","Arial",15,  1,
                              {"Create New Item","Use Selected Item"} )
--------------
local OutNote  = CheckBox:new(590,410,50,18,  0.3,0.5,0.3,0.3, "","Arial",15,  1,
                              {"36","38","40","42","44","46","48"} )
-----------------
-----------------
local VeloMode = CheckBox:new(590,440,50,18,  0.3,0.5,0.5,0.3, "","Arial",15,  1,
                              {"RMS","Peak"} )

VeloMode.onClick = Gate_Sldrs_onUp
--------------
--------------
local DrawMode = CheckBox:new(950,380,70,18,   0.3,0.5,0.5,0.3, "Draw: ","Arial",15,  3,
                              { "Very Slow", "Slow", "Medium", "Fast" } )

DrawMode.onClick = Fltr_Sldrs_onUp
-----------------------------------
--- CheckBox_TB -------------------
-----------------------------------
local CheckBox_TB = {CreateMIDIMode,OutNote,VeloMode, DrawMode}

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Gate  --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:Apply_toFiltered()
    -- Это переделывать - !!! - нужно упрощать до предела !!!
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
      -------------------------------------------------
      -- GetSet Gate Vaules ---------------------------
      -------------------------------------------------
      ------------------------------------- 
      -- Gate state tables ----------------
      self.State_Points = {}               -- State_Points table 
      self.State_Lines  = {}               -- State_Lines  table
      -------------------------------------
      -------------------------------------------------
      -- GetSet parameters ----------------------------
      -------------------------------------------------
      -- attack, release Thresholds -----
      local gain_fltr  = 10^(Fltr_Gain.form_val/20)     -- Gain from Fltr_Gain slider(need for gate Threshs)
      local Thresh  = 10^(Gate_Thresh.form_val/20)/gain_fltr * block_size   -- attThresh * fft scale(block_size)
      local minDiff = 10^(Gate_minDiff.form_val/20)
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
      local rms_val,  maxRMS  = 0, 0        -- init rms_val, RMS, maxRMS
      local peak_val, maxPeak = 0, 0        -- peak_val, maxPeak
      -------------------
      local smpl_cnt  = 0                   -- gate sample counter
      local st_cnt    = 1                   -- gate State_Points counter 
      -------------------
      local sel_start = Wave.sel_start - det_velo_sec -- sel_start(and compensation  det_velo_sec)
      local last_trig = -retrigSmpls*2
      -------------------
      local envOut1 = Wave.out_buf[1]                 -- Peak envelope1 follower
      local envOut2 = envOut1                         -- Peak envelope2 follower
      local Trig,GetSmpls = false, false              -- trigger output 
      -------------------------------------------------
      -- Compute sample frequency related coeffs ------ 
      local ga1 = math.exp(-1/(srate*attTime1))   -- attack1 coeff
      local gr1 = math.exp(-1/(srate*relTime1))   -- release1 coeff
      local ga2 = math.exp(-1/(srate*attTime2))   -- attack2 coeff
      local gr2 = math.exp(-1/(srate*relTime2))   -- release2 coeff
      
       -----------------------------------------------------------------
       -- Gate main for ------------------------------------------------
       -----------------------------------------------------------------
       for i = 1, Wave.Samples*2, 2 do
           local envIn = abs(Wave.out_buf[i]) -- abs smpl val(abs envelope)
           ---------------------------------------------
           -- Envelope1(fast) --------------------------
           if envOut1 < envIn then 
                   envOut1 = envIn + ga1 * (envOut1 - envIn) --!!! 
              else envOut1 = envIn + gr1 * (envOut1 - envIn)
           end
           ---------------------------------------------
           -- Envelope2(slow) --------------------------
           if envOut2 < envIn then 
                   envOut2 = envIn + ga2 * (envOut2 - envIn) --!!! 
              else envOut2 = envIn + gr2 * (envOut2 - envIn)
           end
           
           --------------------------------------
           -- Trigger ---------------------------  
           if retrig>retrigSmpls then
              if envOut1>Thresh and (envOut1/envOut2) > minDiff then
                 Trig = true; GetSmpls = true; retrig = 0; rms_val, peak_val = 0, 0 -- reset
              end
            else envOut2 = envOut1 -- !!!          
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
                      local RMS  = sqrt(rms_val/detVelo)
                      local Peak = peak_val
                      -- -- -- -- -- -- --
                      GetSmpls = false
                      smpl_cnt = 0
                      rms_val  = 0    
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
                      --------------------
               end
           end       
           --------------------------------------     
           retrig = retrig+1;
       end
    -----------------------------
    self.maxRMS  = maxRMS   -- store maxRMS for scaling MIDI velo
    self.maxPeak = maxPeak  -- store maxPeak for scaling MIDI velo  
    -----------------------------
    --reaper.ShowConsoleMsg("Gate time = " .. reaper.time_precise()-start_time .. '\n')--time test

    -----------------------------
    -----------------------------
    if CreateMIDIMode.norm_val == 2 then Wave:Create_MIDI() end

end

----------------------------------------------------------------------
---  Gate - Draw Gate Lines  -----------------------------------------
----------------------------------------------------------------------

function Gate_Gl:draw_Lines()
  if not self.State_Lines then return end -- return if no lines
    -- Velocity scale --
    local scale
    if VeloMode.norm_val == 1 then 
            scale = 1/Gate_Gl.maxRMS    -- velocity scale RMS
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


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
---   WAVE   -----------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
---  GetSet_MIDITake  ----------------------------------------------------------
--------------------------------------------------------------------------------
-- Создает новый айтем, либо удаляет выбранную ноту в выделленном.
function Wave:GetSet_MIDITake()
  local tracknum, midi_track, item, take
  if CreateMIDIMode.norm_val == 1 then         -- for new item -------------
      tracknum = reaper.GetMediaTrackInfo_Value(self.track, "IP_TRACKNUMBER")
      reaper.InsertTrackAtIndex(tracknum, false)
      midi_track = reaper.GetTrack(0, tracknum)
      reaper.TrackList_AdjustWindows(0)
      item = reaper.CreateNewMIDIItemInProj(midi_track, self.sel_start, self.sel_start+self.sel_len, false)
      take = reaper.GetActiveTake(item)
      return take
     ------------
    elseif CreateMIDIMode.norm_val == 2 then   -- for selected item --------
      item = reaper.GetSelectedMediaItem(0, 0)
      if item then take = reaper.GetActiveTake(item) end
         if take and reaper.TakeIsMIDI(take) then
            local ret, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
            local findpitch = tonumber(OutNote.norm_val2[OutNote.norm_val]) -- переделывать эту чушь..
            local note = 0
             for i=1, notecnt do
                 local ret, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, note)
                 if pitch==findpitch then 
                    reaper.MIDI_DeleteNote(take, note); note = note-1   -- del note witch findpitch; return counter
                 end  
                 note = note+1
             end
         reaper.MIDI_Sort(take)
         reaper.UpdateItemInProject(item)
         return item, take
      end   
  end  
end

--------------------------------------------------------------------------------
---  Create MIDI  --------------------------------------------------------------
--------------------------------------------------------------------------------
-- Создает миди-ноты в соответствии с настройками и полученными из аудио данными
function Wave:Create_MIDI()
  reaper.Undo_BeginBlock() 
  -------------------------------------------
    local item, take = Wave:GetSet_MIDITake()
    if not take then return end 
    -- Note parameters ---------
    local pitch = tonumber(OutNote.norm_val2[OutNote.norm_val]) -- переделывать эту чушь..
    local len = 60
    local sel, mute, chan = 1, 0, 0
    local startppqpos, endppqpos, vel
    -- Velocity scale --
    local scale
    if VeloMode.norm_val == 1 then 
           scale = 1/Gate_Gl.maxRMS    -- velocity scale RMS
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
    reaper.UpdateItemInProject(item)
  -------------------------------------------
  reaper.Undo_EndBlock("~Create_MIDI~", -1) 
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
         self.buffer   = reaper.new_array(block_size*2)-- L,R main block-buffer
         self.buffer.clear()
         return true
    end
end
--------
function Wave:Destroy_Track_Accessor()
 if self.AA then reaper.DestroyAudioAccessor(self.AA) 
    self.buffer.clear()
 end
end
--------
function Wave:Get_Selection_SL()
 local curs_pos = reaper.GetCursorPositionEx(0)
 local sel_start,sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
 local sel_len = sel_end - sel_start
    if sel_len>0 then 
            self.sel_start, self.sel_end, self.sel_len = sel_start,sel_end,sel_len  -- selection start, end and lenght
       else self.sel_start, self.sel_end, self.sel_len = curs_pos,curs_pos+block_size/srate,block_size/srate -- cur_pos and one block
    end
end


----------------------------------------------------------------------------------------------------
---  Wave(Processing, drawing etc)  ----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
------------------------------------------------------------
-- Filter_FFT ----------------------------------------------
------------------------------------------------------------  
function Wave:Filter_FFT(lowband, hiband)
  local buf = self.buffer
    ----------------------------------------
    -- Filter(re = Lchan, im = Rchan ) -----
    ----------------------------------------
    buf.fft(block_size,true)       -- FFT
      -----------------------------
      -- Clear lowband bins --
      buf.clear(0, 1, lowband)                       -- clear start part
      buf.clear(0,  block_size*2 - lowband + 1 )     -- clear end part
      -- Clear hiband bins  --
      buf.clear(0, hiband+1, (block_size-hiband)*2 ) -- clear mid part
      -----------------------------  
    buf.ifft(block_size,true)      -- iFFT
    ----------------------------------------
    ----------------------------------------
    --[[ Масштабирование не выполняется! Экономит время.
         Сигнал на выходе в  block_size раз выше по уровню! 
         Масштабирование просто нужно учесть в дальнейшем - в гейте, прорисовке и т.п. --]]
    ----------------------------------------
end  

--------------------------------------------------------------------------------
-- Wave:Set_Coord --------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Set_Coord()
  --gfx buffer always used def coord! --
  local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4] 
    ---------------------------------
    -- init peak tables -------------
    self.in_peaks  = {}    
    self.out_peaks = {}
    ------------------
    self.max_Zoom = 50          -- maximum zoom level(need optim value)
    self.Zoom = self.Zoom or 1  -- init Zoom 
    self.Pos  = self.Pos  or 0  -- init src position
    ------------------
    self:Get_Selection_SL()
    ------------------
    self.sel_len = math.min(self.sel_len,47)  -- limit lenght(deliberate restriction) 
    self.Samples    = math.floor(self.sel_len*srate)      -- Lenght to samples
    self.Blocks     = math.ceil(self.Samples/block_size)  -- Lenght to sampleblocks
    -- pix_dens - Нужно выбрать оптимум!!!
    self.pix_dens = 2^DrawMode.norm_val                 -- 2-учесть все семплы для прорисовки(max кач-во),4-через один и тд.
    self.X, self.Y  = x, h/2                            -- waveform position(X,Y axis)
    self.X_scale    = w/self.Samples                    -- X_scale = w/lenght in samples
    self.Y_scale    = h/2                               -- Y_scale for waveform drawing
    -- Its not real Gain - only visual :) !!! -- но это тоже обязательно учитывать в дальнейшем, экономит время - такой себе фокус...
    self.Y_scaleFltr   = (h/2)/block_size *10^(Fltr_Gain.form_val/20)   -- from Fltr_Gain Sldr!-- Y_scale for filtered waveform drawing

end

--------------------------------------------------------------------------------------------
--- DRAW -----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- Draw Original,Filtered(New Var) --------------------------------------------
--------------------------------------------------------------------------------
function Wave:Redraw() -- 
  local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4] 
  gfx.dest = 1             -- set dest gfx buffer1
  gfx.a    = 1             -- for buf    
    gfx.setimgdim(1,-1,-1) -- clear buf1(wave)
    gfx.setimgdim(1,w,h)   -- set w,h
    ---------------
    self:draw_waveform(1,  0.3,0.4,0.7,1) -- Draw Original(mode=1)
    self:draw_waveform(2,  0.7,0.1,0.3,1) -- Draw Filtered(mode=2)
    ---------------
    gfx.dest = -1          -- set main gfx dest buffer
    ---------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:draw_waveform(mode, r,g,b,a)
    local Peak_TB, Ysc
    local Y = self.Y
    if mode==1 then Peak_TB = self.in_peaks;  Ysc = self.Y_scale   
               else Peak_TB = self.out_peaks; Ysc = self.Y_scaleFltr    
    end 
    ----------------------------
    ----------------------------
    local min = math.min
    local max = math.max
    ----------------------------
    local Zfact = self.max_Zoom/self.Zoom  -- zoom factor
    local Ppos = self.Pos*self.max_Zoom    -- старт. позиция в "мелкой"-Peak_TB для начала прорисовки  
    local p = math.ceil(Ppos+1)
    gfx.set(r,g,b,a)                       -- set color
    ----------------------------------------------
    local w = self.def_xywh[3] -- 1024=def width
    for i=1, w do            
       local next = i*Zfact + Ppos
       local min_peak, max_peak, peak = 0, 0, 0 
          -----
          while p<= next do 
              peak = Peak_TB[p][1]
                min_peak = min(min_peak, peak)
                max_peak = max(max_peak, peak)
              peak = Peak_TB[p][2]
                min_peak = min(min_peak, peak)
                max_peak = max(max_peak, peak)
              p=p+1
          end
          ----- 
        local y, y2 = Y - min_peak *Ysc, Y - max_peak *Ysc 
        gfx.line(i,y, i,y2) -- (x,y,x2,y2[,aa]) - здесь всегда x=i (or i-1 ?)
    end  
    ----------------------------------------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:Create_Peaks(mode)
    local buf
    if mode==1 then buf = self.in_buf    -- for input(original)    
               else buf = self.out_buf   -- for output(filtered)
    end
    ----------------------------
    local min = math.min
    local max = math.max
    ----------------------------
    local Peak_TB = {}
    local w = self.def_xywh[3] -- 1024=def width 
    local pix_dens = self.pix_dens
    local smpl_inpix = (self.Samples*n_chans/w) /self.max_Zoom  -- кол-во семплов на один пик (1024 = def gfx w)
    local s=1
    ----------------------------
    for i=1, w * self.max_Zoom do
        local next = i*smpl_inpix
        local min_smpl, max_smpl, smpl = 0, 0, 0 
        while s<= next do 
            smpl = buf[s]
              min_smpl = min(min_smpl, smpl)
              max_smpl = max(max_smpl, smpl)
            s=s+pix_dens
        end
        Peak_TB[#Peak_TB+1] = {min_smpl, max_smpl} -- min, max val to table   
    end
    ----------------------------
    if mode==1 then self.in_peaks = Peak_TB else self.out_peaks = Peak_TB end    
    ----------------------------
end


------------------------------------------------------------------------------------------------------------------------
-- WAVE - (Get samples(in_buf) > filtering > to out-buf > Create in, out peaks ) ---------------------------------------
------------------------------------------------------------------------------------------------------------------------
function Wave:Processing()
  local start_time = reaper.time_precise()--time test
    -----------------------------------------------
    self:Set_Coord() -- set main values, coordinates etc
    -----------------------------------------------
    local crsx = block_size/8   -- one side "crossX" - use for discard some FFT artefacts(Its non-native, but in this case normally!)
    local Xblock = block_size-crsx*2                               -- active part of full block
    self.A_Blocks  = math.ceil( self.Samples/Xblock )              -- sel_len to active sampleblocks 
    local in_buf  = reaper.new_array(self.Samples*n_chans)         -- buffer for original(input) samples
    local out_buf = reaper.new_array(self.A_Blocks*Xblock*n_chans) -- buffer for filtered(output) samples - rnd to blocks!
    in_buf.clear(0)                                                -- clear in_buf
    out_buf.clear(0)                                               -- clear out_buf 
    self.block_start = self.sel_start - (crsx/srate)/n_chans       -- first block start(regard crsx)
      -------------------------------
      -- Filter values --------------
      -------------------------------
      -- LP = HiFreq, HP = LowFreq --
      local Low_Freq, Hi_Freq =  HP_Freq.form_val, LP_Freq.form_val
      local bin_freq = srate/(block_size*2)          -- freq step 
      local lowband  = Low_Freq/bin_freq             -- low bin
      local hiband   = Hi_Freq/bin_freq              -- hi bin
      -- lowband, hiband to valid values(need even int) ------------
      lowband = math.floor(lowband/2)*2
      hiband  = math.ceil(hiband/2)*2  
    
    
    -- Тут нужно переделывать !!! --------------
    -- По идее, можно брать семплы из in_buf, и не трогать акцессор.
    -- Это и проще, и быстрее.  ----------------
    --------------------------------------------------------
    -- Get Original(input samples-All!) to in_buf ----------
    --------------------------------------------------------
    reaper.GetAudioAccessorSamples(self.AA,srate,n_chans,self.sel_start,self.Samples, in_buf) -- orig samples to in_buf for drawing
     
    --------------------------------------------------------
    -- Filtering each block and add to out_buf -------------
    --------------------------------------------------------
    for block=1, self.A_Blocks do reaper.GetAudioAccessorSamples(self.AA,srate,n_chans,self.block_start,block_size, self.buffer)
        self.block_X = (block-1)* Xblock * self.X_scale     -- X-offs for draw each block
        --------------------
        self:Filter_FFT(lowband, hiband)                    -- Filter(note: don't use out of range freq!)
        out_buf.copy(self.buffer, crsx+1, n_chans*Xblock, (block-1)* n_chans*Xblock + 1 ) -- copy block to out_buf with offset
        --------------------
        self.block_start = self.block_start + Xblock/srate  -- next block start_time
    end
    out_buf.resize(self.Samples*n_chans) -- resize out_buf to selection lenght
    --------------------------------------------------------
    
    ---------------------------------------------------------------------------------------------------------
    -- Дальнейшие операции быстрее(примерно на 35-45%) происходят с таблицей, проверено !!!
    -- Поэтому лучше преводить в таблицу, это сильно ускоряет работу гейта - почти в два раза. 
    -- А гейт используется гораздо чаще. На перевод в таблицу уходит совсем немного - И СРАЗУ ЖЕ ОКУПАЕТСЯ.
    ---------------------------------------------------------------------------------------------------------
    self.in_buf  = in_buf.table()   -- to table in_buf
    self.out_buf = out_buf.table()  -- to table out_buf
    --Garb = collectgarbage ("count")/1024 -- garbage test in MB 
    ------------------------------------------------------
    -- Create_Peaks - Original and Filtered --------------
    ------------------------------------------------------
    self:Create_Peaks(1)  -- input wave peaks
    self:Create_Peaks(2)  -- output wave peaks
    self:Redraw()
    ------------------------------------------------------
    self.State = true
    -------------------------
  --reaper.ShowConsoleMsg("Filter time = " .. reaper.time_precise()-start_time .. '\n')--time test   
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
   --- Wave get-set Cursors ----
   self:Get_Cursor()
   self:Set_Cursor()   
   --- Wave Zoom ---------------
   if self:mouseIN() and gfx.mouse_wheel~=0 and not(Ctrl or Shift) then 
      M_Wheel = gfx.mouse_wheel; gfx.mouse_wheel = 0
      -------------------
      if     M_Wheel>0 then self.Zoom = math.min(self.Zoom*1.2, self.max_Zoom)   
      elseif M_Wheel<0 then self.Zoom = math.max(self.Zoom*0.8, 1)
      end                 
      -- correction Wave Position from src --
      self.Pos = self.insrc_mx - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos = math.max(self.Pos, 0)
      self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      -------------------
      Wave:Redraw() -- redraw after zoom
   end
   --- Wave Move --------------
   if self:mouseM_Down() then 
      self.Pos = self.Pos + (last_x - gfx.mouse_x)/(self.Zoom*Z_w)
      self.Pos = math.max(self.Pos, 0)
      self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      --------------------
      Wave:Redraw() -- redraw after move
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
  -- Insert Wave from buf ----
  if Wave.State then gfx.a = 1 -- gfx.a for blit
     -- from gfx buffer 1 ----
     local srcw, srch = Wave.def_xywh[3], Wave.def_xywh[4] -- its always def values 
     gfx.blit(1, 1, 0, 0, 0, srcw, srch,  self.x, self.y, self.w, self.h)
     self:Get_Mouse()     -- get mouse(for zoom,move etc)
  else self:show_help()
  end
end  

--------------------------------------------------------------------------------
---  show_help -----------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:show_help()
 gfx.setfont(1, "Arial", 15)
 gfx.set(0.7, 0.7, 0.4, 1)
 gfx.x, gfx.y = self.x+10, self.y+10
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
  -- Wave from gfx buffer ---
  Wave:from_gfxBuffer()
  -- Draw Gate lines --------
  Gate_Gl:draw_Lines()
  -- Draw sldrs, btns etc ---
  draw_controls()
end

--------------------------------------------------------------------------------
--   Draw controls(buttons,sliders,knobs etc)  ---------------------------------
--------------------------------------------------------------------------------
function draw_controls()
    for key,btn    in pairs(Button_TB)   do btn:draw()    end 
    for key,sldr   in pairs(Slider_TB)   do sldr:draw()   end
    for key,ch_box in pairs(CheckBox_TB) do ch_box:draw() end
    for key,frame  in pairs(Frame_TB)    do frame:draw()  end       
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
    -------------------------
    MAIN() -- main function
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
