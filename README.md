# partypull
This Addon for Ashita-v4 is designed to send a message to the party when you pull a mob.  It was inspired and sourced from by Atom0s's checker addon included with the Ashita-v4 beta.

## FFXI commands:
/pull - Checks the targeted entity and sends a message to the party including entity level, difficulty rating, and defense/evasion ratings.

/pull cmd [type] [ability/spell] - Set the command executed when pulling.
* [type] - ra, ma, or ja
* [ability/spell] - Place multi-word spells or abilities in double-quotes
* Ex. - /pull cmd ra
* Ex. - /pull cmd ma "Bio II"
* Ex. - /pull cmd ja provoke
/pull call \<n\> - Set the call number inserted into the party chat string. Set to 0 to disable.

/pull help - Displays this help message.

## Future Development
* Check that \<t\> is a mob before attempting the check to get information.  Currently it runs a /check no matter what and will check players or give an error if no target is selected.
* Check that the spell/ability is valid for the player before saving command to be executed.
* Possibly add job level settings for different commands per job.