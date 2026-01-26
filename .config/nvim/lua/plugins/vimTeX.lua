return {
  "lervag/vimtex",
  lazy = false,     -- We don't want to lazy load VimTeX
  -- tag = "v2.15", -- Uncomment to pin to a specific release
  init = function()
    -- VimTeX configuration goes here
    vim.g.vimtex_view_method = "zathura"
  end
}
