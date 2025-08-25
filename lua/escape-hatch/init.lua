-- escape-hatch.nvim
-- The escalating escape system for Neovim
-- More escapes = more final actions

local M = {}

-- Default configuration
local default_config = {
	-- Enable/disable specific escape levels
	enable_1_esc = true,
	enable_2_esc = true, -- Save / Exit terminal
	enable_3_esc = true, -- Save & quit
	enable_4_esc = true, -- Quit (safe)
	enable_5_esc = true, -- Quit all (safe)
	enable_6_esc = false, -- Force quit all (nuclear - disabled by default)

	-- Custom commands (optional overrides)
	commands = {
		save = "w", -- Changed from ":w<CR>" to just "w"
		save_quit = "wq", -- Changed from ":wq<CR>" to just "wq"
		quit = "q", -- Changed from ":q<CR>" to just "q"
		quit_all = "qa", -- Changed from ":qa<CR>" to just "qa"
		force_quit_all = "qa!", -- Changed from ":qa!<CR>" to just "qa!"
		exit_terminal = "<C-\\><C-n>", -- This one stays the same
	},

	-- Descriptions for which-key integration
	descriptions = {
		level_1 = "Clear Highlights and Close Floats",
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

-- Returns true if telescope is installed (doesn't error if not)
local function telescope_available()
	return pcall(require, "telescope")
end

-- Close any active Telescope picker, regardless of which Telescope window is focused.
-- Returns true if it closed something, false otherwise.
local function telescope_close_any()
	if not telescope_available() then
		return false
	end

	local ok_actions, actions = pcall(require, "telescope.actions")
	local ok_state, action_state = pcall(require, "telescope.actions.state")
	if not (ok_actions and ok_state) then
		return false
	end

	-- Find the prompt buffer (works even if Results window is current)
	local prompt_bufnr
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "TelescopePrompt" then
			prompt_bufnr = buf
			break
		end
	end
	if not prompt_bufnr then
		return false
	end

	local picker = action_state.get_current_picker(prompt_bufnr)
	if not picker then
		return false
	end

	-- Schedule to be safe from insert-mode context
	vim.schedule(function()
		actions.close(picker.prompt_bufnr)
	end)
	return true
end

local function smart_save()
	-- leave insert/terminal mode
	if vim.fn.mode() ~= "n" then
		vim.cmd("stopinsert")
	end

	local name = vim.api.nvim_buf_get_name(0)
	local buftype = vim.bo.buftype

	if buftype ~= "" then
		-- special buffer → just quit (no save needed)
		vim.cmd("q")
	elseif name == "" then
		-- unnamed normal buffer → prefill :saveas
		vim.api.nvim_feedkeys(":" .. "saveas ", "c", false)
	else
		-- named normal buffer → save normally
		vim.cmd(config.commands.save)
	end
end

local function smart_save_quit()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" and vim.bo.buftype == "" then
		vim.cmd("q")
	else
		vim.cmd(config.commands.save_quit)
	end
end

local function clear_ui()
	-- Close all floating windows
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local config = vim.api.nvim_win_get_config(win)
		if config.relative ~= "" then
			vim.api.nvim_win_close(win, true)
		end
	end

	-- Clear search highlighting
	vim.cmd("nohlsearch")
end

vim.api.nvim_create_user_command("TelescopeClose", function()
	if not telescope_close_any() then
		vim.notify("No Telescope picker to close", vim.log.levels.INFO)
	end
end, {})
-- set up keymaps based on configuration
local function setup_keymaps()
	if config.enable_1_esc then
		vim.keymap.set("n", "<Esc>", clear_ui, { desc = "Clear highlights and Close Floats" })
	end
	-- level 2: save / exit terminal
	if config.enable_2_esc then
		vim.keymap.set("t", "<Esc><Esc>", config.commands.exit_terminal, { desc = "Exit terminal" })
		vim.keymap.set({ "i", "v", "n" }, "<Esc><Esc>", function()
			if telescope_close_any() then
				return
			end
			smart_save()
		end, { desc = "Smart Save/Close" })
	end

	-- Level 3: Save & quit

	if config.enable_3_esc then
		vim.keymap.set({ "i", "n", "v" }, "<Esc><Esc><Esc>", function()
			smart_save_quit()
		end, { desc = config.descriptions.level_3 })
	end

	-- Level 4: Quit (safe)
	if config.enable_4_esc then
		vim.keymap.set(
			{ "i", "n", "v" },
			"<Esc><Esc><Esc><Esc>",
			"<Esc>:" .. config.commands.quit .. "<CR>", -- Fixed: same pattern as level 3
			{ desc = config.descriptions.level_4 }
		)
	end

	-- Level 5: Quit all (safe)
	if config.enable_5_esc then
		vim.keymap.set(
			{ "i", "n", "v" },
			"<Esc><Esc><Esc><Esc><Esc>",
			"<Esc>:" .. config.commands.quit_all .. "<CR>", -- Fixed: same pattern as level 3
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
	for i = 1, 6 do -- Changed from "for i = 2, 6"
		if config["enable_" .. i .. "_esc"] then
			table.insert(enabled_levels, i)
		end
	end
end

-- Utility function to show current config
function M.show_config()
	print("📋 escape-hatch.nvim configuration:")
	for i = 1, 6 do -- Changed from "for i = 2, 6" to include level 1
		local enabled = config["enable_" .. i .. "_esc"]
		local status = enabled and "✅" or "❌"
		local desc = config.descriptions["level_" .. i] or "Built-in"
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
