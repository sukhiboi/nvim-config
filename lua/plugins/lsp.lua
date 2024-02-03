local servers = { "lua_ls", "rust_analyzer", "tsserver" }

local mason_ensure_installed = {
	-- formatters
	"eslint_d",
	"jq",
	"stylua",
	"prettierd",
	-- "rustfmt", -- not supported on raspberrypi
	-- diagnostics
	"actionlint",
	"checkstyle",
	"jsonlint",
	"markdownlint",
	"stylelint",
	-- code_actions
	"eslint_d",
}


local function setup_none_ls(null_ls)
	null_ls.setup({
		null_ls.builtins.code_actions.eslint_d,

		null_ls.builtins.diagnostics.actionlint,
		null_ls.builtins.diagnostics.checkstyle.with({
			extra_args = { "-c", "/google_checks.xml" },
		}),
		null_ls.builtins.diagnostics.jsonlint,
		null_ls.builtins.diagnostics.markdownlint,
		null_ls.builtins.diagnostics.stylelint,

		null_ls.builtins.formatting.eslint_d,
		null_ls.builtins.formatting.jq,
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.formatting.prettierd,
		null_ls.builtins.formatting.rustfmt,

	})
end

return {
	{
		"williamboman/mason.nvim", -- Thing to install LSP servers, linters, and formatters
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = false,
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = servers,
				automatic_installation = true
			})
		end
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim", -- Only use to make sure these LSP servers are installed
		lazy = false,
		config = function()
			require('mason-tool-installer').setup({
				ensure_installed = mason_ensure_installed,
				auto_update = true,
			})
		end,
	},
	{
		'hrsh7th/cmp-nvim-lsp', -- Used to define source of snippets
		config = function()
			require('cmp_nvim_lsp').setup()
		end
	},
	{
		"neovim/nvim-lspconfig", -- Actual plugin which will connect buffers to LSPs
		lazy = false,
		dependencies = {
			"nvimtools/none-ls.nvim",
			"simrat39/rust-tools.nvim"
		},
		config = function()
			local null_ls = require("null-ls")
			local capabilities = require('cmp_nvim_lsp').default_capabilities()
			local lspconfig = require("lspconfig")

			for _, lsp in ipairs(servers) do
				lspconfig[lsp].setup {
					capabilities = capabilities,
				}
			end

			setup_none_ls(null_ls)

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					-- Enable completion triggered by <c-x><c-o>
					vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

					-- Buffer local mappings.
					-- See `:help vim.lsp.*` for documentation on any of the below functions
					local opts = { buffer = ev.buf }
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
					vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
					vim.keymap.set("n", "<leader>gf", function()
						vim.lsp.buf.format({ async = true })
					end, opts)
				end,
			})
		end,
	},
	{
		'hrsh7th/nvim-cmp', -- Auto completion plugin
		dependencies = {
			'L3MON4D3/LuaSnip', -- Snippet plugin
		},
		config = function()
			local luasnip = require("luasnip")
			local cmp = require("cmp")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					['<C-d>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<CR>'] = cmp.mapping.confirm {
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					},
					['<Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<S-Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { 'i', 's' }),
				}),
				sources = cmp.config.sources({
					{ name = 'nvim_lsp' },
				}),
			})
		end
	}
}
