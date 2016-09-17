--[[
   * ReaScript Name:Create stretch-markers at transients
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.01
  ]]
 
-- Script creates stretch-markers at transients --

--------------------------------------------------------------------------------
---   Simple Element Class   ---------------------------------------------------
--------------------------------------------------------------------------------
local Element = {}
function Element:new(x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val,norm_val2, fnt_rgba)
    local elm = {}
    elm.def_xywh = {x,y,w,h,fnt_sz} -- its default coord,used for Zoom etc
    elm.x, elm.y, elm.w, elm.h = x, y, w, h
    elm.r, elm.g, elm.b, elm.a = r, g, b, a
    elm.lbl, elm.fnt, elm.fnt_sz  = lbl, fnt, fnt_sz
    elm.fnt_rgba = fnt_rgba or {0.7,0.8,0.4,1} --0.7, 0.8, 0.4, 1
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
  self.x, self.w = math.ceil(self.def_xywh[1]* Z_w) , math.ceil(self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = math.ceil(self.def_xywh[2]* Z_h) , math.ceil(self.def_xywh[4]* Z_h) -- upd y,h
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
------------------------
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
  gfx.rect(x, y, w, h, false)            -- frame1
  gfx.roundrect(x, y, w-1, h-1, 3, true) -- frame2         
end


----------------------------------------------------------------------------------------------------
---   Create Element Child Classes(Button,Slider,Knob)   -------------------------------------------
----------------------------------------------------------------------------------------------------
local Button, Slider, Rng_Slider, Knob, CheckBox, Frame = {},{},{},{},{},{}
  --extended(Button,     Element)
  --extended(Knob,       Element)
  extended(Slider,     Element)
    -- Create Slider Child Classes --
    local H_Slider, V_Slider = {},{}
    extended(H_Slider, Slider)
    --extended(V_Slider, Slider)
    ---------------------------------
  --extended(Rng_Slider, Element)
  --extended(Frame,      Element)
  --extended(CheckBox,   Element)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Slider Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Slider:set_norm_val_m_wheel()
    local Step = 0.05 -- Set step
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = math.min(self.norm_val+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = math.max(self.norm_val-Step, 0) end
    return true
end
--------
function H_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Ctrl then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    self.norm_val=VAL
end
--------
function H_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw H_Slider body
end
--------
function H_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw H_Slider label
end
--------
function H_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw H_Slider Value
end
------------------------
function Slider:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.1
             --if self:set_norm_val_m_wheel() then 
                --if self.onMove then self.onMove() end 
             --end  
          end
          -- in elm L_down -----
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
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end


---------------------------------------------------------------------------------------------
-- Create Sliders ---------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------------------
-- Sliders ---------------------------------------
--------------------------------------------------
local Thresh = H_Slider:new(10,10,260,18, 0.5,0.5,0.5,0.3, "Threshold dB", "Arial",15, 0.6 )
function Thresh:draw_val()
  self.form_val = -60 + self.norm_val*60  -- form value
  self.form_val = math.floor(self.form_val/0.2)*0.2
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.2f", self.form_val)
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end

---------------
local Sens = H_Slider:new(10,30,260,18, 0.5,0.5,0.5,0.3, "Sensetivity dB", "Arial",15, 0.25 )
function Sens:draw_val()
  self.form_val = self.norm_val*18  -- form value
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.2f", self.form_val)
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end

---------------
local Retrig = H_Slider:new(10,50,260,18, 0.5,0.5,0.5,0.3, "Retrig ms", "Arial",15, 0 )
function Retrig:draw_val()
  self.form_val = 20+ math.floor(self.norm_val*430)
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.2f", self.form_val)
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end

--------------------------------------------------
-- controls functions ----------------------------
--------------------------------------------------
function onUp_Main()
  RunMain = true
end
---------------
Sens.onUp   = onUp_Main
Thresh.onUp = onUp_Main  
Retrig.onUp = onUp_Main
---------------
local Slider_TB   = { Thresh, Sens, Retrig}



--------------------------------------------------------------------------------
---  Simple Detect Transients Function  ----------------------------------------
--------------------------------------------------------------------------------
function DetectTransients(item, srate, Threshold_dB, Sensitivity_dB, Retrig_sec)
      
      -- Threshold, Sensitivity, Retrig to norm values ---
      local Threshold, Sensitivity, Retrig
      Threshold    = 10^(Threshold_dB/20)          -- Threshold_dB - to norm value
      Sensitivity  = 10^(Sensitivity_dB/20)        -- Sensitivity_dB - to norm value
      Retrig       = math.floor(Retrig_sec*srate)  -- Retrig_sec - to samples
   
      -- Envelopes Attack, Release Time ---------------
      local attTime1, relTime1, attTime2, relTime2   
      attTime1 = 0.001         -- Env1(fast) attack(sec)
      relTime1 = 0.010         -- Env1(fast) release(sec)
      attTime2 = 0.007         -- Env2(slow) attack(sec)
      relTime2 = 0.015         -- Env2(slow) release(sec)

      -- Compute sample frequency related coeffs ------ 
      local ga1, gr1, ga2, gr2   
      ga1 = math.exp(-1/(srate*attTime1))  -- attack1 coeff
      gr1 = math.exp(-1/(srate*relTime1))  -- release1 coeff
      ga2 = math.exp(-1/(srate*attTime2))  -- attack2 coeff
      gr2 = math.exp(-1/(srate*relTime2))  -- release2 coeff

      -- Init some values -----------------------------
      local last_trig_smpl, envOut1, envOut2  
      envOut1 = 0  -- Peak envelope1 follower start value
      envOut2 = 0  -- Peak envelope2 follower start value

        -- Item, take data -------------------------------
        local take, playrate, item_len, item_len_smpls
        take = reaper.GetActiveTake(item); 
        playrate  = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE"); --// get orig playrate
        item_len  = reaper.GetMediaItemInfo_Value(item, "D_LENGTH" );
        item_len_smpls = math.floor(item_len*srate);
     
        --------------------------------------------------
        local AA, samplebuffer, starttime_sec, n_blocks 
        AA = reaper.CreateTakeAudioAccessor(take);
        samplebuffer = reaper.new_array(65536) -- buffer
        starttime_sec = 0;
        n_blocks = math.ceil(item_len_smpls/65536);
        
        -- Detect Transients -----------------------------
        local abs = math.abs    -- abs function
        local retrig_cnt = 0
        for b = 1, n_blocks do  
            reaper.GetAudioAccessorSamples(AA, srate, 1, starttime_sec, 65536, samplebuffer);
        
              for smpl = 1, 65536 do
                  input = abs(samplebuffer[smpl]) -- abs sample value(abs envelope)
                  
                  -- Envelope1(fast) ------------------------
                  if envOut1 < input then envOut1 = input + ga1*(envOut1 - input) 
                     else envOut1 = input + gr1*(envOut1 - input)
                  end
                  -- Envelope2(slow) ------------------------
                  if envOut2 < input then envOut2 = input + ga2*(envOut2 - input)
                     else envOut2 = input + gr2*(envOut2 - input)
                  end
                  
                  -- Trigger -------------------------------- 
                  if retrig_cnt > Retrig then
                      if envOut1>Threshold and (envOut1/envOut2) > Sensitivity then
                          local mrk_pos = starttime_sec + smpl/srate;        -- Calculate mrk pos
                          reaper.SetTakeStretchMarker(take, -1, mrk_pos); -- Insert marker
                          retrig_cnt = 0;            
                      end
                    else envOut2 = envOut1; retrig_cnt = retrig_cnt+1 -- уравнивает огибающие, пока триггер неактивен(здесь важно)
                  end
                          
              end
            
            starttime_sec = starttime_sec+65536/srate; -- To next block
        end
        -----------------------------------------------------------------
    
    reaper.DestroyAudioAccessor(AA);
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", playrate); -- restore orig playrate
    reaper.UpdateTimeline()

end

-------------------------------------------------------------------------------------------------
function MAIN()
   local item, srate, Threshold_dB, Sensitivity_dB, Retrig_sec     
    item = reaper.GetSelectedMediaItem(0, 0);
    if item then 
        -- Detection setting(form values) --//
        srate = 44100;
        Threshold_dB   = Thresh.form_val; 
        Sensitivity_dB = Sens.form_val;
        Retrig_sec     = Retrig.form_val/1000;
        reaper.Main_OnCommand(41844, 0);  --remove old str-marks(All)
        srate = 44100;
        -----------------------------------------------------------------    
        start = reaper.time_precise();
        DetectTransients(item, srate, Threshold_dB, Sensitivity_dB, Retrig_sec);
        reaper.ShowConsoleMsg(reaper.time_precise()-start .."\n")
    end

end


--------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
---   Main DRAW function   -------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function DRAW()
    for key,sldr    in pairs(Slider_TB)   do sldr:draw()   end
end

--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
    -- Some gfx Wnd Default Values --
    local R,G,B = 25,25,25               -- 0..255 form
    local Wnd_bgd = R + G*256 + B*65536  -- red+green*256+blue*65536  
    local Wnd_Title = "Create stretch-markers at transients(lua)"
    local Wnd_Dock,Wnd_X,Wnd_Y = 0,200,420
    Wnd_W,Wnd_H = 280,80 -- global values(used for define zoom level)
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
    if gfx.mouse_cap&1==1   and last_mouse_cap&1==0  or   -- L mouse
       gfx.mouse_cap&2==2   and last_mouse_cap&2==0  or   -- R mouse
       gfx.mouse_cap&64==64 and last_mouse_cap&64==0 then -- M mouse
       mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y 
    end
    Ctrl  = gfx.mouse_cap&4==4
    Shift = gfx.mouse_cap&8==8
    Alt   = gfx.mouse_cap&16==16 -- Shift state
    -------------------------
    -- DRAW,MAIN functions --
      DRAW(); -- Main()
      if RunMain==true then MAIN();RunMain=false end 
    -------------------------
    -------------------------
    last_mouse_cap = gfx.mouse_cap
    last_x, last_y = gfx.mouse_x, gfx.mouse_y
    gfx.mouse_wheel = 0 -- reset gfx.mouse_wheel 
    char = gfx.getchar()
    if char==32 then reaper.Main_OnCommand(40044, 0) end -- play 
    if char~=-1 then reaper.defer(mainloop) end          -- defer
    -----------  
    gfx.update()
    -----------
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------
RunMain=true
Init()
mainloop()
