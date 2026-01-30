return {
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/nvim-cmp", 
        },
        config = function()
            -- 1. Setup Mason (Installs the binaries)
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = { "gopls", "ts_ls", "clangd", "lua_ls", "html", "cssls", "jsonls" },
                automatic_installation = true,
            })

            -- 2. Prepare Capabilities (still needed for nvim-cmp completion)
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- 3. Define your servers and specific overrides
            local servers = {
                gopls = {},
                ts_ls = {},
                clangd = {},
                html = {},
                cssls = {},
                jsonls = {},
                lua_ls = {
                    settings = {
                        Lua = {
                            diagnostics = { globals = { "vim" } },
                        },
                    },
                },
            }

            -- 4. New Neovim 0.11+ Loop
            for server, config in pairs(servers) do
                -- Add capabilities to the config
                config.capabilities = capabilities
                
                -- Register the config using the new native API
                -- This merges your config with the defaults from nvim-lspconfig
                vim.lsp.config(server, config)
                
                -- Enable the server (registers it to auto-attach on the correct filetypes)
                vim.lsp.enable(server)
            end
        end,
    }
}
