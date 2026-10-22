# starship.toml -> its ssh variant (applied by .bashrc / .zshrc over ssh)
# "PROMPT" block becomes "SSH"
s/ 󰆍 PROMPT / 󰌘 SSH /
# One user@host pill after the OS icon instead of a separate user pill
/^\[\](fg:bright-black)\\$/d
/^\$username\\$/d
s/^\[\](fg:green bg:bright-black)/[](fg:green)/
s/^\$hostname\\$/$username$hostname\\/
s/^format = "\[ \$user \]/format = "[ $user]/
s/^format = "\[ \$hostname \]/format = "[@$hostname ]/
