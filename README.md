# 🚀 escape-hatch.nvim

**The escalating escape system for Neovim**

An intuitive keybinding system that scales with your urgency level.

> **Finally! A way to quit Vim that doesn't require a Stack Overflow search.** 
> 
> We've all been there: trapped in Vim, mashing keys, trying `:exit`, `:leave`, `:please-let-me-out`. Those days are over. Now you just press Escape until you're free. The more desperate you get, the more escapes you press, and eventually you'll break free. It's like a panic button that scales with your panic level.

## ✨ Features

- **Mode agnostic**: Every escape level works from any mode (insert, visual, terminal, normal)
- **Additive escalation**: Each level builds on the previous one consistently
- **Universal escape**: Level 1 handles all "get me out" scenarios
- **Safe by default**: Destructive actions require more deliberate keypresses
- **Smart context**: Automatically handles Telescope, LSP floats, and UI windows
- **Configurable**: Enable/disable levels, customize commands
- **No conflicts**: Enhances built-in Vim behaviors without breaking them

## 🎯 The Escalation System

| Escapes | Action | Description |
|---------|--------|-------------|
| **1** | Escape | Exit mode + Clear search + Close floating windows |
| **2** | Escape + Save | Level 1 + Save current file |
| **3** | Escape + Save + Quit | Level 2 + Close current file |
| **4** | Escape + Quit | Level 1 + Close file (with unsaved warning) |
| **5** | Escape + Quit All | Level 1 + Close all files (with unsaved warnings) |
| **6** | Escape + Nuclear 🔥 | Level 1 + Force quit everything, discard changes |

## 📦 Installation

### With [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "sonictim/escape-hatch.nvim",
    config = function()
        require("escape-hatch").setup()
    end
}
```

### With [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
    "sonictim/escape-hatch.nvim",
    config = function()
        require("escape-hatch").setup()
    end
}
```

## ⚙️ Configuration

```lua
require("escape-hatch").setup({
    -- Enable/disable specific escape levels
    enable_1_esc = true,   -- Escape (exit mode + clear UI)
    enable_2_esc = true,   -- Escape + Save
    enable_3_esc = true,   -- Escape + Save + Quit
    enable_4_esc = true,   -- Escape + Quit (safe)
    enable_5_esc = true,   -- Escape + Quit All (safe)
    enable_6_esc = false,  -- Nuclear option (disabled by default for safety)

    -- Behavior options
    close_all_special_buffers = false,  -- Close all help/quickfix/etc buffers on single escape

    -- Custom commands (optional)
    commands = {
        save = "w",
        save_quit = "wq",
        quit = "q",
        quit_all = "qa",
        force_quit_all = "qa!",
        exit_terminal = "<C-\\><C-n>"
    },

    -- Custom descriptions
    descriptions = {
        level_1 = "Escape",
        level_2 = "Escape + Save",
        level_3 = "Escape + Save + Quit", 
        level_4 = "Escape + Quit",
        level_5 = "Escape + Quit All",
        level_6 = "Escape + Force Quit All"
    }
})
```

## 🚦 Safety First

**Level 4 and 5** use `:q` and `:qa` which safely prompt you before closing files with unsaved changes.

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

Traditional Neovim configs scatter save/quit commands across random keybindings and modes:
- `<C-s>` for save
- `<leader>w` for save  
- `<leader>q` for quit
- `:wq` for save & quit

**escape-hatch.nvim** creates a unified, escalating system where **every level starts by getting you to a clean state**, then adds progressively more final actions:

- **Consistent**: Every level works from any mode (normal, insert, visual, terminal)
- **Additive**: Each level does everything the previous level does, plus one more action
- **Predictable**: Same key, different repetition counts
- **Memorable**: Impossible to forget the pattern  
- **Logical**: More escapes = escape + more final actions

## 🎨 Examples

```lua
-- Basic setup (gets levels 1-5, nuclear disabled)
require("escape-hatch").setup()

-- Enable nuclear option
require("escape-hatch").setup({
    enable_6_esc = true  -- ⚠️ Dangerous!
})

-- Custom commands
require("escape-hatch").setup({
    commands = {
        save = "update",    -- Only save if buffer was modified
        quit_all = "qall"   -- Alternative to qa
    }

})

-- Dev setup
require('escape-hatch').setup({
    enable_6_esc = true,
    close_all_special_buffers = true,
    commands = {
        save = 'update',
        save_quit = 'x',
    },
})
```

## 🤝 Contributing

This plugin was born from a conversation about intuitive keybindings. If you have ideas for improvements or find the system useful, contributions are welcome!

## 📄 License

MIT

---

**"More escapes = escape + more final actions"** - The escape-hatch philosophy
