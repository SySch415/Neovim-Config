-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })

	-- check if cloning is successfull
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		-- add your plugins here
		{ "LazyVim/LazyVim", import = "lazyvim.plugins" },

		{ import = "lazyvim.plugins.extras.lang.typescript" },

		{ import = "lazyvim.plugins.extras.lang.json" },

		{ import = "lazyvim.plugins.extras.ui.mini-animate" },

		{ import = "lazyvim.plugins.extras.linting.eslint" },

		{ import = "lazyvim.plugins.extras.formatting.prettier" },

		{ import = "lazyvim.plugins.extras.lang.clangd" },

		{
			"mlaursen/vim-react-snippets",
			event = "InsertEnter",
			dependencies = { "honza/vim-snippets" },
		},

		--[[
		{
			"nvim-lualine/lualine.nvim",
			opts = {
				sections = {
					lualine_x = {
						{
							"diagnostics",
							sources = { "nvim_diagnostic" },
							sections = { "error", "warn", "hint" },
						},
					},
				},
			},
		},
    ]]

		{
			"dense-analysis/ale",
			config = function()
				vim.g.ale_linters = {
					cpp = { "g++", "clang", "cppcheck" },
					java = { "javac" },
				}
				vim.g.ale_fixers = {
					cpp = { "clang-format" },
					java = { "google-java-format" },
				}
				vim.g.ale_cpp_gcc_options = "-std=c++17"
			end,
		},

		-- Rust LSP and development
		{
			"neovim/nvim-lspconfig",
			dependencies = { "mason-org/mason.nvim", "mason-org/mason-lspconfig.nvim" },
			config = function()
				require("mason").setup()
				require("mason-lspconfig").setup({
					ensure_installed = { "rust_analyzer", "clangd" },
					automatic_enable = true,
				})

				local lspconfig = require("lspconfig")
				lspconfig.pyright.setup({})

				vim.lsp.enable("stylua", false)

				-- Rust Lsp
				lspconfig.rust_analyzer.setup({
					settings = {
						["rust-analyzer"] = {
							checkOnSave = {
								command = "clippy",
							},
						},
					},
				})

				-- C/C++ LSP
				local mason_clangd = "/home/sy/.local/share/nvim/mason/bin/clangd"
				lspconfig.clangd.setup({
					cmd = { mason_clangd },
					filetypes = { "c", "cpp", "objc", "objcpp" },
					root_dir = lspconfig.util.root_pattern("compile_commands.json", "compile_flags.txt", ".git"),
				})
			end,
		},

		-- Rust syntax highlighting and better parsing
		{
			"nvim-treesitter/nvim-treesitter",
			opts = {
				ensure_installed = { "rust", "c", "cpp" },
			},
		},

		{
			"mfussenegger/nvim-lint",
			opts = {
				linters_by_ft = {
					rust = { "clippy" },
					cpp = { "cppcheck" },
					c = { "cppcheck" },
					python = { "flake8" },
				},
				linters = {
					cppcheck = {
						args = {
							"--enable=all",
							"--inline-suppr",
							"--std=c11",
							"--cppcheck-build-dir=/tmp/cppcheck",
						},
					},
				},
			},
		},

		{
			"stevearc/conform.nvim",
			opts = {
				formatters_by_ft = {
					rust = { "rustfmt" },
					cpp = { "clang_format" },
					c = { "clang_format" },
					python = { "black" },
				},
			},
		},

		-- Autocompletion for Rust
		{
			"hrsh7th/nvim-cmp",
			dependencies = {
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
				"hrsh7th/cmp-nvim-lsp",
				"saadparwaiz1/cmp_luasnip",
				"L3MON4D3/LuaSnip",
				"rafamadriz/friendly-snippets",
			},
			config = function()
				local cmp = require("cmp")
				local luasnip = require("luasnip")

				require("luasnip.loaders.from_vscode").lazy_load()

				cmp.setup({
					snippet = {
						expand = function(args)
							luasnip.lsp_expand(args.body)
						end,
					},

					mapping = cmp.mapping.preset.insert({
						["<C-y>"] = cmp.mapping.confirm({ select = true }),
						["<C-e>"] = cmp.mapping.close(),
						["<C-Space>"] = cmp.mapping.complete(),
						["<Tab>"] = cmp.mapping(function(fallback)
							if cmp.visible() then
								cmp.select_next_item()
							elseif luasnip.expand_or_jumpable() then
								luasnip.expand_or_jump()
							else
								fallback()
							end
						end, { "i", "s" }),
						["<S-Tab>"] = cmp.mapping(function(fallback)
							if cmp.visible() then
								cmp.select_prev_item()
							elseif luasnip.jumpable(-1) then
								luasnip.jump(-1)
							else
								fallback()
							end
						end, { "i", "s" }),
						["<Down>"] = cmp.mapping.select_next_item(),
						["<Up>"] = cmp.mapping.select_prev_item(),
					}),
					sources = cmp.config.sources({
						{ name = "path" },
						{ name = "nvim_lsp" },
						{ name = "luasnip" },
						{ name = "buffer" },
					}),
				})
			end,
		},

		-- Debugging Support with LLDB
		{
			"mfussenegger/nvim-dap",
			config = function()
				local dap = require("dap")
				dap.adapters.codelldb = {
					type = "server",
					port = "${port}",
					executable = {
						command = "codelldb",
						args = { "--port", "${port}" },
					},
				}

				dap.configurations.rust = {
					{
						name = "Launch",
						type = "codelldb",
						request = "launch",
						program = function()
							return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
						end,
						cwd = "${workspaceFolder}",
						stopOnEntry = false,
						args = {},
					},
				}

				dap.configurations.cpp = {
					{
						name = "Launch",
						type = "codelldb",
						request = "launch",
						program = function()
							return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
						end,
						cwd = "${workspaceFolder}",
						stopOnEntry = false,
						args = {},
					},
				}

				dap.configurations.c = dap.configurations.cpp
			end,
		},

		-- UI for nvim-dap
		{
			"rcarriga/nvim-dap-ui",
			dependencies = {
				"mfussenegger/nvim-dap",
				"nvim-neotest/nvim-nio",
			},
			config = function()
				require("dapui").setup()
			end,
		},

		-- path completition/intellisense
		{
			"hrsh7th/nvim-cmp",
			dependencies = {
				"hrsh7th/cmp-buffer",
				"hrsh7th/cmp-path",
				"hrsh7th/cmp-nvim-lsp",
				"saadparwaiz1/cmp_luasnip",

				-- Snippet completition
				"L3MON4D3/LuaSnip",

				-- Snippet Engine
				"rafamadriz/friendly-snippets",
			},
			config = function()
				local cmp = require("cmp")
				local luasnip = require("luasnip")

				require("luasnip.loaders.from_vscode").lazy_load()

				cmp.setup({
					snippet = {
						expand = function(args)
							luasnip.lsp_expand(args.body)
						end,
					},

					mapping = cmp.mapping.preset.insert({
						["<C-y>"] = cmp.mapping.confirm({ select = true }),
						["<C-e>"] = cmp.mapping.close(),
						["<C-Space>"] = cmp.mapping.complete(),
						["<Tab>"] = cmp.mapping(function(fallback)
							if cmp.visible() then
								cmp.select_next_item()
							elseif luasnip.expand_or_jumpable() then
								luasnip.expand_or_jump()
							else
								fallback()
							end
						end, { "i", "s" }),
						["<S-Tab>"] = cmp.mapping(function(fallback)
							if cmp.visible() then
								cmp.select_prev_item()
							elseif luasnip.jumpable(-1) then
								luasnip.jump(-1)
							else
								fallback()
							end
						end, { "i", "s" }),
						["<Down>"] = cmp.mapping.select_next_item(),
						["<Up>"] = cmp.mapping.select_prev_item(),
					}),
					sources = cmp.config.sources({
						{ name = "path" },
						{ name = "nvim_lsp" },
						{ name = "luasnip" },
						{ name = "buffer" },
					}),
				})
			end,
		},

		{
			"rebelot/kanagawa.nvim",
			lazy = false,
			priority = 1000,
			config = function()
				require("kanagawa").setup({
					transparent = true,
				})
				vim.cmd.colorscheme("kanagawa-dragon")
			end,
		},

		-- git integration
		{ "tpope/vim-fugitive" },

		-- status line
		{ "nvim-lualine/lualine.nvim" },

		-- Javascript/react development
		{ "pangloss/vim-javascript" },
		{ "maxmellon/vim-jsx-pretty" },
	},
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "kanagawa" } },
	-- automatically check for plugin updates
	checker = { enabled = true },
})

vim.cmd([[
highlight LineNr guifg=#FFF36D guibg=NONE
highlight CursorLineNr guifg=#FF0000 guibg=NONE
highlight Normal guibg=NONE
highlight NormalFloat guibg=NONE
highlight SignColumn guibg=NONE
]])

vim.opt.relativenumber = false
vim.opt.number = true
