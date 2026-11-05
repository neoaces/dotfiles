-- Rex config, migrated from tmux (~/.config/tmux/tmux.conf).
-- Ghostty and Alacritty contributed no key bindings.

-- tmux prefix ctrl+b: pressed twice, send it through to the program.
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })

-- tmux.conf:55-58 arrow-key pane focus
rex.bind("ctrl+b>up", "pane.focus", { direction = "up" })
rex.bind("ctrl+b>down", "pane.focus", { direction = "down" })
rex.bind("ctrl+b>left", "pane.focus", { direction = "left" })
rex.bind("ctrl+b>right", "pane.focus", { direction = "right" })

-- tmux.conf:61-64 vim-style pane focus
rex.bind("ctrl+b>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+b>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+b>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+b>l", "pane.focus", { direction = "right" })
