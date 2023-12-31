local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup
local bo = vim.bo
local opt_local = vim.opt_local
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

autocmd({ "ColorScheme" }, {
	pattern = "*",
	command = [[
		hi link OrgAgendaScheduled HintMsg
		hi link OrgDONE DiffAdd
		hi link OrgTODO DiffDelete
	]],
})

local trim = augroup("trim", { clear = true })
autocmd({ "BufWritePre" }, {
	pattern = { "*" },
	group = trim,
	command = [[%s/\s\+$//e]],
})

local stay = augroup("stay", { clear = true })
autocmd({ "BufWinLeave", "BufWritePost", "WinLeave" }, {
	group = stay,
	desc = "Save view with mkview for real files",
	callback = function(args)
		if vim.b[args.buf].view_activated then
			vim.cmd.mkview({ mods = { emsg_silent = true } })
		end
	end,
})
autocmd("BufWinEnter", {
	desc = "Try to load file view if available and enable view saving for real files",
	group = stay,
	callback = function(args)
		if not vim.b[args.buf].view_activated then
			local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
			local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })
			local ignore_filetypes = { "gitcommit", "gitrebase", "svg", "hgcommit" }
			if buftype == "" and filetype and filetype ~= "" and not vim.tbl_contains(ignore_filetypes, filetype) then
				vim.b[args.buf].view_activated = true
				vim.cmd.loadview({ mods = { emsg_silent = true } })
			end
		end
	end,
})

local editing = augroup("editing", { clear = true })
autocmd({ "BufEnter" }, {
	pattern = "*",
	group = editing,
	callback = function()
		local vals = { "c", "r", "o" }
		for _, val in ipairs(vals) do
			opt_local.formatoptions:remove(val)
		end
	end,
})
autocmd("BufWritePre", {
	desc = "Close all notifications on BufWritePre",
	group = editing,
	callback = function()
		require("notify").dismiss({ pending = true, silent = true })
	end,
})

local highlight_yank = augroup("highlight_yank", { clear = true })
autocmd({ "TextYankPost" }, {
	pattern = "*",
	group = highlight_yank,
	command = 'silent! lua vim.highlight.on_yank{"IncSearch", 1000}',
})

local filetypes = augroup("filetypes", { clear = true })
autocmd({ "BufReadPost" }, {
	pattern = "*.rasi",
	group = filetypes,
	callback = function()
		opt_local.filetype = "css"
	end,
})
autocmd({ "BufReadPost" }, {
	pattern = "*.ipynb",
	group = filetypes,
	callback = function()
		opt_local.filetype = "python"
	end,
})
autocmd({ "BufReadPost" }, {
	pattern = "*.conf",
	group = filetypes,
	callback = function()
		opt_local.filetype = "config"
	end,
})
autocmd({ "BufReadPost" }, {
	pattern = "*.sbat",
	group = filetypes,
	callback = function()
		opt_local.filetype = "sh"
	end,
})

local text_opts = augroup("text_opts", { clear = true })
autocmd({ "BufNewFile", "BufRead" }, {
	pattern = { "*.md", "*.txt", "*.tex", "*.org", "*.qmd", "*.typ" },
	group = text_opts,
	callback = function()
		vim.b.minicursorword_disable = true
		opt_local.list = false
		opt_local.spell = true
		map("i", "<C-l>", "<c-g>u<Esc>[s1z=`]a<c-g>u", opts) -- autocorrect last spelling error
	end,
})

local starter = augroup("starter", { clear = true })
autocmd({ "VimEnter" }, {
	pattern = "*",
	group = starter,
	callback = function()
		if bo.filetype == "starter" then
			opt_local.laststatus = 0
			vim.o.showtabline = 0
			autocmd({ "BufUnload" }, {
				group = starter,
				pattern = "<buffer>",
				callback = function()
					opt_local.laststatus = 3
					vim.o.showtabline = 2
				end,
			})
		end
	end,
})

local telescope = augroup("telescope", { clear = true })
autocmd({ "Filetype" }, {
	pattern = "TelescopePrompt",
	group = telescope,
	callback = function()
		require("cmp").setup.buffer({ completion = { autocomplete = false } })
	end,
})

local showpaste = augroup("showpaste", { clear = true })
autocmd({ "InsertLeave", "InsertEnter" }, {
	pattern = "*",
	group = showpaste,
	callback = function()
		if opt_local.paste then
			opt_local.paste = false
		else
			opt_local.paste = true
		end
	end,
})

local toggleterm = augroup("toggleterm", { clear = true })
autocmd({ "TermOpen" }, {
	pattern = "term://*",
	group = toggleterm,
	callback = function()
		require("utils.misc").set_terminal_keymaps()
	end,
})

local neogit = augroup("neogit", { clear = true })
autocmd({ "Filetype" }, {
	pattern = "Neogit*",
	group = neogit,
	callback = function()
		opt_local.list = false
	end,
})
