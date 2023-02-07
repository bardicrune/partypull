# partypull
This Addon for Ashita-v4 is designed to send a message to the party when you pull a mob.  It was inspired by and sourced from Atom0s's checker addon included with the Ashita-v4 beta.

## FFXI commands:
* /pull or /partypull or /pp - Checks the targeted entity and sends a message to the party including entity level, difficulty rating, and defense/evasion ratings.
* /pull cmd [type] [ability/spell] - Set the command executed when pulling.
* * [type] - Can be ra, ma, ja, disable, or custom
* * [ability/spell] - Place multi-word spells, abilities or custom commands in double-quotes
* * Ex. - /pull cmd ra
* * Ex. - /pull cmd ma "Bio II"
* * Ex. - /pull cmd ja provoke
* * Ex. - /pull cmd custom "/exec macro.txt"
* /pull call \<#\> - Set the call number inserted into the party chat string. Set to 99 to disable.
* /pull callprefix \<s,n,c\> - Set the call type to scall, ncall, or call
* /pull help - Displays this help message.

## Note:
* Disable the 'checker' addon to prevent unwanted and additional /check messages.

## Future Development
* Possibly add job level settings for different commands per job.
* Possibly add config gui (imgui) for simpler configuration.
