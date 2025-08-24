# 🚀 escape-hatch.nvim

**The escalating escape system for Neovim**

More escapes = more final actions. A beautifully intuitive keybinding system that scales with your urgency level.

## ✨ Features

- **Intuitive escalation**: The more escapes you press, the more "final" the action
- **Universal**: Works across all modes (normal, insert, visual, terminal)  
- **Safe by default**: Destructive actions require more deliberate keypresses
- **Configurable**: Enable/disable levels, customize commands, add confirmations
- **No conflicts**: Preserves all built-in Vim behaviors

## 🎯 The Escalation System

| Escapes | Action | Description |
|---------|--------|-------------|
| **1** | Built-in | Clear search highlight / Exit mode |
| **2** | Save | Save file / Exit terminal mode |
| **3** | Save & Quit | Save current file and close it |
| **4** | Quit | Close current file (with unsaved warning) |
| **5** | Quit All | Close all files (with unsaved warnings) |
| **6** | Nuclear 🔥 | Force quit everything, discard all changes |

## 📦 Installation

### With [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
  "your-username/escape-hatch.nvim",
  config = function()
    require("escape-hatch").setup()
  end
}
```

### With [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
  "your-username/escape-hatch.nvim",
  config = function()
    require("escape-hatch").setup()
  end
}
```

## ⚙️ Configuration

```lua
require("escape-hatch").setup({
  -- Enable/disable specific escape levels
  enable_2_esc = true,   -- Save / Exit terminal
  enable_3_esc = true,   -- Save & quit
  enable_4_esc = true,   -- Quit (safe)
  enable_5_esc = true,   -- Quit all (safe)
  enable_6_esc = false,  -- Nuclear option (disabled by default for safety)
  
  -- Custom commands (optional)
  commands = {
    save = ":w<CR>",
    save_quit = ":wq<CR>",
    quit = ":q<CR>",
    quit_all = ":qa<CR>",
    force_quit_all = ":qa!<CR>",
    exit_terminal = "<C-\\><C-n>"
  },
  
  -- Custom descriptions
  descriptions = {
    level_2 = "Save / Exit terminal",
    level_3 = "Save & Quit", 
    level_4 = "Quit",
    level_5 = "Quit All",
    level_6 = "Force Quit All"
  }
})
```

## 🚦 Safety First

**Level 5** uses `:qa` which safely prompts you before closing files with unsaved changes.

The **nuclear option** (6 escapes) uses `:qa!` and is **disabled by default** because it immediately force quits everything without any confirmation or protection.

To enable the nuclear option:
```lua
require("escape-hatch").setup({
  enable_6_esc = true  -- ⚠️ Will force quit without any confirmation!
})
```

## 🛠️ Utility Functions

```lua
-- Show current configuration
:lua require("escape-hatch").show_config()

-- Toggle nuclear option on/off
:lua require("escape-hatch").toggle_nuclear()
```

## 💡 Philosophy

Traditional Neovim configs scatter save/quit commands across random keybindings:
- `<C-s>` for save
- `<leader>w` for save  
- `<leader>q` for quit
- `:wq` for save & quit

**escape-hatch.nvim** creates a unified, escalating system:
- **Predictable**: Same key, different repetition counts
- **Memorable**: Impossible to forget the pattern
- **Scalable**: Easy to extend with more levels
- **Logical**: More escapes = more final actions

## 🎨 Examples

```lua
-- Minimal setup (recommended)
require("escape-hatch").setup()

-- Conservative setup (no nuclear option)  
require("escape-hatch").setup({
  enable_6_esc = false
})

-- Power user setup (nuclear enabled - no confirmation!)
require("escape-hatch").setup({
  enable_6_esc = true  -- ⚠️ Dangerous!
})

-- Custom commands
require("escape-hatch").setup({
  commands = {
    save = ":update<CR>",  -- Only save if buffer was modified
    quit_all = ":qall<CR>" -- Alternative to :qa
  }
})
```

## 🤝 Contributing

This plugin was born from a conversation about intuitive keybindings. If you have ideas for improvements or find the system useful, contributions are welcome!

## 📄 License

MIT

---

**"More escapes = more final"** - The escape-hatch philosophy
