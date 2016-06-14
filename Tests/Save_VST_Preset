--[[
   * ReaScript Name: Save_VST_Preset
   * Lua script for Cockos REAPER
   * Author: EUGEN27771
   * Author URI: http://forum.cockos.com/member.php?u=50462
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
--------------------------------------------------------------------------------
-- Decoding function from lua.org ----------------------------------------------
--------------------------------------------------------------------------------
  -- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de> ----------
  -- licensed under the terms of the LGPL2 -------------------------------------
  ------------------------------------------------------------------------------
  -- character table string
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  -- decoding from base64
  function Decode(data)
      data = string.gsub(data, '[^'..b..'=]', '')
      return (data:gsub('.', function(x)
          if (x == '=') then return '' end
          local r,f = '',(b:find(x)-1)
          for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
          return r;
      end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
          if (#x ~= 8) then return '' end
          local c=0
          for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
          return string.char(c)
      end))
  end

--------------------------------------------------------------------------------
-- Base64 to HEX ---------------------------------------------------------------
--------------------------------------------------------------------------------
function B64_to_HEX(line)       
  local BIN  = Decode(line)
  local VAL = { BIN:byte(1,-1) } -- to bytes, values
  local Pfmt = string.rep("%02X", #VAL)
  return string.format(Pfmt, table.unpack(VAL))
end
----------------------------------------
--[[ Name to Hex(not necessarily?) -----
----------------------------------------
function Name_to_Hex(Preset_Name)
  local VAL  = {Preset_Name:byte(1,-1)} -- to bytes, values
  local Pfmt = string.rep("%02X", #VAL)
  local HEX  = string.format(Pfmt, table.unpack(VAL))
  return HEX.."0000000000" -- ???
end
--]]

--------------------------------------------------------------------------------
-- FX_Chunk_to_HEX -------------------------------------------------------------
--------------------------------------------------------------------------------
function FX_Chunk_to_HEX(FX_Chunk, Preset_Name)
  local Preset_Chunk = FX_Chunk:match("\n.*\n")  -- extract preset(simple var)
  local Hex_TB = {}
  local init = 1
  ---------------------
  for i=1, math.huge do 
        line = Preset_Chunk:match("\n.-\n", init) 
        if not line then --[[Hex_TB[i-1] = Name_to_Hex(Preset_Name)--]] -- not necessarily
           break 
        end 
        Hex_TB[i] = B64_to_HEX(line)
        init = init + #line - 1
  end
  ---------------------
  return table.concat(Hex_TB)
end

--------------------------------------------------------------------------------
-- Get_CtrlSum -----------------------------------------------------------------
--------------------------------------------------------------------------------
function Get_CtrlSum(HEX)
  local Sum = 0
  for i=1, #HEX, 2 do  Sum = Sum + tonumber( HEX:sub(i,i+1), 16) end
  return string.sub( string.format("%X", Sum), -2, -1 ) 
end

--------------------------------------------------------------------------------
-- Write preset to PresetFile --------------------------------------------------
--------------------------------------------------------------------------------
function Write_to_File(PresetFile, Preset_HEX, Preset_Name) 
  local file, Presets_ini, Nprsts
  ----------------------------------------------------------
  -- Rewrite header(or create) -----------------------------
  ----------------------------------------------------------
    if reaper.file_exists(PresetFile) then 
        file = io.open(PresetFile, "r")
        Presets_ini = file:read("a")
        file:close()
        ------------------
        Nprsts = tonumber(Presets_ini:match("NbPresets=(%d*)"))
        Presets_ini = Presets_ini:gsub("NbPresets=(%d*)", "NbPresets="..Nprsts+1)
        
        ------------------
    else Nprsts = 0
         Presets_ini = "[General]\nNbPresets="..Nprsts+1
    end 
    ----------------------
    file = io.open(PresetFile, "w")
    file:write(Presets_ini)
    file:close()
  
  ----------------------------------------------------------
  -- Write preset data to file -----------------------------
  ----------------------------------------------------------
  file = io.open(PresetFile, "r+")
  file:seek("end")                        -- to end of file
  ------------------
  file:write("\n[Preset"..Nprsts.."]")    -- preset number(0-based)
  --------------------------------------
  --------------------------------------
  local Len = #Preset_HEX                 -- Data Lenght
  local s = 1
  local Ndata = 0 
  for i=1, math.ceil(Len/32768) do
      if i==1 then Ndata = "\nData=" else Ndata = "\nData_".. i-1 .."=" end   
      local Data = Preset_HEX:sub(s, s+32767)
      local Sum = Get_CtrlSum(Data)
      file:write(Ndata, Data, Sum)
      s = s+32768
  end
  --------------------------------------
  --- Preset_Name, Data Lenght ---------
  --------------------------------------
  file:write("\nName=".. Preset_Name .."\nLen=".. Len//2 .."\n")
  -------------------
  file:close()
end

--------------------------------------------------------------------------------
-- Get FX_Chunk and PresetFile  ------------------------------------------------
--------------------------------------------------------------------------------
function Get_FX_Data(track, fxnum)
  local fx_cnt = reaper.TrackFX_GetCount(track)
  if fx_cnt==0 or fxnum>fx_cnt-1 then return end          -- if fxnum not valid
  local ret, Track_Chunk =  reaper.GetTrackStateChunk(track,"",false)
  --reaper.ShowConsoleMsg(Track_Chunk)
  
    ------------------------------------
    -- Find FX_Chunk(use fxnum) --------
    ------------------------------------
    local s, e = Track_Chunk:find("<FXCHAIN")             -- find FXCHAIN section
    -- find VST(or JS) chunk 
    for i=1, fxnum+1 do
        s, e = Track_Chunk:find("%b<>", e)                    
    end
    ----------------------------------
    -- if FX(fxnum) type ~= "VST" ----
    if Track_Chunk:sub(s+1, s+3)~="VST" then return end   -- Only VST supported
    ----------------------------------
    -- extract FX_Chunk -------------- 
    local FX_Chunk = Track_Chunk:match("%b<>", s)         -- FX_Chunk(simple var)
    ----------------------------------
    --reaper.ShowConsoleMsg(FX_Chunk.."\n")
  
  ------------------------------------
  -- Get UserPresetFile --------------
  ------------------------------------
  local PresetFile = reaper.TrackFX_GetUserPresetFilename(track, fxnum, "")
  ------------------------------------
  return FX_Chunk, PresetFile
end

------------------------------------------------------------
-- Main function  ------------------------------------------
------------------------------------------------------------
function Save_VST_Preset(track, fxnum, Preset_Name)
  if not (track and fxnum and Preset_Name) then return end   --  Need track, fxnum, Preset_Name
  local FX_Chunk, PresetFile = Get_FX_Data(track, fxnum)
  -----------
  if FX_Chunk and PresetFile then 
     local Preset_HEX = FX_Chunk_to_HEX(FX_Chunk, Preset_Name)
     Write_to_File(PresetFile, Preset_HEX, Preset_Name)
     reaper.TrackFX_SetPreset(track, fxnum, Preset_Name) -- For "update", but this is optional
  end
end    

----------------------------------------------------------------------------------------------------
-- TEST --------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--reaper.ClearConsole()
local track = reaper.GetSelectedTrack(0, 0)     -- track(trackID) must be defined in you function ! 
local fxnum = 0                                 -- fxnum must be defined in you function !
local Preset_Name = "New".. math.random(1,1000) -- Name must be defined in you function(always different), for test only !
------------------------- 
-------------------------
Save_VST_Preset(track, fxnum, Preset_Name)      -- RUN TEST !!! 
        
