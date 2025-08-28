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
| **1** | Escape | Clear/Exit mode + Close UI windows |
| **2** | Escape + Save | Level 1 + Save current file |
| **3** | Escape + Save + Quit | Level 2 + Close current file |
| **4** | Escape + Quit | Level 1 + Close file (with unsaved warning) |
| **5** | Escape + Quit All | Level 1 + Close all files (with unsaved warnings) |
| **6** | Escape + Nuclear 🔥 | Level 1 + Force quit everything, discard changes |

## 🔄 Split Mode (Alternative)

Split mode eliminates timeout delays by using a timer-based counter system with two separate keybindings:

- **`<Esc>`**: "Gentle" actions (clear UI → save → quit)
- **`<leader><Esc>`**: "Aggressive" actions (quit → quit all → force quit all)

**Benefits:**
- ✅ No timeout delays - immediate response
- ✅ Separate gentle vs aggressive workflows
- ✅ Timer resets automatically after 500ms (configurable)

**Usage:**
```lua
require("escape-hatch").setup({
    split_mode = true,
    timeout = 500,  -- Timer timeout in milliseconds
})
```

**Split mode behavior:**
- Press `<Esc>` once: Clear UI/exit modes  
- Press `<Esc>` twice quickly: + Save file
- Press `<Esc>` thrice quickly: + Quit

- Press `<leader><Esc>` once: Quit (no save)
- Press `<leader><Esc>` twice quickly: Quit all
- Press `<leader><Esc>` thrice quickly: Force quit all

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
    handle_completion_popups = false,   -- Close completion popups on single escape (stays in insert mode)
    
    -- Mode selection
    split_mode = false,                 -- Use timer-based split mode instead of escalation
    timeout = 500,                      -- Timer timeout for split mode (milliseconds)
    
    -- Split mode command arrays (only used when split_mode = true)
    normal_commands = {
        [1] = "smart_close",            -- First <Esc>: clear UI/exit modes
        [2] = "save",                   -- Second <Esc>: save
        [3] = "quit",                   -- Third <Esc>: quit
    },
    leader_commands = {
        [1] = "quit",                   -- First <leader><Esc>: quit
        [2] = "quit_all",               -- Second: quit all
        [3] = "force_quit_all",         -- Third: force quit all
    },
    
    -- Completion engine detection
    completion_engine = "auto",         -- "auto" (default), "nvim-cmp", "blink", "coq", "native", or custom function

    -- Custom commands (optional)
    commands = {
        save = "w",
        save_quit = "wq",
        quit = "q",
        quit_all = "qa",
        force_quit_all = "qa!",
        exit_terminal = "<C-\\><C-n>"   -- "close" and "hide" are custom commands you can put here also
    },

    -- Custom descriptions
    descriptions = {
        level_1 = "Escape",
        level_2 = "Escape + Save",
        level_3 = "Escape + Save + Quit", 
        level_4 = "Escape + Quit",
        level_5 = "Escape + Quit All",
        level_6 = "Escape + Force Quit All"
    },

    -- UI elements to preserve (not close with escape)
    preserve_buffers = {
        "tutor",      -- Vimtutor buffers
        "lualine",    -- Lualine statusline  
        "neo%-tree",  -- Neo-tree file explorer
        "nvim%-tree", -- Nvim-tree file explorer
        "alpha",      -- Alpha dashboard
        "dashboard",  -- Dashboard
        "trouble",    -- Trouble diagnostics
        "which%-key", -- Which-key popup
        -- Users can add more patterns here
    },
})
```

## 🔧 Completion Engine Configuration

The `completion_engine` option controls how escape-hatch detects active completion popups:

```lua
require("escape-hatch").setup({
    handle_completion_popups = true,
    completion_engine = "auto",  -- Choose detection method
})
```

**Available options:**
- `"auto"` (default) - Auto-detects nvim-cmp, blink.cmp, coq_nvim, and native completion
- `"nvim-cmp"` - Only check for nvim-cmp completion
- `"blink"` - Only check for blink.cmp completion  
- `"coq"` - Only check for coq_nvim completion
- `"native"` - Only check for native Vim completion (`pumvisible()`)
- Custom function - Define your own detection logic

**Custom function example:**
```lua
require("escape-hatch").setup({
    completion_engine = function()
        -- Your custom completion detection logic
        return require("my_completion_plugin").is_visible()
    end
})
```

**Performance tip:** If you know which completion engine you use, set it specifically (e.g., `"blink"`) instead of `"auto"` for faster detection.

## ⚠️ Multi-Key Sequence Behavior

Due to Neovim's keymap system, there is a brief delay (controlled by `timeoutlen`) when pressing single escape while the system waits to see if you'll press additional escapes. This is unavoidable with multi-level key sequences.

**To reduce the delay:**
```lua
-- Set a shorter timeout globally (affects all multi-key sequences)
vim.o.timeoutlen = 200  -- Default is usually 1000ms. Less than 200 is not recommended

require("escape-hatch").setup({
  -- your config
})
```

**Trade-offs:**
- **Shorter timeout**: Faster escape response, but other multi-key mappings (like `<leader>` sequences) will also timeout faster
- **Default timeout**: Longer escape delay, but preserves your existing keymap timing

This behavior is fundamental to how Vim/Neovim processes ambiguous key sequences and cannot be avoided while maintaining the escalation system.

**💡 Tip:** Consider using split mode (`split_mode = true`) to eliminate timeout delays entirely!

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

-- Toggle functions (can be mapped to keys)
:lua require("escape-hatch").toggle_nuclear()          -- Enable/disable nuclear option
:lua require("escape-hatch").toggle_close_all_buffers() -- Toggle closing all special buffers
:lua require("escape-hatch").toggle_completion_popups() -- Toggle completion popup handling
:lua require("escape-hatch").toggle_plugin()           -- Enable/disable entire plugin

-- Example keybindings
vim.keymap.set("n", "<leader>en", require("escape-hatch").toggle_nuclear)
vim.keymap.set("n", "<leader>ec", require("escape-hatch").toggle_close_all_buffers)
vim.keymap.set("n", "<leader>ep", require("escape-hatch").toggle_plugin)
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
        quit_all = "wqa"    -- Save all files then quit (instead of qa)
    }
})

-- Split mode setup (no timeout delays!)
require("escape-hatch").setup({
    split_mode = true,
    timeout = 300,  -- Faster reset
    normal_commands = {
        [1] = "smart_close",  -- <Esc>: clear UI
        [2] = "save",         -- <Esc><Esc>: + save  
        [3] = "save_quit",    -- <Esc><Esc><Esc>: + save & quit
    },
    leader_commands = {
        [1] = "quit",         -- <leader><Esc>: quit without save
        [2] = "quit_all",     -- <leader><Esc><Esc>: quit all
        [3] = "force_quit_all" -- <leader><Esc><Esc><Esc>: nuclear
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
