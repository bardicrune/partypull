addon.name      = 'PartyPull';
addon.author    = 'bardicrune';
addon.version   = '2.0.0';
addon.desc      = 'Informs party with advanced info about the target when pulling';
addon.link      = 'https://github.com/bardicrune/partypull';

require('common');
local chat = require('chat');
local settings = require('settings');

--[[
* Returns the string wrapped in a colored parenthesis.
*
* @param {string} str - The string to wrap.
* @return {string} The wrapped string.
--]]
chat.headerp = function (str)
    return ('\30\81(%s\30\81)\30\01'):fmt(str);
end

-- Default Settings
local default_settings = T{
    user = T{
        pull_str = '/ra <t>',
		pcallnmb = 99,
		callprefix = 'c',
		jobcmd = T{
			WAR = ' ',
			MNK = ' ',
			WHM = ' ',
			BLM = ' ',
			RDM = ' ',
			THF = ' ',
			PLD = ' ',
			DRK = ' ',
			BST = ' ',
			BRD = ' ',
			RNG = ' ',
			SMN = ' ',
			SAM = ' ',
			NIN = ' ',
			DRG = ' ',
			BLU = ' ',
			COR = ' ',
			PUP = ' ',
			DNC = ' ',
			SCH = ' ',
			GEO = ' ',
			RUN = ' ',
		},
    },
};

-- PartyPull Variables
local partypull_check = 'no'
local pstr = ' '
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
	user = T{ },
	settings = settings.load(default_settings),
};

--[[
* Updates the addon settings.
*
* @param {table} s - The new settings table to use for the addon settings. (Optional.)
--]]
local function update_settings(s)
    -- Update the settings table..
    if (s ~= nil) then
        partypull.settings = s;
    end

    -- Save the current settings..
    settings.save();
end

--[[
* Registers a callback for the settings to monitor for character switches.
--]]
settings.register('settings', 'settings_update', update_settings);

local function print_help(isError)
	-- Print the help header.
	if (isError) then
		print(chat.header(addon.name):append(chat.error('Invalid command syntax for command: ')):append(chat.success('/' .. addon.name)));
	else
		print(chat.header(addon.name):append(chat.message('Note: ')):append(chat.color1(6, 'Disable \'checker\' addon to prevent multiple messages during a /check')));
		print(chat.header(addon.name):append(chat.message('Available commands:')));
	end
	
	local cmds = T{
		{ '/pull', 'Send the party message and pull.' },
		{ '/pull cmd [type] [ability/spell]', 'Set the command to be executed for the current job when pulling.'},
		{ '    [type]', 'Can be ra, ma, ja, disable, or custom'},
		{ '    [ability/spell]', 'Place multi-word spells, abilities or custom commands in double-quotes'},
		{ '  Ex.', '/pull cmd ma \"Bio II\"' },
		{ '  Ex.', '/pull cmd ja Provoke' },
		{ '  Ex.', '/pull cmd custom \"/exec macro.txt\"' },
		{ '/pull call <#>', 'Set the call number inserted into the party chat string. Set to 99 to disable.' },
		{ '/pull callprefix <s,n,c>', 'Set the call type to scall, ncall, or call' },
		{ '/pull help', 'Displays this help information.' },
	};
	
	-- Print the command list.
	cmds:ieach(function (v)
		print(chat.header(addon.name):append(chat.error('Usage: ')):append(chat.message(v[1]):append(' - ')):append(chat.color1(6, v[2])));
	end);
end

local function do_partypull()
	local mainjobid = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
	local MainJob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", mainjobid);
	--print (chat.header(addon.name):append(tostring(MainJob)));
	--Perform pulling action
	if (partypull.settings.user.jobcmd[MainJob] ~= ' ' ) then
		if (partypull.settings.user.jobcmd[MainJob] ~= 'disable') then
			--print(chat.header(addon.name):append(tostring('before pull cmd')));
			AshitaCore:GetChatManager():QueueCommand(1, partypull.settings.user.jobcmd[MainJob]);
		end
	else
		if (partypull.settings.user.pull_str ~= 'disable') then
			--print(chat.header(addon.name):append(tostring('before pull cmd')));
			AshitaCore:GetChatManager():QueueCommand(1, partypull.settings.user.pull_str);
		end
	end
	coroutine.sleep(0.1);
	
	-- Inform party of action
	--print(chat.header(addon.name):append(tostring('before pchat msg')));
	AshitaCore:GetChatManager():QueueCommand(1, pstr);
	return;
end

ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args();
	if (#args == 0) then
		return;
	end
	if (args[1] ~= '/pull' and args[1] ~= '/partypull' and args[1] ~= '/pp') then
        return;
    end

    -- Block all related commands..
    e.blocked = true;

    -- Handle: /pull help - Shows the addon help.
    if (#args == 2 and args[2]:any('help')) then
        print_help(false);
        return;
    end
	
	if (#args > 1 and args[2]:any('cmd')) then
		if (#args == 2) then
			print(chat.header(addon.name):append(chat.error('Type must be provided.')));
			return;
		end
		local mainjobid = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
		local MainJob = AshitaCore:GetResourceManager():GetString("jobs.names_abbr", mainjobid);
		if (partypull.settings.user.jobcmd[MainJob] ~= ' ' ) then
			print(chat.header(addon.name):append('Old pull command: '):append(tostring(partypull.settings.user.jobcmd[MainJob])));
		else
			print(chat.header(addon.name):append('Old pull command: '):append(tostring(partypull.settings.user.pull_str)));
		end
		if (args[3]:any('show')) then
			return;
		end
		if (args[3]:any('disable')) then
			partypull.settings.user.jobcmd[MainJob] = 'disable'
		end
		if (args[3]:any('custom')) then
			partypull.settings.user.jobcmd[MainJob] = args[4]
		end
		if (args[3]:any('ra')) then
			partypull.settings.user.jobcmd[MainJob] = '/ra <t>'
		end
		if (args[3]:any('ma')) then
			if (args[4] ~= nil) then
				local spell = AshitaCore:GetResourceManager():GetSpellByName(args[4], 0)
				--print(chat.header(addon.name):append(tostring(spell)));
				if (spell == nil) then
					print(chat.header(addon.name):append(chat.error('Spell ' .. args[4] .. ' is not valid.  Check your spelling.')));
					return;
				end
				local spellindex = spell.Index
				--print(chat.header(addon.name):append(tostring(spellindex)));
				local hasspell = AshitaCore:GetMemoryManager():GetPlayer():HasSpell(spellindex)
				--print(chat.header(addon.name):append(tostring(hasspell)));
				if (hasspell == true) then
					partypull.settings.user.jobcmd[MainJob] = '/ma \"' + args[4] + '\" <t>'
				else
					print(chat.header(addon.name):append(chat.error('Player does not have access to spell.')));
					return;
				end
			else
				print(chat.header(addon.name):append(chat.error('Spell name must be provided.')));
				return;
			end
		end
		if (args[3]:any('ja')) then
			if (args[4] ~= nil) then
				local ability = AshitaCore:GetResourceManager():GetAbilityByName(args[4], 0)
				--print(chat.header(addon.name):append(tostring(ability)));
				if (ability == nil) then
					print(chat.header(addon.name):append(chat.error('Ability ' .. args[4] .. ' is not valid.  Check your spelling.')));
					return;
				end
				local abilityid = ability.Id
				--print(chat.header(addon.name):append(tostring(abilityid)));
				local hasability = AshitaCore:GetMemoryManager():GetPlayer():HasAbility(abilityid)
				--print(chat.header(addon.name):append(tostring(hasability)));
				if (hasability == true) then
					partypull.settings.user.jobcmd[MainJob] = '/ja \"' + args[4] + '\" <t>'
				else
					print(chat.header(addon.name):append(chat.error('Player does not have access to ability.')));
					return;
				end
			else
				print(chat.header(addon.name):append(chat.error('Ability name must be provided.')));
				return;
			end
		end
		update_settings();
		print(chat.header(addon.name):append('New pull command: '):append(tostring(partypull.settings.user.jobcmd[MainJob])));
		return;
	end
	
	if (#args == 3 and args[2]:any('call')) then
		if tonumber(args[3]) then
			partypull.settings.user.pcallnmb = args[3]
			update_settings();
		else
			print(chat.header(addon.name):append('Value must be numeric.'));
		end
		return;
	end
	
	if (#args == 3 and args[2]:any('callprefix')) then
		if (args[3] == 'c' or args[3] == 's' or args[3] == 'n') then
			partypull.settings.user.callprefix = args[3]
			update_settings();
		else
			print(chat.header(addon.name):append(tostring('Value must be s, n, or c')));
		end
		return;
	end
	if (#args == 1) then
		-- Check if target is a mob
		local TI = AshitaCore:GetMemoryManager():GetTarget():GetTargetIndex(0)
		--print(chat.header(addon.name):append(TI));
		--better logic to detect if mob vs other entity (detects dynamic index mobs)
		if (bit.band(AshitaCore:GetMemoryManager():GetEntity():GetSpawnFlags(TI), 0x10) ~= 0) then
			-- Set flag for check called by this routine
			partypull_check = 'yes'
			--print(chat.header(addon.name):append(tostring('IsMonster')));
			-- Perform check of target
			AshitaCore:GetChatManager():QueueCommand(1, '/c <t>');
		end

	end
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

		-- Clear previous msg
		partypull.msg:clear();
		pstr = ' '

		-- Create chat string from check
		-- Build basic chat check message if not called by /pull
		if (partypull_check == 'no') then
			partypull.msg:append(chat.header(addon.name) - 1);
		else
			-- Check for party membership
			local partychk = AshitaCore:GetMemoryManager():GetParty():GetMemberIsActive(1)
			--print(chat.header(addon.name):append(tostring(partychk)));
			if (partychk == 0) then
				partypull.msg:append(tostring('/echo Pulling -'));
			else
				partypull.msg:append(tostring('/p Pulling -'));
			end
		end

		
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
		local calltype = 'call'
		if (partypull.settings.user.callprefix == 's') then
			calltype = 'scall'
		elseif (partypull.settings.user.callprefix == 'n') then
			calltype = 'ncall'
		end
		if (partypull.settings.user.pcallnmb ~= '99' and partypull_check == 'yes' and partychk == 0) then
			partypull.msg:append(tostring('<' .. calltype .. partypull.settings.user.pcallnmb .. '>'));
		end
		
		-- Set partypull.msg to variable defined in main
		pstr = (partypull.msg:concat(' '))

        -- Mark the packet as handled..
        e.blocked = true;

		if (partypull_check == 'no') then
			print(pstr);
		else
			do_partypull();
			-- Unset partypull_check flag
			partypull_check = 'no'
		end
	end
	
    -- Packet: Widescan Results
    if (e.id == 0x00F4) then
        local idx = struct.unpack('H', e.data, 0x04 + 0x01);
        local lvl = struct.unpack('b', e.data, 0x06 + 0x01);

        partypull.widescan[idx] = lvl;
        return;
    end
end);
