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
	close_all_special_buffers = false,
	handle_completion_popups = false,

	plugin_enabled = true,
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
		level_1 = "Escape",
		level_2 = "Escape + Save",
		level_3 = "Escape + Save + Quit",
		level_4 = "Escape + Quit",
		level_5 = "Escape + Quit All",
		level_6 = "Escape + Force Quit All",
	},
	ignore_buffers = {
		"tutor", -- Vimtutor buffers
		-- Users can add more patterns here
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

local function completion_active()
	-- Check for native completion
	if vim.fn.pumvisible() == 1 then
		return true
	end

	-- Check for nvim-cmp (if installed)
	local ok, cmp = pcall(require, "cmp")
	if ok and cmp.visible() then
		return true
	end

	return false
end

local function preserve_buffer(buf_name, buf_type)
	for _, pattern in ipairs(config.ignore_buffers) do
		local ok1, match1 = pcall(string.match, buf_name, pattern)
		local ok2, match2 = pcall(string.match, buf_type, pattern)
		if (ok1 and match1) or (ok2 and match2) then
			return true
		end
	end
	return false
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

local function smart_close()
	-- Step 3: Clear search highlighting
	vim.cmd("nohlsearch")
	-- Step 4: Close telescope if active
	if telescope_close_any() then
		return -- Telescope closed, we're done
	end
	-- Step 5: Close floating windows
	local flag = false
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local win_config = vim.api.nvim_win_get_config(win)
		if win_config.relative ~= "" then
			vim.api.nvim_win_close(win, true)
			flag = true
		end
	end
	if flag then
		return
	end
	-- Handle completion popups first, before any mode changes
	if config.handle_completion_popups and vim.fn.mode() == "i" and completion_active() then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		return
	end
	-- Step 1: Exit any mode to normal mode
	local mode = vim.fn.mode()
	if mode == "t" then
		vim.api.nvim_feedkeys(
			vim.api.nvim_replace_termcodes(config.commands.exit_terminal, true, false, true),
			"n",
			false
		)
		return -- Terminal exit needs to complete first
	elseif mode == "v" or mode == "V" or mode == "\22" then -- visual, visual-line, visual-block
		vim.cmd([[normal! \<Esc>]])
		-- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		return
	elseif mode ~= "n" then
		vim.cmd("stopinsert")
		return
	end

	-- Step 2: Close any non editable buffers
	if config.close_all_special_buffers then
		-- Close ALL special buffers
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype ~= "" then
				local name = vim.api.nvim_buf_get_name(buf)
				if not preserve_buffer(name, vim.bo[buf].buftype) then
					vim.api.nvim_buf_delete(buf, { force = true })
				end
			end
		end
	else
		-- Close current buffer if it's special
		if vim.bo.buftype ~= "" then
			local name = vim.api.nvim_buf_get_name(0)
			if not preserve_buffer(name, vim.bo.buftype) then
				vim.api.nvim_buf_delete(0, { force = true })
			end
		end
	end
end

local function smart_save()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then
		vim.api.nvim_feedkeys(":" .. "saveas ", "c", false) -- Unnamed buffer
	else
		vim.cmd(config.commands.save) -- Normal file
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
vim.api.nvim_create_user_command("TelescopeClose", function()
	if not telescope_close_any() then
		vim.notify("No Telescope picker to close", vim.log.levels.INFO)
	end
end, {})
-- set up keymaps based on configuration
local function setup_keymaps()
	if not config.plugin_enabled then
		return
	end
	if config.enable_1_esc then
		vim.keymap.set({ "n", "i", "v", "t" }, "<Esc>", smart_close, { desc = "Escape" })
	end
	-- level 2: save / exit terminal
	if config.enable_2_esc then
		vim.keymap.set({ "n", "i", "v", "t" }, "<Esc><Esc>", function()
			smart_close()
			smart_save()
		end, { desc = "Escape + Save" })
	end

	-- Level 3: Save & quit

	if config.enable_3_esc then
		vim.keymap.set({ "n", "i", "v", "t" }, "<Esc><Esc><Esc>", function()
			smart_close()
			smart_save_quit()
		end, { desc = "Escape + Save + Quit" })
	end

	-- Level 4: Quit (safe)
	if config.enable_4_esc then
		vim.keymap.set({ "i", "n", "v", "t" }, "<Esc><Esc><Esc><Esc>", function()
			smart_close()
			vim.cmd(config.commands.quit)
		end, { desc = "Escape + Quit" })
	end

	-- Level 5: Quit all (safe)
	if config.enable_5_esc then
		vim.keymap.set({ "i", "n", "v", "t" }, "<Esc><Esc><Esc><Esc><Esc>", function()
			smart_close()
			vim.cmd(config.commands.quit_all)
		end, { desc = "Escape + Quit All" })
	end

	-- Level 6: Nuclear option
	if config.enable_6_esc then
		vim.keymap.set({ "i", "n", "v", "t" }, "<Esc><Esc><Esc><Esc><Esc><Esc>", function()
			smart_close()
			nuclear_option()
		end, { desc = "Escape + Force Quit All" })
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

	local modes = { "n", "i", "v", "t" }
	if config.enable_6_esc then
		vim.keymap.set(modes, "<Esc><Esc><Esc><Esc><Esc><Esc>", function()
			smart_close()
			nuclear_option()
		end, { desc = "Escape + Force Quit All" })
	else
		pcall(vim.keymap.del, modes, "<Esc><Esc><Esc><Esc><Esc><Esc>")
	end

	local status = config.enable_6_esc and "enabled" or "disabled"
	print("🔥 Nuclear option " .. status)
end

-- Utility function to toggle close_all_special_buffers option
function M.toggle_close_all_buffers()
	config.close_all_special_buffers = not config.close_all_special_buffers

	local status = config.close_all_special_buffers and "enabled" or "disabled"
	print("Close all special buffers " .. status)
end

-- Utility function to toggle close_all_special_buffers option
function M.toggle_completion_popups()
	config.handle_completion_popups = not config.handle_completion_popups

	local status = config.handle_completion_popups and "enabled" or "disabled"
	print("Close completion popups " .. status)
end
-- Utility function to toggle entire plugin on/off
function M.toggle_plugin()
	config.plugin_enabled = not config.plugin_enabled

	if config.plugin_enabled then
		setup_keymaps()
		print("Escape-hatch enabled")
	else
		-- Remove all keymaps
		local modes = { "n", "i", "v", "t" }
		pcall(vim.keymap.del, modes, "<Esc>")
		pcall(vim.keymap.del, modes, "<Esc><Esc>")
		pcall(vim.keymap.del, modes, "<Esc><Esc><Esc>")
		pcall(vim.keymap.del, modes, "<Esc><Esc><Esc><Esc>")
		pcall(vim.keymap.del, modes, "<Esc><Esc><Esc><Esc><Esc>")
		if config.enable_6_esc then
			pcall(vim.keymap.del, modes, "<Esc><Esc><Esc><Esc><Esc><Esc>")
		end
		print("Escape-hatch disabled")
	end
end

return M
