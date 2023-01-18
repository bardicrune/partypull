# partypull
This Addon for Ashita-v4 is designed to send a message to the party when you pull a mob.  It was inspired and sourced from by Atom0s's checker addon included with the Ashita-v4 beta.

## FFXI commands:
/pull - Checks the targeted entity and sends a message to the party including entity level, difficulty rating, and defense/evasion ratings.

/pull help - Displays a help message.

### Change the audible call used by modifying the pcallnmb variable
0 is the default.  This means no <call#> is attached to the party message and is disabled.
### Change the command used to pull the mob by modifying the pull_str variable
'/ra \<t\>' is the default. Other options could be '/ma "Dia" \<t\>' or '/ja "Provoke" \<t\>'


### Future planned options are to add subcommands to set and store those in a config file.
