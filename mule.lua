-- Copyright © 2020, DefrostedTuna
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:

--  * Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
--  * Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
--  * Neither the name of <addon name> nor the
--    names of its contributors may be used to endorse or promote products
--    derived from this software without specific prior written permission.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

_addon.name = 'mule'
_addon.author = 'DefrostedTuna'
_addon.version = '1.0'
_addon.commands = {'mule'}

local packets = require('packets')

---
-- Sets up the outgoing listener for incoming commands.
--
-- @param declaration string  The type of command being issued.
-- @param ...         string  The incoming command string.
--
-- @return void
windower.register_event("addon command", function (declaration, ...)
  if declaration == nil then
    windower.add_to_chat(123, "Mule: No command passed to mule!")
    return
  else
    local command_string = table.concat({...}, ' ')
    issue_command(declaration, command_string)
  end
end)

---
-- Sets up the listener for incoming commands.
--
-- @param msg  string  The incoming command string.
--
-- @return void
windower.register_event('ipc message', function (msg)
  local arguments = split_args(msg)
  local command = table.remove(arguments, 1)

  if command:lower() ~= 'mule' then return end
  if #arguments < 2 then return end

  local declaration = table.remove(arguments, 1)
  local command_string = table.concat(arguments, ' ')
  parse_incoming_command(declaration, command_string)
end)

---
-- Split the arguments into a table by a space. 
--
-- This unfortunately doesn't factor strings like 'Fire V'.
-- Please remove these beforehand until I figure out a way to handle this.
-- LUA doesn't support multiple matches with regex patterns and I'm lazy, so meh.
--
-- @param args  string  The arguments to split.
--
-- @return table
function split_args(args)
  if args == nil then 
    return {}
  end


  local arg_table = {}
  for v in args:gmatch("(%S+)") do
    table.insert(arg_table, v)
  end

  return arg_table
end

---
-- Finds the last sub target of the issuing player.
--
-- @param id  number  The ID of the npc in which to target. 
--
-- @return table|nil
function get_last_sub_target()
  local target = windower.ffxi.get_mob_by_target('lastst')

  if not target then
    return
  end

  return target
end

---
-- Targets the specified mob on the secondary accounts.
--
-- @param id  number  The ID of the npc in which to target.
--
-- @return string
function target_mob(id)
  local player = windower.ffxi.get_player()
  local target = windower.ffxi.get_mob_by_id(id)
  
  if not target then
    return
  end
  
  if target.in_party or target.in_alliance then
    return target.name
  end

  -- This will target the desired mob, although
  -- it will also lock on by default for enemies.
  packets.inject(packets.new('incoming', 0x058, {
    ['Player'] = player.id,
    ['Target'] = target.id,
    ['Player Index'] = player.index,
  }))
  
  -- Stop following.
  -- Else characters will chase their targets.
  windower.ffxi.follow()

  -- Disable lockon sent by the last command if the target
  -- is not a character in the current party or alliance.
  windower.send_command('wait 1; input /lockon')

  return '<t>'
end 

---
-- Extracts the Character, Action, and Target from the command string. 
--
-- @param command_string  string  The string that contains the commands to be issued.
--
-- @return table
function parse_command_arguments(command_string)
    local command_string = command_string

    -- Remove anything that is in quotes. This should be limited to only
    -- actions due to the nature of Character names and targetting limitations.
    -- We must remove these prior to parsing everything as LUA doesn't support
    -- mutiple matches with regex patterns. Laaaaaame!
    local found = string.match(command_string, "'.+'")
    if found ~= nil then
      local expression = found:gsub("(%-)", "%%-") -- Sanitize hyphens.
      command_string = command_string:gsub(expression, '')
    end

    -- Parse the command string into a table.
    local arg_table = split_args(command_string)

    -- Arg Table Keys
    -------------------------------------------------------
    -- 1. Will always be the Character.
    -- 2. Will be the Action. If Action was found previously, 
    --    this will be the Target Instead.
    -- 3. Will be the Target if the Action was not found.
    local character = arg_table[1]
    local action = found and found or arg_table[2]
    local target -- This can be nil and will be used as a check later if so.

    if found and arg_table[2] then
      target = arg_table[2]
    elseif arg_table[3] then
      target = arg_table[3]
    end

    if not character or not action then
      windower.add_to_chat(123, "Mule: Please specify a Character and an Action.")
      return
    end

    return {
      character = character:lower(),
      action = action,
      target = target
    }
end

---
-- Issues Commands to the designated Target. 
--
-- @param declaration     string  The type of Action being performed.
-- @param command_string  string  The string that contains the commands to be issued.
--
-- @return void
function issue_command(declaration, command_string)
  local command_arguments = parse_command_arguments(command_string)

  if command_arguments == nil then return end

  -- This will always result in an ID.
  if command_arguments.target == nil then
    local subtarget = get_last_sub_target()

    if subtarget == nil then 
      windower.add_to_chat(123, "Mule: Unable to find a valid Target.")
      return
    end

    command_arguments.target = subtarget.id
  end

  local command = string.format(
    "mule %s %s %s %s", 
    declaration,
    command_arguments.character,
    command_arguments.action,
    command_arguments.target
  )

  windower.send_ipc_message(command)
end

---
-- Parses the incoming command
---
-- @param declaration     string  The type of Action being performed.
-- @param command_string  string  The string that contains the commands to be issued.
--
-- @return void
function parse_incoming_command(declaration, command_string)
  local command_arguments = parse_command_arguments(command_string)
  local player = windower.ffxi.get_player()
  
  local character = command_arguments.character
  local action = command_arguments.action
  local target = command_arguments.target

  if character == '@all' or character == '@others' or character =='@' .. player.main_job:lower() then
    delegate_command(declaration, action, target)
  elseif character == player['name']:lower() then
    delegate_command(declaration, action, target)
  end
end

---
-- Performs the incoming command
---
-- @param declaration   string      The type of Action being performed.
-- @param action        string      The Action for the Character to perform.
-- @param target        string|nil  The designated Target of the Action.
--
-- @return void
function delegate_command(declaration, action, target)
  local mob_id = tonumber(target)
  local slash_command

  -- If the target is in the party or alliance, simply return the name of the target.
  -- This is useful to prevent targetting issues when locked on to an ememy.
  if mob_id then 
    target = target_mob(mob_id)
  end

  if declaration == 'cast' then
    slash_command = "/ma"
  elseif declaration == 'ability' then
    slash_command = '/ja'
  elseif declaration == 'item' then
    slash_command = '/item'
  end

  if slash_command ~= nil then
    -- If a mob_id was specified, we want to 
    -- set the target to the current target.
    local command_string = string.format(
      "input %s %s %s",
      slash_command,
      action,
      target
    )

    -- If the target needs to be acquired first,
    -- add a delay before issuing the command.
    if mob_id then
      command_string = 'wait 0.5; ' .. command_string
    end

    windower.send_command(command_string)
  end
end