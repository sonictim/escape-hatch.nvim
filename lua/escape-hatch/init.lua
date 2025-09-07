-- escape-hatch.nvim
-- The escalating escape system for Neovim
-- More escapes = more final actions

local M = {}

local counter = 0
local timer = nil
local current_mode = "normal" -- Track which command set we're using

-- Default configuration
local default_config = {
	close_all_special_buffers = false,
	handle_completion_popups = false,
	normal_mode = true,
	leader_mode = true,
	timeout = 400, -- Timer timeout in milliseconds for split mode
	telescope_full_quit = true,
	normal_commands = {
		[1] = "smart_close", -- First escape: clear UI/exit modes
		[2] = "save", -- Second escape: save
		[3] = "quit", -- Third escape: quit
		[4] = "quit_all",
	},
	leader_commands = {
		[1] = "escape",
		[2] = "delete_buffer", -- First leader+escape: quit
		[3] = "quit_all", -- Second: quit all
		[4] = "force_quit_all", -- Third: force quit all
	},

	-- Completion engine detection (auto-detects common engines)
	-- Can be "auto", "nvim-cmp", "blink", "coq", "native", or a custom function
	completion_engine = "auto",

	plugin_enabled = true,
	-- Custom commands (optional overrides)
	commands = {
		save = "w", -- Changed from ":w<CR>" to just "w"
		save_quit = "wq", -- Changed from ":wq<CR>" to just "wq"
		quit = "q", -- Changed from ":q<CR>" to just "q"
		quit_all = "qa", -- Changed from ":qa<CR>" to just "qa"
		force_quit_all = "qa!", -- Changed from ":qa!<CR>" to just "qa!"
		exit_terminal = "<C-\\><C-n>", -- Options: "<C-\\><C-n>", "hide", "close"
		delete_buffer = "bd",
	},

	preserve_buffers = {
		"tutor", -- Vimtutor buffers
		"lualine", -- Lualine statusline
		"neo%-tree", -- Neo-tree file explorer
		"nvim%-tree", -- Nvim-tree file explorer
		"alpha", -- Alpha dashboard
		"dashboard", -- Dashboard
		"trouble", -- Trouble diagnostics
		"which%-key", -- Which-key popup (usually auto-closes)
		-- Users can add more patterns here
	},

	debug = false,
}

local config = {}

local function dprint(...)
	if config.debug then
		print(...)
	end
end
local function send_keys(keys)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end
local function escape()
	send_keys("<Esc>")
end

-- Returns true if telescope is installed (doesn't error if not)
local function telescope_available()
	return pcall(require, "telescope")
end

local function completion_active()
	-- If user provided a custom function, use it
	if type(config.completion_engine) == "function" then
		return config.completion_engine()
	end

	-- Handle specific engines
	if config.completion_engine == "native" then
		return vim.fn.pumvisible() == 1
	elseif config.completion_engine == "nvim-cmp" then
		local ok, cmp = pcall(require, "cmp")
		return ok and cmp.visible()
	elseif config.completion_engine == "blink" then
		local ok, blink = pcall(require, "blink.cmp")
		return ok and blink.is_visible()
	elseif config.completion_engine == "coq" then
		local ok, coq = pcall(require, "coq")
		return ok and coq.is_visible()
	else
		-- Auto-detect (default behavior)
		-- Check for native completion
		if vim.fn.pumvisible() == 1 then
			return true
		end

		-- Check for nvim-cmp (if installed)
		local ok, cmp = pcall(require, "cmp")
		if ok and cmp.visible() then
			return true
		end

		-- Check for blink.cmp (if installed)
		local ok_blink, blink = pcall(require, "blink.cmp")
		if ok_blink and blink.is_visible() then
			return true
		end

		-- Check for coq_nvim (if installed)
		local ok_coq, coq = pcall(require, "coq")
		if ok_coq and coq.is_visible() then
			return true
		end

		return false
	end
end

local function preserve_buffer(buf_name, buf_type)
	for _, pattern in ipairs(config.preserve_buffers) do
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

	if config.telescope_full_quit then
		-- Schedule to be safe from insert-mode context
		vim.schedule(function()
			actions.close(picker.prompt_bufnr)
		end)
		return true
	else
		escape()
		return true
	end
end
local function close_floating_windows()
	local r = false
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local win_config = vim.api.nvim_win_get_config(win)
		if win_config.relative ~= "" then
			local buf = vim.api.nvim_win_get_buf(win)
			local ft = vim.bo[buf].filetype
			if not preserve_buffer(vim.api.nvim_buf_get_name(buf), ft) then
				vim.api.nvim_win_close(win, true)
				r = true
			end
		end
	end
	return r
end

local function handle_terminal()
	local mode = vim.fn.mode()
	local wins = vim.api.nvim_list_wins()
	local comm = config.commands.exit_terminal
	if vim.bo.buftype ~= "terminal" then
		return false
	end

	dprint("Terminal Path")
	if mode == "n" or comm == "hide" or comm == "close" then
		if #wins > 1 then
			if comm == "hide" then
				vim.cmd.hide()
			else
				vim.cmd.close()
			end
		else
			vim.cmd("b#")
		end
	else
		send_keys(comm)
	end

	return true
end

local function smart_close()
	local mode = vim.fn.mode()
	local buftype = vim.bo.buftype
	dprint("Mode:", mode, "Bufftype:", vim.bo.buftype)

	if mode == "c" then
		send_keys("<C-c>")
		return true
	end
	if config.handle_completion_popups and vim.fn.mode() == "i" and completion_active() then
		dprint("Completion path")
		close_floating_windows()
		return true
	end
	if telescope_close_any() then
		dprint("Telescope path")
		return true
	end
	local r = close_floating_windows()
	if handle_terminal() then
		return true
	end
	if mode == "v" or mode == "V" or mode == "\22" then -- visual, visual-line, visual-block
		dprint("Visual Path")
		escape()
		return true
	elseif mode ~= "n" then
		dprint("Insert Path")
		vim.cmd("stopinsert")
		return true
	end
	if config.close_all_special_buffers then
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype ~= "" then
				local name = vim.api.nvim_buf_get_name(buf)
				-- print(name)
				if not preserve_buffer(name, vim.bo[buf].buftype) and vim.bo[buf].buftype ~= "terminal" then
					vim.api.nvim_buf_delete(buf, { force = true })
					r = true
				end
			end
		end
	else
		-- Close current buffer if it's special
		if buftype ~= "" and buftype ~= "terminal" then
			local name = vim.api.nvim_buf_get_name(0)
			if not preserve_buffer(name, vim.bo.buftype) then
				vim.api.nvim_buf_delete(0, { force = true })
				r = true
			end
		end
	end
	vim.cmd("nohlsearch")
	return r
end

local function smart_save()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then
		vim.api.nvim_feedkeys(":" .. "saveas ", "c", false) -- Unnamed buffer
	else
		handle_terminal()
		vim.cmd(config.commands.save) -- Normal file
	end
end

local function smart_save_quit()
	local name = vim.api.nvim_buf_get_name(0)
	if vim.bo.buftype == "terminal" then
		vim.cmd.close()
	end
	if name == "" and vim.bo.buftype == "" then
		vim.cmd("q")
	else
		vim.cmd(config.commands.save_quit)
	end
end

local function delete_buffer()
	vim.cmd(config.commands.delete_buffer) -- Normal file
end
local function smart_quit()
	dprint("smart_quit activated")
	dprint(vim.fn.getcmdline())
	if vim.fn.getcmdline() ~= "" then
		dprint("commandline occupied")
		return
	end
	local name = vim.api.nvim_buf_get_name(0)
	local num_wins = #vim.api.nvim_list_wins()
	dprint("smart_quit: buftype:", vim.bo.buftype, "num_wins:", num_wins, "name:", name)

	if vim.bo.buftype == "terminal" then
		-- Check window count right before closing (it might have changed)
		local current_wins = #vim.api.nvim_list_wins()
		if current_wins == 1 then
			dprint("Last terminal window - quitting all")
			vim.cmd("qa")
			return
		else
			dprint("Closing terminal window (current wins:", current_wins, ")")
			pcall(vim.cmd.close) -- Use pcall to handle race condition
			return
		end
	end
	if name == "" and vim.bo.buftype == "" then
		vim.cmd("q")
	else
		vim.cmd(config.commands.quit)
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

	if config.normal_mode then
		vim.keymap.set({ "n", "i", "v", "t", "x", "c" }, "<Esc>", function()
			M.handle_escape()
		end, { desc = "Escape Hatch" })
	end
	if config.leader_mode then
		vim.keymap.set({ "n", "i", "v", "t", "x", "c" }, "<leader><Esc>", function()
			M.handle_leader_escape()
		end, { desc = "Escape Hatch Quit without Save" })
	end
end

local function execute_commands(command_type, level)
	if command_type == "smart_close" then
		smart_close()
	elseif command_type == "escape" then
		escape()
	elseif command_type == "save" then
		smart_save()
	elseif command_type == "save_quit" then
		smart_save_quit()
	elseif command_type == "delete_buffer" then
		delete_buffer()
	elseif command_type == "quit" then
		smart_quit()
	elseif command_type == "quit_all" then
		vim.cmd(config.commands.quit_all)
	elseif command_type == "force_quit_all" then
		vim.cmd(config.commands.force_quit_all)
	elseif type(command_type) == "function" then
		command_type()
	end
end

function M.handle_escape()
	counter = counter + 1

	-- Execute command based on current mode
	local cmds = (current_mode == "leader") and config.leader_commands or config.normal_commands
	if cmds[counter] then
		execute_commands(cmds[counter], counter)
	end

	-- Clear existing timer
	if timer then
		timer:stop()
		timer:close()
	end

	-- Set new timer to reset counter and mode
	timer = vim.loop.new_timer()
	timer:start(config.timeout, 0, function()
		counter = 0
		current_mode = "normal" -- Reset to normal mode
		timer:close()
		timer = nil
	end)
end

function M.handle_leader_escape()
	current_mode = "leader"
	M.handle_escape()
end

function M.get_count()
	return counter
end

function M.reset_counter()
	counter = 0
	current_mode = "normal"
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
end

-- Main setup function
function M.setup(user_config)
	-- Merge user config with defaults
	config = vim.tbl_deep_extend("force", default_config, user_config or {})

	setup_keymaps()
end

-- Utility function to toggle close_all_special_buffers option
function M.toggle_completion_popups()
	config.handle_completion_popups = not config.handle_completion_popups

	local status = config.handle_completion_popups and "enabled" or "disabled"
	print("Close completion popups " .. status)
end

return M
