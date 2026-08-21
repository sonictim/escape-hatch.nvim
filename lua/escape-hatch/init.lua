-- escape-hatch.nvim
-- The escalating escape system for Neovim
-- More escapes = more final actions

local M = {}

local uv = vim.uv or vim.loop

-- Burst state: instead of a libuv timer resetting a counter, we compare
-- timestamps. Same behavior, no handle lifecycle to get wrong.
local counter = 0
local last_press = 0
local last_cmds = nil

-- Default configuration
local default_config = {
	close_all_special_buffers = false,
	handle_completion_popups = false,
	normal_mode = true,
	leader_mode = true,
	timeout = 500, -- How long a burst of escapes stays "connected", in ms
	telescope_full_quit = true,

	normal_commands = {
		[1] = "smart_close", -- First escape: clear UI/exit modes
		[2] = "save",  -- Second escape: save
		[3] = "quit",  -- Third escape: quit
		[4] = "quit_all",
	},
	leader_commands = {
		[1] = "escape",
		[2] = "delete_buffer",
		[3] = "force_quit_current",
		[4] = "force_quit_all",
	},

	-- Completion engine detection (auto-detects common engines)
	-- Can be "auto", "nvim-cmp", "blink", "coq", "native", or a custom function
	completion_engine = "auto",

	plugin_enabled = true,

	-- Any action name not handled natively falls through to this table and is
	-- run as an ex command, so adding a new escalation step needs no new code.
	commands = {
		save = "w",
		save_quit = "wq",
		quit = "q",
		quit_all = "qa",
		force_quit_current = "q!",
		force_quit_all = "qa!",
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
	},

	debug = false,
}

-- List-valued options are replaced wholesale rather than merged index-by-index,
-- so `normal_commands = { "smart_close", "quit" }` means exactly that.
local replace_keys = {
	preserve_buffers = true,
	normal_commands = true,
	leader_commands = true,
}

local config = {}

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------

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

---------------------------------------------------------------------------
-- completion engines
---------------------------------------------------------------------------

-- One entry per engine. "auto" just probes every entry, so an engine is
-- described once instead of twice.
local engines = {
	native = function()
		return vim.fn.pumvisible() == 1
	end,
	["nvim-cmp"] = function()
		local ok, cmp = pcall(require, "cmp")
		return ok and cmp.visible()
	end,
	blink = function()
		local ok, blink = pcall(require, "blink.cmp")
		return ok and blink.is_visible()
	end,
	coq = function()
		local ok, coq = pcall(require, "coq")
		return ok and coq.is_visible()
	end,
}

local function completion_active()
	local engine = config.completion_engine

	if type(engine) == "function" then
		return engine()
	end
	if engines[engine] then
		return engines[engine]()
	end

	for _, probe in pairs(engines) do
		if probe() then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------
-- window / buffer closing
---------------------------------------------------------------------------

-- Close any active Telescope picker, regardless of which Telescope window is
-- focused. Returns true if it closed something.
local function telescope_close_any()
	if not package.loaded["telescope"] then
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
	else
		escape()
	end
	return true
end

local function close_floating_windows()
	local closed = false
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local win_config = vim.api.nvim_win_get_config(win)
		if win_config.relative ~= "" then
			local buf = vim.api.nvim_win_get_buf(win)
			if not preserve_buffer(vim.api.nvim_buf_get_name(buf), vim.bo[buf].filetype) then
				vim.api.nvim_win_close(win, true)
				closed = true
			end
		end
	end
	return closed
end

local function handle_terminal()
	if vim.bo.buftype ~= "terminal" then
		return false
	end

	local mode = vim.fn.mode()
	local comm = config.commands.exit_terminal
	dprint("Terminal Path")

	if mode == "n" or comm == "hide" or comm == "close" then
		if #vim.api.nvim_tabpage_list_wins(0) > 1 then
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

local function close_special_buffers(buftype)
	local closed = false

	if config.close_all_special_buffers then
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			local bt = vim.bo[buf].buftype
			if vim.api.nvim_buf_is_loaded(buf) and bt ~= "" and bt ~= "terminal" then
				if not preserve_buffer(vim.api.nvim_buf_get_name(buf), bt) then
					vim.api.nvim_buf_delete(buf, { force = true })
					closed = true
				end
			end
		end
	elseif buftype ~= "" and buftype ~= "terminal" then
		if not preserve_buffer(vim.api.nvim_buf_get_name(0), buftype) then
			vim.api.nvim_buf_delete(0, { force = true })
			closed = true
		end
	end

	return closed
end


local function smart_close()
	local mode = vim.fn.mode()
	local buftype = vim.bo.buftype
	dprint("Mode:", mode, "Buftype:", buftype)


	if mode == "c" then
		send_keys("<C-c>")
		return true
	end
	if config.handle_completion_popups and mode == "i" and completion_active() then
		close_floating_windows()
		return true
	end
	if telescope_close_any() then
		return true
	end

	-- Sweep, then keep going: a float closing shouldn't block a terminal/mode exit.
	local closed = close_floating_windows()

	if handle_terminal() then
		return true
	end
	if mode == "v" or mode == "V" or mode == "\22" then
		escape()
		return true
	elseif mode ~= "n" then
		vim.cmd("stopinsert")
		return true
	end

	closed = close_special_buffers(buftype) or closed
	vim.cmd("nohlsearch")
	return closed
end

---------------------------------------------------------------------------
-- save / quit actions
---------------------------------------------------------------------------

local function smart_save()
	if vim.bo.buftype ~= "" then
		return -- cmdwin, terminal, quickfix, prompt, preview: nothing to write
	end
	if not vim.bo.modifiable or vim.bo.readonly then
		return
	end
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" or name:find("%c") or vim.fn.strchars(name, 1) < 0 then
		vim.notify("escape-hatch: refusing to write " .. vim.inspect(name), vim.log.levels.WARN)
		return
	end
	vim.cmd(config.commands.save)
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
	vim.cmd(config.commands.delete_buffer)
end

local function smart_quit()
	dprint("smart_quit activated")
	if vim.fn.getcmdline() ~= "" then
		dprint("commandline occupied")
		return
	end

	local name = vim.api.nvim_buf_get_name(0)
	dprint("smart_quit: buftype:", vim.bo.buftype, "name:", name)

	if vim.bo.buftype == "terminal" then
		-- Check window count right before closing (it might have changed)
		if #vim.api.nvim_tabpage_list_wins(0) == 1 then
			dprint("Last terminal window - quitting all")
			vim.cmd("qa")
		else
			dprint("Closing terminal window")
			pcall(vim.cmd.close) -- pcall to handle race condition
		end
		return
	end

	if name == "" and vim.bo.buftype == "" then
		vim.cmd("q")
	else
		vim.cmd(config.commands.quit)
	end
end

---------------------------------------------------------------------------
-- dispatch
---------------------------------------------------------------------------

-- Named actions with real logic. Anything else is looked up in
-- config.commands and run as an ex command.
local actions = {
	smart_close = smart_close,
	escape = escape,
	save = smart_save,
	save_quit = smart_save_quit,
	quit = smart_quit,
	delete_buffer = delete_buffer,
}

local function run(action)
	if type(action) == "function" then
		return action()
	end

	local fn = actions[action]
	if fn then
		return fn()
	end

	local cmd = config.commands[action]
	if cmd then
		local ok, err = pcall(vim.cmd, cmd)
		if not ok then
			vim.notify(("escape-hatch: %s: %s"):format(action, err), vim.log.levels.WARN)
		end
		return
	end

	vim.notify("escape-hatch: unknown action " .. tostring(action), vim.log.levels.WARN)
end


-- Advance the burst counter, restarting if the last press was too long ago or
-- came from a different command list.
local function bump(cmds)
	local now = uv.now()
	if cmds ~= last_cmds or (now - last_press) > config.timeout then
		counter = 1
	else
		counter = counter + 1
	end
	last_press = now
	last_cmds = cmds
	return counter
end

---------------------------------------------------------------------------
-- public API
---------------------------------------------------------------------------

---@param cmds table|nil Command list to escalate through; defaults to normal_commands
function M.handle_escape(cmds)
	if vim.fn.getcmdwintype() ~= "" then
		if vim.fn.mode() ~= "n" then
			vim.cmd("stopinsert")
		else
			vim.cmd("quit")
		end
		return
	end


	cmds = cmds or config.normal_commands
	local level = bump(cmds)
	if cmds[level] then
		run(cmds[level])
	end
end

-- Toggle whether <Esc> dismisses completion popups
function M.toggle_completion_popups()
	config.handle_completion_popups = not config.handle_completion_popups
	print("Close completion popups " .. (config.handle_completion_popups and "enabled" or "disabled"))
end

---------------------------------------------------------------------------
-- setup
---------------------------------------------------------------------------

local escape_modes = { "n", "i", "v", "t", "x", "c" }
local leader_modes = { "n", "v" }

local function setup_keymaps()
	if config.normal_mode then
		vim.keymap.set(escape_modes, "<Esc>", function()
			M.handle_escape()
		end, { desc = "Escape Hatch" })
	end
	if config.leader_mode then
		vim.keymap.set(leader_modes, "<leader><Esc>", function()
			M.handle_escape(config.leader_commands)
		end, { desc = "Escape Hatch Quit without Save" })
	end
end

local function merge_config(user)
	user = user or {}
	local merged = vim.tbl_deep_extend("force", default_config, user)

	for key in pairs(replace_keys) do
		if user[key] ~= nil then
			merged[key] = vim.deepcopy(user[key])
		end
	end

	return merged
end

function M.setup(user_config)
	config = merge_config(user_config)

	if not config.plugin_enabled then
		return
	end

	vim.api.nvim_create_user_command("TelescopeClose", function()
		if not telescope_close_any() then
			vim.notify("No Telescope picker to close", vim.log.levels.INFO)
		end
	end, {})

	setup_keymaps()
end

return M
