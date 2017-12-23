--[[
   * Description: TestScript
   * Author: EUGEN27771
   * Version: 1.03
   * Provides: 
        Modules/*.{lua}
        Images/*.{png}
--]]

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
require "Modules.Module1"
require "Modules.Module2"

-- Provides: Modules/*.{lua} >> reapack-index - OK!

-- Provides: Images/*.{lua} >> reapack-index - OK!
