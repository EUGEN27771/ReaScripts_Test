--[[
   * ReaScript Name:Drums to MIDI(test version)
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.0
  ]]
--[[
   * Внимание, это тестовая версия!!!
--]]
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
local block_size = 1024*16 -- Block size
local n_chans = 2       -- num_chans

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
---  Create Objects(Wave,Gate) ---------------------------------------------------------------------
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
local Wave = Element:new(10,10,1024,350)
------------------
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
----------------
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
local Fltr_Gain = H_Slider:new(20,450,180,18,  0.3,0.5,0.5,0.3, "Filter Gain","Arial",15, 0 )
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
     local start_time = reaper.time_precise()
     ---------- 
     if Wave.AA then Wave:Processing()
        if Wave.State then
           Wave:Redraw() 
           Gate_Gl:Apply_toFiltered()
        end
     end
     ---------- 
     --reaper.ShowConsoleMsg("Full Process - Original = " .. reaper.time_precise()-start_time .. '\n')--time test
  end
----------------
HP_Freq.onUp   = Fltr_Sldrs_onUp
LP_Freq.onUp   = Fltr_Sldrs_onUp
----------------
----------------
Fltr_Gain.onUp =
  function() 
     if Wave.State then 
        Wave:Redraw()
        Gate_Gl:Apply_toFiltered() 
     end 
  end

------------------------------------------------------------------------------------
--- Gate Sliders -------------------------------------------------------------------
------------------------------------------------------------------------------------
local Gate_Thresh = H_Slider:new(250,380,290,18, 0.3,0.5,0.7,0.3, "Threshold","Arial",15, 1 )
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
      local val = (10^(self.form_val/20)) * Wave.Y_scale * Wave.vertZoom * Z_h -- value in gfx
      if val>Wave.h/2 then return end            -- don't draw lines if value out of range
      local val_line1 = Wave.y + Wave.h/2 - val  -- line1 y coord
      local val_line2 = Wave.y + Wave.h/2 + val  -- line2 y coord
      gfx.line(Wave.x, val_line1, Wave.x+Wave.w-1, val_line1 )
      gfx.line(Wave.x, val_line2, Wave.x+Wave.w-1, val_line2 )
    end
  end
----------------
local Gate_Sensetive = H_Slider:new(250,400,290,18, 0.3,0.5,0.7,0.3, "Sensetive","Arial",15, 0.2 )
  function Gate_Sensetive:draw_val()
    self.form_val = 2+(self.norm_val)*15
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.form_val).." dB"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end
----------------
local Gate_Retrig = H_Slider:new(250,420,290,18, 0.3,0.5,0.5,0.3, "Retrig","Arial",15, 0.15 )
  function Gate_Retrig:draw_val()
    self.form_val  = 20+ self.norm_val * 80                 -- form_val
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.1f", self.form_val).." ms"
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5
    gfx.drawstr(val)--draw Slider Value
  end
---------------- Detect velo time(slider in MIDI section)
local Gate_DetVelo = H_Slider:new(650,430,140,18, 0.3,0.5,0.5,0.3, "Detect Velo","Arial",15, 0.1 ) -- 250,405,220,18
  function Gate_DetVelo:draw_val()
    self.form_val  = 3+ self.norm_val * 7                   -- form_val
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
Gate_Thresh.onUp    = Gate_Sldrs_onUp
Gate_Sensetive.onUp = Gate_Sldrs_onUp
Gate_Retrig.onUp    = Gate_Sldrs_onUp
Gate_DetVelo.onUp   = Gate_Sldrs_onUp

-----------------------------------
--- Slider_TB ---------------------
-----------------------------------
local Slider_TB = {HP_Freq,LP_Freq,Fltr_Gain, Gate_Thresh, Gate_Sensetive, Gate_DetVelo,Gate_Retrig }

------------------------------------------------------------------------------------
--- Buttons ------------------------------------------------------------------------
------------------------------------------------------------------------------------
local Detect = Button:new(20,380,180,25, 0.4,0.12,0.12,0.3, "Get Selection",    "Arial",15 )
  Detect.onClick = 
  function()
     local start_time = reaper.time_precise()
     ----------
     Wave.State = false -- reset Wave.State
     if Wave:Create_Track_Accessor() then Wave:Processing()
        if Wave.State then
           Wave:Redraw()  
           Gate_Gl:Apply_toFiltered() 
        end
     end
     ---------- 
     reaper.ShowConsoleMsg("Full Process time = " .. reaper.time_precise()-start_time .. '\n')--time test 
  end
----------------------------------- 
local Create_MIDI = Button:new(590,380,200,25, 0.4,0.12,0.12,0.3, "Create MIDI",    "Arial",15 )
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
----------------------------------------------------------------------------------------
local CreateMIDIMode = CheckBox:new(650,410,140,18,   0.3,0.5,0.3,0.3, "","Arial",15,  1,
                              {"Create New Item","Use Selected Item"} )
-----------------
local OutNote  = CheckBox:new(590,410,50,18,  0.3,0.5,0.3,0.3, "","Arial",15,  1,
                              {36,37,38,39,40,41,42,43,44,45,46,47} )
-----------------
-----------------
local VeloMode = CheckBox:new(590,430,50,18,  0.3,0.5,0.5,0.3, "","Arial",15,  1,
                              {"RMS","Peak"} )

VeloMode.onClick = 
  function()
     if Wave.State and CreateMIDIMode.norm_val == 2 then Wave:Create_MIDI() end
  end
-----------------------------------
-----------------------------------
local DrawMode = CheckBox:new(950,380,70,18,   0.3,0.5,0.5,0.3, "Draw: ","Arial",15,  3,
                              { "Very Slow", "Slow", "Medium", "Fast" } )

DrawMode.onClick = Fltr_Sldrs_onUp
--------------
local ViewMode = CheckBox:new(950,400,70,18,   0.3,0.5,0.5,0.3, "View: ","Arial",15,  1,
                              { "All", "Original", "Filtered" } )
ViewMode.onClick = 
  function() 
     if Wave.State then Wave:Redraw() end 
  end
-----------------------------------
--- CheckBox_TB -------------------
-----------------------------------
local CheckBox_TB = {CreateMIDIMode,OutNote,VeloMode, DrawMode, ViewMode}



----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------
-- Some used functions(local func work faster) --
-------------------------------------------------
local abs  = math.abs
local min  = math.min
local max  = math.max
local sqrt = math.sqrt  

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Gate  --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:Apply_toFiltered()
    ---------------------------------------------------
    local start_time = reaper.time_precise()--time test
    ---------------------------------------------------
      -------------------------------------------------
      -- GetSet Gate Vaules ---------------------------
      -------------------------------------------------
      ------------------------------------- 
      -- Gate state tables ----------------
      self.State_Points = {}               -- State_Points table 
      -------------------------------------
      -------------------------------------------------
      -- GetSet parameters ----------------------------
      -------------------------------------------------
      -- attack, release Thresholds -----
      local gain_fltr  = 10^(Fltr_Gain.form_val/20)       -- Gain from Fltr_Gain slider(need for scaling gate Thresh!)
      local Thresh     = 10^(Gate_Thresh.form_val/20)/gain_fltr * block_size   -- attThresh * fft scale(block_size)
      local Sensetive  = 10^(Gate_Sensetive.form_val/20)  -- Gate "Sensetive", diff between - fast and slow envelopes(in dB)
      -- attack, release Time -----------
      -- Эти параметры нужно либо выносить в доп. настройки, либо подбирать тщательнее...
      local attTime1  = 0.001                            -- Env1 attack(sec)
      local attTime2  = 0.007                            -- Env2 attack(sec)
      local relTime1  = 0.010                            -- Env1 release(sec)
      local relTime2  = 0.015                            -- Env2 release(sec)
      -----------------------------------
      -- Init counters etc --------------
      ----------------------------------- 
      local retrig_smpls   = math.floor(Gate_Retrig.form_val/1000*srate)  -- Retrig slider to samples
      local retrig         = retrig_smpls+1                               -- Retrig counter start value!
      local det_velo_smpls = math.floor(Gate_DetVelo.form_val/1000*srate) -- DetVelo slider to samples 
      -----------------------------------
      local rms_sum,   maxRMS  = 0, 0       -- init rms_sum,   maxRMS
      local peak_smpl, maxPeak = 0, 0       -- init peak_smpl, maxPeak
      -------------------
      local smpl_cnt  = 0                   -- Gate sample(for get velo) counter
      local st_cnt    = 1                   -- Gate State counter for State tables
      -------------------
      -------------------
      local envOut1 = Wave.out_buf[1]        -- Peak envelope1 follower start value
      local envOut2 = envOut1                -- Peak envelope2 follower start value
      local GetSmpls = false                 -- Trigger, GetSmpls init state 
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
           if retrig>retrig_smpls then
              if envOut1>Thresh and (envOut1/envOut2) > Sensetive then
                 GetSmpls = true; smpl_cnt = 0; retrig = 0; rms_sum, peak_smpl = 0, 0 -- set start-values(for capture velo)
              end
            else envOut2 = envOut1 -- уравнивает огибающие, здесь это важно!!!          
           end
           ------------------------------------------------------------
           -- Get velo ------------------------------------------------
           ------------------------------------------------------------
           if GetSmpls then
              if smpl_cnt<=det_velo_smpls then 
                 rms_sum   = rms_sum + Wave.out_buf[i] * Wave.out_buf[i]   -- get rms_sum for note-velo
                 peak_smpl = max(peak_smpl, Wave.out_buf[i])               -- find peak_smpl for note-velo
                 smpl_cnt = smpl_cnt+1 
                 ---------------------------     
                 else 
                      GetSmpls = false -- reset GetSmpls state !!!
                      --------------------
                      local RMS  = sqrt(rms_sum/det_velo_smpls)  -- calculate RMS
                      --- Trigg point -----
                      self.State_Points[st_cnt]   = (i-1)/2 - det_velo_smpls  -- Time point(in Samples!) 
                      self.State_Points[st_cnt+1] = {RMS, peak_smpl}        -- RMS, Peak values
                      --------
                      maxRMS  = max(maxRMS, RMS)         -- save maxRMS for scaling
                      maxPeak = max(maxPeak, peak_smpl)  -- save maxPeak for scaling             
                      --------
                      st_cnt = st_cnt+2
                      --------------------
              end
           end       
           --------------------------------------     
           retrig = retrig+1
       end
    -----------------------------
    self.maxRMS  = maxRMS   -- store maxRMS for scaling MIDI velo
    self.maxPeak = maxPeak  -- store maxPeak for scaling MIDI velo  
    -----------------------------
    --reaper.ShowConsoleMsg("Gate time = " .. reaper.time_precise()-start_time .. '\n')--time test

    -----------------------------
    -----------------------------
    if CreateMIDIMode.norm_val == 2 then Wave:Create_MIDI() end -- Auto-create MIDI, when mode == 2(use sel item)
    -----------------------------
  --Garb = collectgarbage ("count")/1024 -- garbage test in MB
  collectgarbage("collect")            -- collectgarbage 
end

----------------------------------------------------------------------
---  Gate - Draw Gate Lines  -----------------------------------------
----------------------------------------------------------------------

function Gate_Gl:draw_Lines()
  if not self.State_Points or #self.State_Points==0 then return end -- return if no lines
    -- Velocity scale -----
    local mode = VeloMode.norm_val
    local scale
    if mode == 1 then scale = 1/Gate_Gl.maxRMS    -- velocity scale by RMS
                 else scale = 1/Gate_Gl.maxPeak   -- velocity scale by Peaks
    end
    -- Pos, X, Y scale ---------
    local Pos_smpls = Wave.Pos/Wave.X_scale     -- Стартовая позиция отрисовки в семплах!
    local Xsc = Wave.X_scale * Wave.Zoom * Z_w  -- x scale(regard zoom) for trigg lines
    local Yop = Wave.y + Wave.h  -- y start wave coord for velo points
    local Ysc = Wave.h * scale   -- y scale for velo points 
    
    -- lines, points color -----
    gfx.set(1, 1, 0) -- gate line, point color
    ----------------------------
    for i=1, #self.State_Points, 2 do
       -- draw line, velo ------ 
       local line_x   = Wave.x + (self.State_Points[i] - Pos_smpls) * Xsc  -- line x coord
       local velo_y   = Yop -  self.State_Points[i+1][mode] * Ysc          -- velo y coord    
       -------------------------
       -------------------------
       if line_x>=Wave.x and line_x<=Wave.x+Wave.w then
          ----------------------
          gfx.a = 0.6     -- gate line a
          gfx.line(line_x, Wave.y, line_x, Yop-1)
          ----------------------
          gfx.a = 0.8     -- velo point a
          gfx.circle(line_x, velo_y, 2,1,1) -- Velocity point
       end
       -------------------------
       if not self.captd and abs(line_x-gfx.mouse_x)<10 and ((Shift and Wave:mouseDown()) or 
          Wave:mouseR_Down()) then self.captd = i
       end
       -------------------------
    end
  
  ------------------------
  ------------------------  
      ------------------------------------------------------
      -- Operations witch captured etc ---------------------
      ------------------------------------------------------
      if self.captd and Shift and Wave:mouseDown() then
        -- Move -----------------------------------------
        local line_x = Wave.x + (self.State_Points[self.captd] - Pos_smpls) * Xsc  -- line x coord
        local curs_y = min(max(gfx.mouse_y, Wave.y), Yop)
             gfx.set(1, 1, 1, 1) -- cursor color 
             gfx.line(line_x-12, curs_y, line_x+12, curs_y)
             gfx.circle(line_x, curs_y, 3 , 0, 1)
             ---------
             self.State_Points[self.captd] = self.State_Points[self.captd] + (gfx.mouse_x-last_x) / Xsc
        -- Delete ---------------------------------------
        elseif self.captd and Wave:mouseR_Down() then gfx.x, gfx.y  = gfx.mouse_x, gfx.mouse_y
          if gfx.showmenu("Delete")==1 then
             table.remove(self.State_Points,self.captd) -- Del self.captd - Элементы смещаются влево!
             table.remove(self.State_Points,self.captd) -- Поэтому, опять тот же индекс(а не self.captd+1)
          end
        -- Insert  --------------------------------------
        elseif Wave:mouseR_Down() then gfx.x, gfx.y  = gfx.mouse_x, gfx.mouse_y
          if gfx.showmenu("Insert")==1 then
             local line_pos = Pos_smpls + gfx.mouse_x/Xsc            -- Time point(in Samples!) from mouse x pos
             local veloRMS  = (Yop - gfx.y)/(Wave.h/Gate_Gl.maxRMS)  -- veloRMS from mouse y pos
             local veloPeak = (Yop - gfx.y)/(Wave.h/Gate_Gl.maxPeak) -- veloPeak from mouse y pos
             table.insert(self.State_Points, line_pos)            -- В конец таблицы
             table.insert(self.State_Points, {veloRMS, veloPeak}) -- В конец таблицы
             ----------
             self.captd = #self.State_Points
          end 
      end
      
      ------------------------------------------------------
      -- Update captured state if mouse released -----------
      ------------------------------------------------------
      if self.captd and Wave:mouseUp() then self.captd = false  
         if CreateMIDIMode.norm_val == 2 then Wave:Create_MIDI() end -- Auto-create MIDI, when mode == 2(use sel item)
      end
end

------------------------------------------------------
-- Gate -  manual_Correction -------------------------
--[[--------------------------------------------------
function Gate_Gl:manual_Correction()
end--]]

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
      return item, take
     ------------
    elseif CreateMIDIMode.norm_val == 2 then   -- for selected item --------
      item = reaper.GetSelectedMediaItem(0, 0)
      if item then take = reaper.GetActiveTake(item) end
         if take and reaper.TakeIsMIDI(take) then
            local ret, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
            local findpitch = OutNote.norm_val2[OutNote.norm_val]
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
    local pitch = OutNote.norm_val2[OutNote.norm_val]
    local len = 60
    local sel, mute, chan = 1, 0, 0
    local startppqpos, endppqpos, vel
    -- Velocity scale --
    local mode = VeloMode.norm_val
    local scale
    if mode == 1 then scale = (1/Gate_Gl.maxRMS)*127   -- velocity scale by RMS
                 else scale = (1/Gate_Gl.maxPeak)*127  -- velocity scale by Peaks
    end
    -----------
    for i=1, #Gate_Gl.State_Points, 2 do
        startppqpos = reaper.MIDI_GetPPQPosFromProjTime(take, self.sel_start + Gate_Gl.State_Points[i]/srate )
        endppqpos   = startppqpos + len
        vel = math.floor(Gate_Gl.State_Points[i+1][mode] *scale)
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
         self.AA_Hash  = reaper.GetAudioAccessorHash(self.AA, "")
         self.AA_start = reaper.GetAudioAccessorStartTime(self.AA)
         self.AA_end   = reaper.GetAudioAccessorEndTime(self.AA)
         self.buffer   = reaper.new_array(block_size*2)-- L,R main block-buffer
         self.buffer.clear()
         return true
    end
end
--------
function Wave:Validate_Accessor()
 if self.AA then 
    if not reaper.AudioAccessorValidateState(self.AA) then return true end 
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
  -- gfx buffer always used default Wave coordinates! --
  local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4] 
    ---------------------------------
    -- init Horizontal --------------
    self.max_Zoom = 50          -- maximum zoom level(need optim value)
    self.Zoom = self.Zoom or 1  -- init Zoom 
    self.Pos  = self.Pos  or 0  -- init src position
    -- init Vertical ----------------
    self.max_vertZoom = 6       -- maximum vertical zoom level(need optim value)
    self.vertZoom = self.vertZoom or 1  -- init vertical Zoom 
    -- Get Selection ----------------
    self:Get_Selection_SL()     -- Get sel track, sel start, sel lenght
    -- Calculate some values --------
    self.sel_len = math.min(self.sel_len,47)  -- limit lenght(deliberate restriction) 
    self.Samples    = math.floor(self.sel_len*srate)      -- Lenght to samples
    self.Blocks     = math.ceil(self.Samples/block_size)  -- Lenght to sampleblocks
    -- pix_dens - Здесь нужно выбрать оптимум или оптимальную зависимость от sel_len!!!
    self.pix_dens = 2^DrawMode.norm_val                 -- 2-учесть все семплы для прорисовки(max кач-во),4-через один и тд.
    self.X, self.Y  = x, h/2                            -- waveform position(X,Y axis)
    self.X_scale    = w/self.Samples                    -- X_scale = w/lenght in samples
    self.Y_scale    = h/2                               -- Y_scale for waveform drawing
 
end

--------------------------------------------------------------------------------------------
--- DRAW -----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- Draw Original,Filtered -----------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Redraw() -- 
    local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4] 
    ---------------
    gfx.dest = 1             -- set dest gfx buffer1
    gfx.a    = 1             -- a - for buf    
    gfx.setimgdim(1,-1,-1) -- clear buf1(Wave)
    gfx.setimgdim(1,w,h)   -- set gfx buffer w,h
    ---------------
      if ViewMode.norm_val == 1 then self:draw_waveform(1,  0.3,0.4,0.7,1) -- Draw Original(1, r,g,b,a)
                                     self:draw_waveform(2,  0.7,0.1,0.3,1) -- Draw Filtered(2, r,g,b,a)
        elseif ViewMode.norm_val == 2 then self:draw_waveform(1,  0.3,0.4,0.7,1) -- Only original
        elseif ViewMode.norm_val == 3 then self:draw_waveform(2,  0.7,0.1,0.3,1) -- Only filtered
      end
    ---------------
    gfx.dest = -1          -- set main gfx dest buffer
    ---------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:draw_waveform(mode, r,g,b,a)
    local Peak_TB, Ysc
    local Y = self.Y
    ----------------------------
    if mode==1 then Peak_TB = self.in_peaks;  Ysc = self.Y_scale * self.vertZoom end  
    if mode==2 then Peak_TB = self.out_peaks;
       -- Its not real Gain - only visual - но это обязательно учитывать в дальнейшем, экономит время - такой себе фокус...
       local fltr_gain = 10^(Fltr_Gain.form_val/20)               -- from Fltr_Gain Sldr!
       Ysc = self.Y_scale/block_size * fltr_gain * self.vertZoom  -- Y_scale for filtered waveform drawing 
    end   
    ----------------------------
    ----------------------------
    ----------------------------
    local Zfact = self.max_Zoom/self.Zoom  -- zoom factor
    local Ppos = self.Pos*self.max_Zoom    -- старт. позиция в "мелкой"-Peak_TB для начала прорисовки  
    local p = math.ceil(Ppos+1)
    gfx.set(r,g,b,a)                       -- set color
    ----------------------------------------------
    local w = self.def_xywh[3] -- 1024 = def width
    for i=1, w do            
       local next = i*Zfact + Ppos
       local min_peak, max_peak, peak = 0, 0, 0 
          -----
          while p< next do 
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
        gfx.line(i,y, i,y2) -- (x,y,x2,y2[,aa]) - здесь всегда x=i
    end  
    ----------------------------------------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:Create_Peaks(mode) -- mode = 1 for oriinal, mode = 2 for filtered
    local buf
    if mode==1 then buf = self.in_buf    -- for input(original)    
               else buf = self.out_buf   -- for output(filtered)
    end
    ----------------------------
    ----------------------------
    local Peak_TB = {}
    local w = self.def_xywh[3] -- 1024 = def width 
    local pix_dens = self.pix_dens
    local smpl_inpix = (self.Samples*n_chans/w) /self.max_Zoom  -- кол-во семплов на один пик (1024 = def gfx w)
    local s=1
    ----------------------------
    for i=1, w * self.max_Zoom do
        local next = i*smpl_inpix
        local min_smpl, max_smpl, smpl = 0, 0, 0 
        while s< next do 
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
    -------------------------------------------------------------------------
    -- Get Original(input) samples to in_buf >> to table >> create peaks ----
    -------------------------------------------------------------------------
    if not self.State then
        self:Set_Coord() -- set main values, coordinates etc   
        ------------------------------------------------------
        local in_buf  = reaper.new_array(self.Samples*n_chans)         -- buffer for original(input) samples
        in_buf.clear(0)                                                -- clear in_buf
        reaper.GetAudioAccessorSamples(self.AA, srate,n_chans, self.sel_start,self.Samples, in_buf) -- orig samples to in_buf for drawing
        self.in_buf  = in_buf.table()   -- to table in_buf
        self:Create_Peaks(1)  -- Create_Peaks input(Original) wave peaks
    end
    
    -------------------------------------------------------------
    -- Filter values --------------------------------------------
    -------------------------------------------------------------
    local crsx = block_size/8   -- one side "crossX" - use for discard some FFT artefacts(Its non-native, but in this case normally!)
    local Xblock = block_size-crsx*2                               -- active part of full block
    local A_Blocks  = math.ceil( self.Samples/Xblock )             -- sel_len to active sampleblocks 
    local out_buf = reaper.new_array(A_Blocks*Xblock*n_chans) -- buffer for filtered(output) samples - rnd to blocks!
    out_buf.clear(0)                                               -- clear out_buf 
    local block_start = self.sel_start - (crsx/srate)/n_chans      -- first block start(regard crsx)
      -------------------------------
      -- LP = HiFreq, HP = LowFreq --
      local Low_Freq, Hi_Freq =  HP_Freq.form_val, LP_Freq.form_val
      local bin_freq = srate/(block_size*2)          -- freq step 
      local lowband  = Low_Freq/bin_freq             -- low bin
      local hiband   = Hi_Freq/bin_freq              -- hi bin
      -- lowband, hiband to valid values(need even int) ------------
      lowband = math.floor(lowband/2)*2
      hiband  = math.ceil(hiband/2)*2  
    -------------------------------------------------------------
    -- Filtering each block and add to out_buf ------------------
    -------------------------------------------------------------
    for block=1, A_Blocks do reaper.GetAudioAccessorSamples(self.AA, srate,n_chans, block_start,block_size, self.buffer)
        --------------------
        self:Filter_FFT(lowband, hiband)                    -- Filter(note: don't use out of range freq!)
        out_buf.copy(self.buffer, crsx+1, n_chans*Xblock, (block-1)* n_chans*Xblock + 1 ) -- copy block to out_buf with offset
        --------------------
        block_start = block_start + Xblock/srate  -- next block start_time
    end
    out_buf.resize(self.Samples*n_chans) -- resize out_buf to selection lenght!
    -------------------------------------------------------------
    
    -------------------------------------------------------------------------
    -- Filtered(output) samples to to table >> create peaks -----------------
    -------------------------------------------------------------------------
    self.out_buf = out_buf.table()  -- to table out_buf
    self:Create_Peaks(2)  -- Create_Peaks output(Filtered) wave peaks
    -------------------------------------------------------------------------
    
    self.State = true -- Change State
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
  if self:mouseDown() and not(Ctrl or Shift) then  
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
    -----------------------------
    self.insrc_mx = self.Pos + (gfx.mouse_x-self.x)/(self.Zoom*Z_w) -- its current mouse position in source!
    ----------------------------- 
    --- Wave get-set Cursors ----
    self:Get_Cursor()
    self:Set_Cursor()   
    -----------------------------------------
    --- Wave Zoom(horizontal) ---------------
    if self:mouseIN() and gfx.mouse_wheel~=0 and not(Ctrl or Shift) then 
      M_Wheel = gfx.mouse_wheel
      -------------------
      if     M_Wheel>0 then self.Zoom = math.min(self.Zoom*1.2, self.max_Zoom)   
      elseif M_Wheel<0 then self.Zoom = math.max(self.Zoom*0.8, 1)
      end                 
      -- correction Wave Position from src --
      self.Pos = self.insrc_mx - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos = math.max(self.Pos, 0)
      self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      -------------------
      Wave:Redraw() -- redraw after horizontal zoom
    end
    -----------------------------------------
    --- Wave Zoom(Vertical) -----------------
    if self:mouseIN() and Shift and gfx.mouse_wheel~=0 and not Ctrl then 
     M_Wheel = gfx.mouse_wheel
     -------------------
     if     M_Wheel>0 then self.vertZoom = math.min(self.vertZoom*1.2, self.max_vertZoom)   
     elseif M_Wheel<0 then self.vertZoom = math.max(self.vertZoom*0.8, 1)
     end                 
     -------------------
     Wave:Redraw() -- redraw after vertical zoom
    end
    -----------------------------------------
    --- Wave Move ---------------------------
    if self:mouseM_Down() then 
      self.Pos = self.Pos + (last_x - gfx.mouse_x)/(self.Zoom*Z_w)
      self.Pos = math.max(self.Pos, 0)
      self.Pos = math.min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      --------------------
      Wave:Redraw() -- redraw after move view
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
  gfx.a = 1 -- gfx.a for blit
  -- from gfx buffer 1 -------
  local srcw, srch = Wave.def_xywh[3], Wave.def_xywh[4] -- its always def values 
  gfx.blit(1, 1, 0, 0, 0, srcw, srch,  self.x, self.y, self.w, self.h)
  self:Get_Mouse()     -- get mouse(for zoom,move etc)
  
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
  
  On Waveform Area:
  Mouswheel - Horizontal Zoom,
  Shift+Mouswheel - Vertical Zoom, 
  Middle drag - Move View(Scroll),
  Left click - Set Edit Cursor,
  Shift+Left drag - Move Marker,
  Right click on Marker - Delete Marker,
  Right click on Empty Space - Insert Marker,
  Space - Play. 
  ]]) 
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---   MAIN   ---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function MAIN()
  if Project_Change() then 
     if not Wave:Validate_Accessor() then Wave.State = false end 
  end
  -- Draw Wave, gate lines etc --
  if Wave.State then 
       Wave:from_gfxBuffer() -- Wave from gfx buffer
       Gate_Gl:draw_Lines()  -- Draw Gate lines
  else Wave:show_help()      -- else show help
  end
  -- Draw sldrs, btns etc ---
  draw_controls()
end
------------------------
-- Get Project Change --
------------------------
function Project_Change()
    local cur_cnt = reaper.GetProjectStateChangeCount(0)
    if cur_cnt ~= proj_change_cnt then proj_change_cnt = cur_cnt
       return true  
    end
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
    -- MAIN function --------
    -------------------------
    MAIN() -- main function
    -------------------------
    -------------------------
    last_mouse_cap = gfx.mouse_cap
    last_x, last_y = gfx.mouse_x, gfx.mouse_y
    gfx.mouse_wheel = 0
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
