-- escape-hatch.nvim
-- The escalating escape system for Neovim
-- More escapes = more final actions

local M = {}

-- Default configuration
local default_config = {
	-- Enable/disable specific escape levels
	enable_2_esc = true, -- Save / Exit terminal
	enable_3_esc = true, -- Save & quit
	enable_4_esc = true, -- Quit (safe)
	enable_5_esc = true, -- Quit all (safe)
	enable_6_esc = false, -- Force quit all (nuclear - disabled by default)

	-- Custom commands (optional overrides)
	commands = {
		save = ":w<CR>",
		save_quit = ":wq<CR>",
		quit = ":q<CR>",
		quit_all = ":qa<CR>",
		force_quit_all = ":qa!<CR>",
		exit_terminal = "<C-\\><C-n>",
	},

	-- Descriptions for which-key integration
	descriptions = {
		level_2 = "Save / Exit terminal",
		level_3 = "Save & Quit",
		level_4 = "Quit",
		level_5 = "Quit All",
		level_6 = "Force Quit All",
	},
}

local config = {}

-- Nuclear option - force quit all without confirmation
-- If you want confirmation, just use level 5 (:qa) which has built-in protection
local function nuclear_option()
	vim.cmd("qa!")
end

-- Set up keymaps based on configuration
local function setup_keymaps()
	-- Level 2: Save / Exit terminal
	if config.enable_2_esc then
		vim.keymap.set("t", "<Esc><Esc>", config.commands.exit_terminal, { desc = config.descriptions.level_2 })
		vim.keymap.set(
			"i",
			"<Esc><Esc>",
			"<Esc>" .. config.commands.save,
			{ desc = "Exit insert & " .. config.descriptions.level_2:lower() }
		)
		vim.keymap.set("n", "<Esc><Esc>", config.commands.save, { desc = config.descriptions.level_2 })
	end

	-- Level 3: Save & quit
	if config.enable_3_esc then
		vim.keymap.set(
			{ "i", "n", "v" },
			"<Esc><Esc><Esc>",
			"<Esc>" .. config.commands.save_quit,
			{ desc = config.descriptions.level_3 }
		)
	end

	-- Level 4: Quit (safe)
	if config.enable_4_esc then
		vim.keymap.set(
			{ "i", "n", "v" },
			"<Esc><Esc><Esc><Esc>",
			"<Esc>" .. config.commands.quit,
			{ desc = config.descriptions.level_4 }
		)
	end

	-- Level 5: Quit all (safe)
	if config.enable_5_esc then
		vim.keymap.set(
			{ "i", "n", "v" },
			"<Esc><Esc><Esc><Esc><Esc>",
			"<Esc>" .. config.commands.quit_all,
			{ desc = config.descriptions.level_5 }
		)
	end

	-- Level 6: Nuclear option
	if config.enable_6_esc then
		vim.keymap.set({ "i", "n", "v" }, "<Esc><Esc><Esc><Esc><Esc><Esc>", function()
			vim.cmd("normal! <Esc>") -- Ensure we're in normal mode
			nuclear_option()
		end, { desc = config.descriptions.level_6 })
	end
end

-- Main setup function
function M.setup(user_config)
	-- Merge user config with defaults
	config = vim.tbl_deep_extend("force", default_config, user_config or {})

	-- Set up the keymaps
	setup_keymaps()

	-- Print setup confirmation
	local enabled_levels = {}
	for i = 2, 6 do
		if config["enable_" .. i .. "_esc"] then
			table.insert(enabled_levels, i)
		end
	end

	print("🚀 escape-hatch.nvim loaded! Enabled levels: " .. table.concat(enabled_levels, ", "))
	if config.enable_6_esc then
		print("⚠️  Nuclear option enabled - 6 escapes will force quit without confirmation!")
	end
end

-- Utility function to show current config
function M.show_config()
	print("📋 escape-hatch.nvim configuration:")
	print("  Level 1 (1 esc): Built-in (clear search/exit mode)")
	for i = 2, 6 do
		local enabled = config["enable_" .. i .. "_esc"]
		local status = enabled and "✅" or "❌"
		local desc = config.descriptions["level_" .. i]
		print("  Level " .. i .. " (" .. i .. " esc): " .. status .. " " .. desc)
	end
end

-- Utility function to toggle nuclear option
function M.toggle_nuclear()
	config.enable_6_esc = not config.enable_6_esc

	-- Remove existing keymaps
	vim.keymap.del({ "i", "n", "v" }, "<Esc><Esc><Esc><Esc><Esc><Esc>", { silent = true })

	-- Re-setup keymaps
	setup_keymaps()

	local status = config.enable_6_esc and "enabled" or "disabled"
	print("🔥 Nuclear option " .. status)
end

return M
