-- patina: the ${DISPLAY_NAME} theme for neovim, from its base16 palette. `patina theme
-- set` overwrites this file; copy it under another name to change it.
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.background = "${VARIANT}"
vim.o.termguicolors = true
vim.g.colors_name = "patina-${THEME}"

local c = {
  base00 = "${BASE00}", base01 = "${BASE01}", base02 = "${BASE02}", base03 = "${BASE03}",
  base04 = "${BASE04}", base05 = "${BASE05}", base06 = "${BASE06}", base07 = "${BASE07}",
  base08 = "${BASE08}", base09 = "${BASE09}", base0A = "${BASE0A}", base0B = "${BASE0B}",
  base0C = "${BASE0C}", base0D = "${BASE0D}", base0E = "${BASE0E}", base0F = "${BASE0F}",
}

-- The terminal inside neovim gets the same sixteen colours as kitty.
for i, key in ipairs({ "00", "08", "0B", "0A", "0D", "0E", "0C", "05",
                       "03", "08", "0B", "0A", "0D", "0E", "0C", "07" }) do
  vim.g["terminal_color_" .. (i - 1)] = c["base" .. key]
end

local groups = {
  -- the editor
  Normal = { fg = c.base05, bg = c.base00 },
  NormalFloat = { fg = c.base05, bg = c.base01 },
  FloatBorder = { fg = c.base03, bg = c.base01 },
  Cursor = { fg = c.base00, bg = c.base05 },
  CursorLine = { bg = c.base01 },
  CursorColumn = { bg = c.base01 },
  ColorColumn = { bg = c.base01 },
  CursorLineNr = { fg = c.base0E, bg = c.base01, bold = true },
  LineNr = { fg = c.base03 },
  SignColumn = { fg = c.base03 },
  FoldColumn = { fg = c.base03 },
  Folded = { fg = c.base03, bg = c.base01 },
  Visual = { bg = c.base02 },
  Search = { fg = c.base00, bg = c.base0A },
  IncSearch = { fg = c.base00, bg = c.base09 },
  CurSearch = { fg = c.base00, bg = c.base09 },
  Substitute = { fg = c.base00, bg = c.base0A },
  MatchParen = { bg = c.base02, bold = true },
  Pmenu = { fg = c.base05, bg = c.base01 },
  PmenuSel = { fg = c.base00, bg = c.base0E },
  PmenuSbar = { bg = c.base02 },
  PmenuThumb = { bg = c.base04 },
  WildMenu = { fg = c.base00, bg = c.base0E },
  StatusLine = { fg = c.base05, bg = c.base02 },
  StatusLineNC = { fg = c.base04, bg = c.base01 },
  TabLine = { fg = c.base04, bg = c.base01 },
  TabLineSel = { fg = c.base07, bg = c.base02 },
  TabLineFill = { bg = c.base01 },
  WinSeparator = { fg = c.base02 },
  VertSplit = { fg = c.base02 },
  NonText = { fg = c.base03 },
  Whitespace = { fg = c.base02 },
  SpecialKey = { fg = c.base03 },
  EndOfBuffer = { fg = c.base01 },
  Conceal = { fg = c.base0D },
  Directory = { fg = c.base0D },
  Title = { fg = c.base0D, bold = true },
  ErrorMsg = { fg = c.base08 },
  WarningMsg = { fg = c.base09 },
  MoreMsg = { fg = c.base0B },
  ModeMsg = { fg = c.base0B },
  Question = { fg = c.base0D },
  QuickFixLine = { bg = c.base01 },

  -- syntax, after the base16 styling guide
  Comment = { fg = c.base03, italic = true },
  Constant = { fg = c.base09 },
  String = { fg = c.base0B },
  Character = { fg = c.base08 },
  Number = { fg = c.base09 },
  Boolean = { fg = c.base09 },
  Float = { fg = c.base09 },
  Identifier = { fg = c.base08 },
  Function = { fg = c.base0D },
  Statement = { fg = c.base08 },
  Conditional = { fg = c.base0E },
  Repeat = { fg = c.base0A },
  Label = { fg = c.base0A },
  Operator = { fg = c.base05 },
  Keyword = { fg = c.base0E },
  Exception = { fg = c.base08 },
  PreProc = { fg = c.base0A },
  Include = { fg = c.base0D },
  Define = { fg = c.base0E },
  Macro = { fg = c.base08 },
  Type = { fg = c.base0A },
  StorageClass = { fg = c.base0A },
  Structure = { fg = c.base0E },
  Typedef = { fg = c.base0A },
  Special = { fg = c.base0C },
  SpecialChar = { fg = c.base0F },
  Tag = { fg = c.base0A },
  Delimiter = { fg = c.base0F },
  SpecialComment = { fg = c.base0C },
  Debug = { fg = c.base08 },
  Underlined = { fg = c.base0D, underline = true },
  Error = { fg = c.base00, bg = c.base08 },
  Todo = { fg = c.base0A, bg = c.base01 },

  -- tree-sitter: variables and fields in the plain foreground, the rest links above
  ["@variable"] = { fg = c.base05 },
  ["@variable.builtin"] = { fg = c.base08 },
  ["@variable.member"] = { fg = c.base05 },
  ["@field"] = { fg = c.base05 },
  ["@property"] = { fg = c.base05 },
  ["@module"] = { fg = c.base0D },

  -- diagnostics, diffs, spelling
  DiagnosticError = { fg = c.base08 },
  DiagnosticWarn = { fg = c.base0A },
  DiagnosticInfo = { fg = c.base0D },
  DiagnosticHint = { fg = c.base0C },
  DiagnosticOk = { fg = c.base0B },
  DiagnosticUnderlineError = { undercurl = true, sp = c.base08 },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.base0A },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.base0D },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.base0C },
  LspReferenceText = { bg = c.base02 },
  LspReferenceRead = { bg = c.base02 },
  LspReferenceWrite = { bg = c.base02 },
  DiffAdd = { fg = c.base0B, bg = c.base01 },
  DiffChange = { fg = c.base03, bg = c.base01 },
  DiffDelete = { fg = c.base08, bg = c.base01 },
  DiffText = { fg = c.base0D, bg = c.base01 },
  Added = { fg = c.base0B },
  Changed = { fg = c.base0D },
  Removed = { fg = c.base08 },
  diffAdded = { fg = c.base0B },
  diffRemoved = { fg = c.base08 },
  GitSignsAdd = { fg = c.base0B },
  GitSignsChange = { fg = c.base0D },
  GitSignsDelete = { fg = c.base08 },
  SpellBad = { undercurl = true, sp = c.base08 },
  SpellCap = { undercurl = true, sp = c.base0D },
  SpellRare = { undercurl = true, sp = c.base0E },
  SpellLocal = { undercurl = true, sp = c.base0C },
}

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end
