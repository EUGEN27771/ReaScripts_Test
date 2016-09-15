--[[
   * ReaScript Name:DetectTransients
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.0
  ]]

--[[
  ------------------
  samplebuffer    -- The input samples array(lua or reaper.array).
    Note: It is recommended to use a Lua-array("list") - is much faster much faster than reaper.array.
    For example, if you have reaper.array - use samplebuffer = samplebuffer.table() before the function call.
    Операции с массивом lua быстрее почти в два раза, это особенно важно для длинных массивов.
    Поэтому лучше использовать массив lua!!!
  -------
  srate           -- samplerate - (for example 44100; 48000; 96000 etc). 
  Threshold_dB    -- Threshold in db(for example -24.01; -12.47 etc). The threshold for a fast envelope(not input samples!)
  Sensitivity_dB  -- Min diff between the fast and slow envelope. The smaller the value - more the detected transients. 
  Retrig_sec      -- Time of inactivity after the last trig in seconds.
  -------
  Optional(if not specified - default values will be used):      
    attTime1,relTime1 -- fast envelope attack, release(атакa и релиз быстрой огибающей)
    attTime2,relTime2 -- slow envelope attack, release(атакa и релиз медленной огибающей)
  ------------------
  The function returns a table with the positions of the transients(in samples).
--]]


--------------------------------------------------------------------------------
---  Simple Detect Transients Function  ----------------------------------------
--------------------------------------------------------------------------------
function DetectTransients(samplebuffer, srate, Threshold_dB, Sensitivity_dB, Retrig_sec, attTime1,relTime1, attTime2,relTime2)
      if not(samplebuffer and srate and Threshold_dB and 
             Sensitivity_dB and Retrig_sec) then return 
      end
      -------------------------------------------------
      local Trans_Points = {}  -- Transient-Points table 
      -------------------------------------------------
      -- Threshold, Sensitivity -----------------------
      local gain_scale   = 1        -- Можно использувать для масштабирования(при необходимости), default = 1(not scaling)
      local Threshold    = 10^(Threshold_dB/20)/gain_scale -- Threshold_dB - to norm value
      local Sensitivity  = 10^(Sensitivity_dB/20)          -- Sensitivity_dB - to norm value
      local Retrig_smpls = math.floor(Retrig_sec*srate)    -- Retrig_sec - to samples
      -------------------------------------------------      
      -- Envelopes Attack, Release Time ---------------
      local attTime1 = attTime1 or 0.001         -- Env1(fast) attack(sec)
      local relTime1 = relTime1 or 0.010         -- Env1(fast) release(sec)
      local attTime2 = attTime2 or 0.007         -- Env2(slow) attack(sec)
      local relTime2 = relTime2 or 0.015         -- Env2(slow) release(sec)
      -------------------------------------------------
      -- Compute sample frequency related coeffs ------ 
      local ga1 = math.exp(-1/(srate*attTime1))  -- attack1 coeff
      local gr1 = math.exp(-1/(srate*relTime1))  -- release1 coeff
      local ga2 = math.exp(-1/(srate*attTime2))  -- attack2 coeff
      local gr2 = math.exp(-1/(srate*relTime2))  -- release2 coeff
      -------------------------------------------------
      -- Init some values -----------------------------
      local last_trig_smpl  = - Retrig_smpls  -- last trig start value!
      local envOut1 = samplebuffer[1]  -- Peak envelope1 follower start value
      local envOut2 = envOut1          -- Peak envelope2 follower start value
      
        -----------------------------------------------------------------
        -- Detect Transients --------------------------------------------
        -----------------------------------------------------------------
        local abs = math.abs
        for i = 1, #samplebuffer, 1 do
            local input = abs(samplebuffer[i]) -- abs sample value(abs envelope)
            
            -- Envelope1(fast) ------------------------
            if envOut1 < input then envOut1 = input + ga1*(envOut1 - input) 
               else envOut1 = input + gr1*(envOut1 - input)
            end
            -- Envelope2(slow) ------------------------
            if envOut2 < input then envOut2 = input + ga2*(envOut2 - input)
               else envOut2 = input + gr2*(envOut2 - input)
            end
            
            -- Trigger -------------------------------- 
            if (i - last_trig_smpl) > Retrig_smpls then
                if envOut1>Threshold and (envOut1/envOut2) > Sensitivity then
                   Trans_Points[#Trans_Points+1] = i  -- store current point
                   last_trig_smpl = i                 -- last trig point             
                end
              else envOut2 = envOut1 -- уравнивает огибающие, пока триггер неактивен(здесь важно)
            end
                    
        end
        -----------------------------------------------------------------
  -------------------
  return Trans_Points
end
