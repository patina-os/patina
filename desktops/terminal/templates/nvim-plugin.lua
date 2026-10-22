-- patina21: turns on the ${DISPLAY_NAME} colour scheme when your configuration chose
-- none; a `colorscheme` line in your init.lua wins. Rewritten by `patina theme set`
-- while this first line stays; remove the line to keep the file as you leave it.
if vim.g.colors_name == nil or vim.g.colors_name == "default" then
  pcall(vim.cmd.colorscheme, "patina21-${THEME}")
end
