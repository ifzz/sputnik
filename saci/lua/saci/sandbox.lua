
module(...,package.seeall)

local Sandbox = {}
local Sandbox_mt = {__metatable = {}, __index = Sandbox}

function new(initial_values)
   local sandbox = setmetatable({}, Sandbox_mt)
   local value_mt = setmetatable({__index=initial_values}, initial_values)
   sandbox.values = setmetatable({}, value_mt)
   sandbox.returned_value = nil
   return sandbox
end

function Sandbox:add_values(symbol_table)
   for symbol, value in pairs(symbol_table) do
      self.values[symbol] = value
   end
end
   
function Sandbox:do_lua(lua_code)

   local f, err = loadstring(lua_code)      -- load the code into a function
   if f then 
      setfenv(f, self.values or {})         -- set a restricted environment
      self.returned_value, err = pcall(f)   -- run it
   end
     
   if err then                              -- check if something went wrong
      local error_report = {}
      local reg_exp = "^.+%]%:(%d+)%:"
      error_report.line_num = string.match(err, reg_exp)
      error_report.errors = string.gsub(err, reg_exp, "On line %1:")
      error_report.source = lua_code
      error_report.err = err
           
      if self.logger then
         self.logger:error("sputnik.luaenv: couldn't execute lua")
         self.logger:error("Source code: \n"..error_report.source)
         self.logger:error("environment: \n")
         for k,v in pairs(self.values) do
            self.logger:error(string.format("%s=%q", tostring(k), tostring(v)))
         end
         self.logger:error(err)
      end
      return nil, error_report
   else
      self.values = getfenv(f)         -- save the values
      return self.values               -- return them
   end
end

