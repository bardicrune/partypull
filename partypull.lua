addon.name      = 'partypull';
addon.author    = 'bardicrune';
addon.version   = '1.0';
addon.desc      = 'Informs party with advanced info about the target when pulling';
addon.link      = 'https://ashitaxi.com/';

require('common');
local chat = require('chat');

--[[
* Returns the string wrapped in a colored parenthesis.
*
* @param {string} str - The string to wrap.
* @return {string} The wrapped string.
--]]
chat.headerp = function (str)
    return ('\30\81(%s\30\81)\30\01'):fmt(str);
end

-- PartyPull Variables
local partypull = T{
    conditions = T{
        [0xAA] = chat.message('High Evasion, High Defense'),
        [0xAB] = chat.message('High Evasion'),
        [0xAC] = chat.message('High Evasion, Low Defense'),
        [0xAD] = chat.message('High Defense'),
        [0xAE] = '',
        [0xAF] = chat.message('Low Defense'),
        [0xB0] = chat.message('Low Evasion, High Defense'),
        [0xB1] = chat.message('Low Evasion'),
        [0xB2] = chat.message('Low Evasion, Low Defense'),
    },
    types = T{
        [0x40] = chat.color1(67,'too weak to be worthwhile'),
        [0x41] = 'like incredibly easy prey',
        [0x42] = chat.color1(2,'like easy prey'),
        [0x43] = chat.color1(102,'like a decent challenge'),
        [0x44] = chat.color1(8,'like an even match'),
        [0x45] = chat.color1(68,'tough'),
        [0x46] = chat.color1(76,'very tough'),
        [0x47] = chat.color1(76,'incredibly tough'),
    },
    widescan = T{ },
    msg = T{ },
};

partypull_check = 'no'
local pcallnmb = 0
local pull_str = '/ra <t>'

local function print_help(isError)
	-- Print the help header.
	if (isError) then
		print(chat.header(addon.name):append(chat.error('Invalid command syntax for command: ')):append(chat.success('/' .. addon.name)));
	else
		print(chat.header(addon.name):append(chat.message('Available commands:')));
	end
	
	local cmds = T{
		{ '/pull', 'Do the party msg and pull.' };
		{ '/pull help', 'Displays the addons help information.' },
		--Future Improvement ideas
		--{ '/partypull cmd /ra <t>', 'Set the command executed when pulling.' };
		--{ '/partypull call <n>', 'Set the call number inserted into the party chat string. Set to 0 to disable.' };
	};
	
	-- Print the command list.
	cmds:ieach(function (v)
		print(chat.header(addon.name):append(chat.error('Usage: ')):append(chat.message(v[1]):append(' - ')):append(chat.color1(6, v[2])));
	end);
end

local function do_partypull()
	-- Inform party of action
	AshitaCore:GetChatManager():QueueCommand(1, pstr);

	--Perform pulling action
	AshitaCore:GetChatManager():QueueCommand(1, pull_str);
end

ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args();
    if (#args == 0 or args[1] ~= '/pull') then
        return;
    end

    -- Block all related commands..
    e.blocked = true;

    -- Handle: /pull help - Shows the addon help.
    if (#args == 2 and args[2]:any('help')) then
        print_help(false);
        return;
    end
	
	-- Clear previous msg
	partypull.msg:clear();
	
	-- Set flag for check called by this routine
	partypull_check = 'yes'
	
	-- Check if target is a mob
	AshitaCore:GetTargetID()
	-- Perform check of target
	AshitaCore:GetChatManager():QueueCommand(1, '/c <t>');
	return;
end);

--[[
* event: packet_in
* desc : Event called when the addon is processing incoming packets.
--]]
ashita.events.register('packet_in', 'packet_in_cb', function (e)
    -- Packet: Zone Enter / Zone Leave
    if (e.id == 0x000A or e.id == 0x000B) then
        partypull.widescan:clear();
        return;
    end
	
    -- Packet: Message Basic
    if (e.id == 0x0029) then
        local p1    = struct.unpack('l', e.data, 0x0C + 0x01); -- Param 1 (Level)
        local p2    = struct.unpack('L', e.data, 0x10 + 0x01); -- Param 2 (Check Type)
        local m     = struct.unpack('H', e.data, 0x18 + 0x01); -- Message (Defense / Evasion)

        -- Obtain the target entity..
        local target = struct.unpack('H', e.data, 0x16 + 0x01);
        local entity = GetEntity(target);
        if (entity == nil) then
            return;
        end

        -- Ensure this is a /check message..
        if (m ~= 0xF9 and (not partypull.conditions:haskey(m) or not partypull.types:haskey(p2))) then
            return;
        end

		-- Do nothing if not called by /pull
		if (partypull_check == 'no') then
			return;
		end

        -- Obtain the string form of the conditions and type..
        local c = partypull.conditions[m];
        local t = partypull.types[p2];

        -- Obtain the level override if needed..
        if (p1 <= 0) then
            local lvl = partypull.widescan[target];
            if (lvl ~= nil) then
                p1 = lvl;
            end
        end
		
		-- Create party chat string from check
		partypull.msg:append(tostring('/p Pulling -'));
		partypull.msg:append(chat.message(entity.Name));
		partypull.msg:append(chat.color1(82, string.char(0x81, 0xA8)));
		partypull.msg:append(chat.headerp('Lv. ' .. chat.color1(82, p1 > 0 and tostring(p1) or '???')));

		if (m == 0xF9) then
			partypull.msg:append(chat.color1(5, 'Impossible to gauge!'));
		else
			partypull.msg:append(t);
			partypull.msg:append(#c > 0 and c:enclose('\30\81(', '\30\81)\30\01') or c);
		end
		--Add audible alert to party chat
		if (pcallnmb ~= 0 ) then
			partypull.msg:append(tostring('<call' .. pcallnmb .. '>'));
		end
		
		--Set string to global variable
		pstr = (partypull.msg:concat(' '))

        -- Mark the packet as handled..
        e.blocked = true;

		do_partypull();

		-- Unset partypull_check flag
		partypull_check = 'no'
	end
	
    -- Packet: Widescan Results
    if (e.id == 0x00F4) then
        local idx = struct.unpack('H', e.data, 0x04 + 0x01);
        local lvl = struct.unpack('b', e.data, 0x06 + 0x01);

        partypull.widescan[idx] = lvl;
        return;
    end
end);
