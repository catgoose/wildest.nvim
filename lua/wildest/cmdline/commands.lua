-- Command table: maps command names to their expand types
-- Based on Vim's internal command table. Only commands with special
-- expand types are listed; unlisted commands default to flag-based detection.

local M = {}

-- Expand type constants
M.EXPAND = {
  NOTHING = "nothing",
  COMMAND = "command",
  FILE = "file",
  DIR = "dir",
  BUFFER = "buffer",
  HELP = "help",
  OPTION = "option",
  TAGS = "tags",
  COLOR = "color",
  COMPILER = "compiler",
  HIGHLIGHT = "highlight",
  AUGROUP = "augroup",
  FUNCTION = "function",
  USER_FUNC = "user_func",
  USER_COMMANDS = "user_commands",
  FILE_IN_PATH = "file_in_path",
  ENVIRONMENT = "environment",
  LANGUAGE = "language",
  EXPRESSION = "expression",
  LUA = "lua",
  EVENT = "event",
  PACKADD = "packadd",
  FILETYPE = "filetype",
  SHELLCMD = "shellcmd",
  SIGN = "sign",
  MESSAGES = "messages",
  HISTORY = "history",
  MAPCLEAR = "mapclear",
  ARGLIST = "arglist",
  CHECKHEALTH = "checkhealth",
  SYNTAX = "syntax",
  CUSTOM = "custom",
}

local E = M.EXPAND

-- Commands with explicit expand types
-- Format: command_name = expand_type
M.command_expand = {
  -- File commands
  edit = E.FILE,
  e = E.FILE,
  split = E.FILE,
  sp = E.FILE,
  vsplit = E.FILE,
  vs = E.FILE,
  tabedit = E.FILE,
  tabe = E.FILE,
  tabnew = E.FILE,
  new = E.FILE,
  vnew = E.FILE,
  view = E.FILE,
  sview = E.FILE,
  read = E.FILE,
  r = E.FILE,
  write = E.FILE,
  w = E.FILE,
  saveas = E.FILE,
  sav = E.FILE,
  source = E.FILE,
  so = E.FILE,
  runtime = E.FILE,
  ru = E.FILE,
  drop = E.FILE,
  badd = E.FILE,
  argadd = E.FILE,
  argedit = E.FILE,
  argglobal = E.FILE,
  arglocal = E.FILE,
  next = E.FILE,
  n = E.FILE,
  previous = E.FILE,
  prev = E.FILE,
  first = E.FILE,
  fir = E.FILE,
  last = E.FILE,
  la = E.FILE,
  wnext = E.FILE,
  wn = E.FILE,
  wprevious = E.FILE,
  wp = E.FILE,
  wNext = E.FILE,
  wN = E.FILE,
  diffsplit = E.FILE,
  diffpatch = E.FILE,
  pedit = E.FILE,
  ped = E.FILE,

  -- Dir commands
  cd = E.DIR,
  chdir = E.DIR,
  lcd = E.DIR,
  lchdir = E.DIR,
  tcd = E.DIR,
  tchdir = E.DIR,

  -- File in path
  find = E.FILE_IN_PATH,
  sfind = E.FILE_IN_PATH,
  tabfind = E.FILE_IN_PATH,

  -- Buffer commands
  buffer = E.BUFFER,
  b = E.BUFFER,
  sbuffer = E.BUFFER,
  sb = E.BUFFER,
  bdelete = E.BUFFER,
  bd = E.BUFFER,
  bwipeout = E.BUFFER,
  bw = E.BUFFER,
  bunload = E.BUFFER,
  bun = E.BUFFER,
  checktime = E.BUFFER,

  -- Help
  help = E.HELP,
  h = E.HELP,
  helpgrep = E.HELP,

  -- Tags
  tag = E.TAGS,
  ta = E.TAGS,
  stag = E.TAGS,
  sta = E.TAGS,
  ptag = E.TAGS,
  pta = E.TAGS,
  ltag = E.TAGS,
  tselect = E.TAGS,
  ts = E.TAGS,
  stselect = E.TAGS,
  sts = E.TAGS,
  tjump = E.TAGS,
  tj = E.TAGS,
  stjump = E.TAGS,
  stj = E.TAGS,
  ptselect = E.TAGS,
  pts = E.TAGS,
  ptjump = E.TAGS,
  ptj = E.TAGS,

  -- Options
  set = E.OPTION,
  se = E.OPTION,
  setglobal = E.OPTION,
  setg = E.OPTION,
  setlocal = E.OPTION,
  setl = E.OPTION,

  -- Highlight
  highlight = E.HIGHLIGHT,
  hi = E.HIGHLIGHT,
  echohl = E.HIGHLIGHT,

  -- Color
  colorscheme = E.COLOR,
  colo = E.COLOR,

  -- Compiler
  compiler = E.COMPILER,
  comp = E.COMPILER,

  -- Augroup
  augroup = E.AUGROUP,

  -- Function
  ["function"] = E.FUNCTION,
  fu = E.FUNCTION,
  delfunction = E.USER_FUNC,
  delf = E.USER_FUNC,

  -- Commands
  command = E.COMMAND,
  com = E.COMMAND,
  delcommand = E.USER_COMMANDS,
  delc = E.USER_COMMANDS,

  -- Language
  language = E.LANGUAGE,
  lan = E.LANGUAGE,

  -- Autocmd / events
  autocmd = E.EVENT,
  au = E.EVENT,
  doautocmd = E.EVENT,
  doau = E.EVENT,
  doautoall = E.EVENT,

  -- Expression
  let = E.EXPRESSION,
  ["if"] = E.EXPRESSION,
  ["elseif"] = E.EXPRESSION,
  ["while"] = E.EXPRESSION,
  ["for"] = E.EXPRESSION,
  echo = E.EXPRESSION,
  echon = E.EXPRESSION,
  execute = E.EXPRESSION,
  exe = E.EXPRESSION,
  echomsg = E.EXPRESSION,
  echoerr = E.EXPRESSION,
  call = E.EXPRESSION,
  ["return"] = E.EXPRESSION,

  -- Lua
  lua = E.LUA,
  luado = E.LUA,
  luafile = E.FILE,

  -- Packadd
  packadd = E.PACKADD,
  pa = E.PACKADD,

  -- Filetype
  filetype = E.FILETYPE,
  filet = E.FILETYPE,

  -- Shell commands
  ["!"] = E.SHELLCMD,
  terminal = E.SHELLCMD,
  term = E.SHELLCMD,
  make = E.SHELLCMD,

  -- Arglist
  argdelete = E.ARGLIST,
  argd = E.ARGLIST,

  -- Checkhealth
  checkhealth = E.CHECKHEALTH,
  che = E.CHECKHEALTH,

  -- Messages
  messages = E.MESSAGES,
  mes = E.MESSAGES,

  -- History
  history = E.HISTORY,
  his = E.HISTORY,

  -- Sign
  sign = E.SIGN,

  -- Syntax
  syntax = E.SYNTAX,
  sy = E.SYNTAX,

  -- Substitute (special handling)
  substitute = E.NOTHING,
  s = E.NOTHING,
  smagic = E.NOTHING,
  sm = E.NOTHING,
  snomagic = E.NOTHING,
  sno = E.NOTHING,
  global = E.NOTHING,
  g = E.NOTHING,
  vglobal = E.NOTHING,
  v = E.NOTHING,
}

-- Command modifiers (these don't consume arguments, just modify the next command)
M.modifiers = {
  aboveleft = true,
  abo = true,
  belowright = true,
  bel = true,
  botright = true,
  bo = true,
  browse = true,
  bro = true,
  confirm = true,
  conf = true,
  hide = true,
  hid = true,
  keepalt = true,
  keepa = true,
  keepjumps = true,
  keepj = true,
  keepmarks = true,
  kee = true,
  keeppatterns = true,
  keepp = true,
  leftabove = true,
  lefta = true,
  lockmarks = true,
  loc = true,
  noautocmd = true,
  noa = true,
  noswapfile = true,
  nos = true,
  rightbelow = true,
  rightb = true,
  sandbox = true,
  san = true,
  silent = true,
  sil = true,
  tab = true,
  topleft = true,
  to = true,
  unsilent = true,
  uns = true,
  verbose = true,
  verb = true,
  vertical = true,
  vert = true,
  horizontal = true,
  hor = true,
}

return M
