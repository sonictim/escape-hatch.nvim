# 🚀 escape-hatch.nvim

**The escalating escape system for Neovim**

More escapes = more final actions. Fully customizable to your workflow.

> **Finally! A way to quit Vim that doesn't require a Stack Overflow search.** 
> 
> We've all been there: trapped in Vim, mashing keys, trying `:exit`, `:leave`, `:please-let-me-out`. Those days are over. Choose your path: `<Esc>` for smart cleanup with saves, `<leader><Esc>` for direct actions, or use both. Each path escalates - more presses = more final actions. Fully customizable to your workflow.

## ✨ Features

- **Zero delays**: Immediate response with timer-based escalation
- **Mode agnostic**: Works from any mode (insert, visual, terminal, normal)
- **Flexible paths**: Use `<Esc>` (with saving), `<leader><Esc>` (without saving), or both
- **Perfect integrations**: `<leader><Esc>` provides simple escape for which-key, while `<Esc>` handles telescope and UI cleanup
- **Smart context**: Automatically handles floating windows, completion popups, terminals
- **Highly customizable**: Customize commands, sequences, timeouts, and behavior
- **Safe by default**: Destructive actions require more deliberate sequences

## 🎯 Default Escalation Paths

Choose which paths you want enabled and customize their commands:

### **Normal Path (`<Esc>`)** - Smart Cleanup with Saving (Default)
Clean UI → Save → Quit → Quit All

| Presses | Command | Description |
|---------|--------|-------------|
| **1** | `smart_close` | Clear modes + Close floating windows + Exit UI |
| **2** | `save` | Everything above + Save current file |
| **3** | `quit` | Everything above + Close current file |
| **4** | `quit_all` | Everything above + Close all files |

### **Leader Path (`<leader><Esc>`)** - Direct Actions without Saving (Default)
Escape → Delete → Quit → Nuclear

| Presses | Command | Description |
|---------|--------|-------------|
| **1** | `escape` | Regular escape (minimal intervention) |
| **2** | `delete_buffer` | Remove current buffer |
| **3** | `quit_all` | Close all files (with unsaved warnings) |
| **4** | `force_quit_all` | Nuclear option - force quit everything |

**Key Advantages**: 
- **Two distinct workflows**: Normal path preserves your work with automatic saving, while leader path provides quick exits without saving
- **Simple vs Smart escape**: Normal path does smart cleanup (closes UI, handles modes), while leader path starts with simple escape (perfect for which-key, minimal intervention)

Uses a timer-based counter system (400ms default) that tracks rapid sequences:

- **Immediate response** - no waiting for timeout delays
- **Independent paths** - each keybinding maintains its own sequence  
- **Auto-reset** - timer resets after inactivity
- **Which-key friendly** - `<leader><Esc>` level 1 sends regular escape for perfect integration

**Perfect for:**
- **Daily workflows** - Normal path handles 95% of escape scenarios smartly
- **Power users** - Leader path provides direct buffer/quit controls  
- **Which-key users** - Zero conflicts, seamless integration
- **Plugin compatibility** - Works with Telescope, completion engines, terminals

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
-- Basic setup (both paths enabled with defaults)
require("escape-hatch").setup()

-- Custom configuration
require("escape-hatch").setup({
    -- Choose which paths to enable
    normal_mode = true,                 -- Enable <Esc> sequences
    leader_mode = true,                 -- Enable <leader><Esc> sequences
    
    -- Timer and behavior
    timeout = 400,                      -- Timer reset timeout (milliseconds)
    close_all_special_buffers = false,  -- Close all help/quickfix/etc buffers on smart_close
    handle_completion_popups = false,   -- Close completion popups on smart_close (stays in insert mode)
    
    -- Customize command sequences
    normal_commands = {
        [1] = "smart_close",            -- <Esc>: smart cleanup
        [2] = "save",                   -- <Esc><Esc>: + save
        [3] = "quit",                   -- <Esc><Esc><Esc>: + quit
        [4] = "quit_all",               -- <Esc><Esc><Esc><Esc>: + quit all
    },
    leader_commands = {
        [1] = "escape",                 -- <leader><Esc>: regular escape
        [2] = "delete_buffer",          -- <leader><Esc><Esc>: delete buffer
        [3] = "quit_all",               -- <leader><Esc><Esc><Esc>: quit all (no save)
        [4] = "force_quit_all",         -- <leader><Esc><Esc><Esc><Esc>: nuclear
    },
    
    -- Completion engine detection
    completion_engine = "auto",         -- "auto", "nvim-cmp", "blink", "coq", "native", or custom function

    -- Custom commands (optional)
    commands = {
        save = "w",
        save_quit = "wq",
        quit = "q",
        quit_all = "qa",
        force_quit_all = "qa!",
        exit_terminal = "<C-\\><C-n>",   -- Terminal exit behavior
        delete_buffer = "bd",
    },

    -- UI elements to preserve (not close with smart_close)
    preserve_buffers = {
        "tutor", "lualine", "neo%-tree", "nvim%-tree", 
        "alpha", "dashboard", "trouble", "which%-key",
        -- Add your own patterns here
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

## ⚡ Timer-Based System

The plugin uses a 400ms timer (configurable) to track rapid key sequences within each path. This eliminates the timeout delays of traditional multi-key mappings:

- **Immediate response**: Each keypress executes instantly
- **Independent paths**: `<Esc>` and `<leader><Esc>` maintain separate counters
- **Auto-reset**: Counter resets to 1 after timeout period

```lua
require("escape-hatch").setup({
    timeout = 300,  -- Faster reset for rapid sequences
    timeout = 600,  -- Slower reset for more deliberate sequences
})
```

**No more waiting for Vim's `timeoutlen`** - each escape action happens immediately!

## 🎛️ Single Path Setups

You can enable just one path for simpler workflows:

**Normal path only (just `<Esc>`):**
```lua
require("escape-hatch").setup({
    normal_mode = true,
    leader_mode = false,
})
```

**Leader path only (just `<leader><Esc>`):**
```lua
require("escape-hatch").setup({
    normal_mode = false,
    leader_mode = true,
})
```

**Custom single path with different commands:**
```lua
require("escape-hatch").setup({
    normal_mode = true,
    leader_mode = false,
    normal_commands = {
        [1] = "smart_close",  -- Clean up UI
        [2] = "save_quit",    -- Save and quit immediately  
        [3] = "quit_all",     -- Quit everything
        [4] = "force_quit_all" -- Nuclear option
    },
})
```

## 🚦 Safety First

**Normal path levels 3-4** and **leader path level 3** use `:q` and `:qa` which safely prompt before closing files with unsaved changes.

The **nuclear option** (leader path level 4) uses `:qa!` and immediately force quits everything. Use with caution!

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
-- Basic setup (both paths enabled with defaults)
require("escape-hatch").setup()

-- Custom commands
require("escape-hatch").setup({
    commands = {
        save = "update",        -- Only save if buffer was modified
        quit_all = "wqa",       -- Save all files then quit (instead of qa)
        delete_buffer = "bw",   -- Wipe buffer instead of delete
    }
})

-- Faster timer reset for rapid workflows
require("escape-hatch").setup({
    timeout = 300,  -- Reset timer faster
})

-- Completely custom sequences
require("escape-hatch").setup({
    normal_commands = {
        [1] = "smart_close",   -- Clean UI
        [2] = "save",         -- Save file
        [3] = "save_quit",    -- Save and quit immediately
        [4] = "quit_all",     -- Quit everything
    },
    leader_commands = {
        [1] = "delete_buffer", -- Different first action
        [2] = "quit",         -- Direct quit
        [3] = "quit_all",     -- Quit all (safe)
        [4] = "force_quit_all" -- Nuclear option
    }
})

-- Development workflow
require('escape-hatch').setup({
    close_all_special_buffers = true,  -- Aggressive cleanup
    handle_completion_popups = true,   -- Handle completion popups
    commands = {
        save = 'update',               -- Only save when modified
        delete_buffer = 'bw',          -- Wipe buffer completely
    },
})

-- Minimal setup (normal path only, custom sequence)
require('escape-hatch').setup({
    normal_mode = true,
    leader_mode = false,
    normal_commands = {
        [1] = "smart_close",
        [2] = "quit_all",     -- Skip saving, go straight to quit all
    },
})
```

## 🤝 Contributing

This plugin was born from a conversation about intuitive keybindings. If you have ideas for improvements or find the system useful, contributions are welcome!

## 📄 License

MIT

---

**"More escapes = escape + more final actions"** - The escape-hatch philosophy
