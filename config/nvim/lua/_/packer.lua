-- Only required if you have packer in your `opt` pack
local packer_exists = pcall(vim.api.nvim_command, [[packadd packer.nvim]])

if not packer_exists then
  if vim.fn.input 'Download Packer? (y for yes) ' ~= 'y' then
    return
  end

  local directory = string.format(
    '%s/pack/packer/opt/',
    vim.fn.stdpath 'config'
  )

  vim.fn.mkdir(directory, 'p')

  local out = vim.fn.system(
    string.format(
      'git clone %s %s',
      'https://github.com/wbthomason/packer.nvim',
      directory .. '/packer.nvim'
    )
  )

  print(out)
  print 'Downloading packer.nvim...'
  vim.fn.execute 'packadd packer.nvim'

  return
end

local packer = require 'packer'
local au = require '_.utils.au'
local lisps = { 'lisp', 'scheme', 'clojure', 'fennel' }
local plugins = {
  { 'https://github.com/wbthomason/packer.nvim', opt = true },
  { 'https://github.com/antoinemadec/FixCursorHold.nvim' },
  { 'https://github.com/windwp/nvim-autopairs' },
  { 'https://github.com/camspiers/snap' },
  {
    'https://github.com/junegunn/fzf.vim',
    -- I have the bin globally, so don't build, and just grab plugin directory
    requires = { { 'https://github.com/junegunn/fzf' } },
  },
  {
    'https://github.com/kyazdani42/nvim-tree.lua',
    keys = { '-' },
    cmd = { 'NvimTreeToggle', 'NvimTreeFindFile' },
    config = function()
      -- vim-fugitive :GBrowse depends on netrw & this has to be set as early as possible
      -- maybe switch to https://github.com/ruifm/gitlinker.nvim?
      -- I only use fugitive for GBrowse 99% of the time & git branch in the statusline
      vim.g.nvim_tree_disable_netrw = 0
    end,
  },
  { 'https://github.com/duggiefresh/vim-easydir' },
  { 'https://github.com/junegunn/vim-peekaboo' },
  {
    'https://github.com/mbbill/undotree',
    opt = true,
    cmd = 'UndotreeToggle',
  },
  { 'https://github.com/mhinz/vim-sayonara', opt = true, cmd = 'Sayonara' },
  { 'https://github.com/mhinz/vim-startify' },
  { 'https://github.com/nelstrom/vim-visual-star-search' },
  { 'https://github.com/tpope/tpope-vim-abolish' },
  { 'https://github.com/tpope/vim-eunuch' },
  { 'https://github.com/tpope/vim-repeat' },
  { 'https://github.com/machakann/vim-sandwich' },
  { 'https://github.com/tomtom/tcomment_vim', keys = { 'gc' } },
  { 'https://github.com/wincent/loupe' },
  { 'https://github.com/wincent/terminus' },
  { 'https://github.com/simrat39/symbols-outline.nvim', cmd = 'SymbolsOutline' },
  { 'https://github.com/christoomey/vim-tmux-navigator', opt = true },
  { 'https://github.com/kevinhwang91/nvim-bqf' },
  -- LSP/Autocompletion {{{
  {
    'https://github.com/neovim/nvim-lspconfig',
    requires = {
      { 'https://github.com/tjdevries/lsp_extensions.nvim' },
      {
        'https://github.com/folke/todo-comments.nvim',
        config = function()
          require('todo-comments').setup {}
        end,
      },
      { 'https://github.com/glepnir/lspsaga.nvim' },
      { 'https://github.com/ray-x/lsp_signature.nvim' },
    },
  },
  { 'https://github.com/mhartington/formatter.nvim' },
  {
    'https://github.com/L3MON4D3/LuaSnip',
    requires = {
      { 'https://github.com/rafamadriz/friendly-snippets' },
    },
  },
  {
    'https://github.com/hrsh7th/nvim-compe',
    requires = {
      { 'https://github.com/tami5/compe-conjure', ft = lisps },
      { 'https://github.com/andersevenrud/compe-tmux' },
    },
  },
  {
    'https://github.com/nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    requires = {
      { 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects' },
      { 'https://github.com/p00f/nvim-ts-rainbow' },
      {
        'https://github.com/nvim-treesitter/playground',
        cmd = 'TSPlaygroundToggle',
      },
    },
  },
  -- Syntax {{{
  {
    'https://github.com/norcalli/nvim-colorizer.lua',
    config = function()
      -- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
      require('colorizer').setup({
        '*',
        '!vim',
        '!packer',
      }, {
        css = true,
      })
    end,
  },
  {
    'https://github.com/kristijanhusak/orgmode.nvim',
    config = function()
      require('orgmode').setup {
        org_agenda_files = { '~/Sync/org/*' },
        org_default_notes_file = '~/Sync/refile.org',
      }
    end,
  },
  {
    'https://github.com/plasticboy/vim-markdown',
    ft = { 'markdown' },
    requires = {
      { 'https://github.com/godlygeek/tabular' },
      { 'https://github.com/npxbr/glow.nvim', cmd = 'Glow' },
    },
  },
  { 'https://github.com/jez/vim-github-hub' },
  -- Clojure
  { 'https://github.com/guns/vim-sexp', ft = lisps },
  { 'https://github.com/Olical/conjure', tag = 'v4.22.0', ft = lisps },
  -- }}}

  -- Git {{{
  {
    'https://github.com/rhysd/conflict-marker.vim',
    config = function()
      -- disable the default highlight group
      vim.g.conflict_marker_highlight_group = ''

      -- Include text after begin and end markers
      vim.g.conflict_marker_begin = '^<<<<<<< .*$'
      vim.g.conflict_marker_end = '^>>>>>>> .*$'
    end,
  },
  {
    'https://github.com/sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen' },
    config = function()
      require('diffview').setup {
        file_panel = {
          use_icons = false,
        },
      }
    end,
  },
  {
    'https://github.com/tpope/vim-fugitive',
    requires = {
      { 'https://github.com/tpope/vim-rhubarb' },
    },
  },
  {
    'https://github.com/rhysd/git-messenger.vim',
    opt = true,
    cmd = 'GitMessenger',
    keys = '<Plug>(git-messenger)',
  },
  -- }}}

  -- Themes, UI & eye cnady {{{
  { 'https://github.com/andreypopp/vim-colors-plain', opt = true },
  { 'https://github.com/liuchengxu/space-vim-theme', opt = true },
  { 'https://github.com/rakr/vim-two-firewatch', opt = true },
  { 'https://github.com/logico-dev/typewriter', opt = true },
  { 'https://github.com/arzg/vim-substrata', opt = true },
  { 'https://github.com/haishanh/night-owl.vim', opt = true },
  { 'https://github.com/lifepillar/vim-gruvbox8', opt = true },
  { 'https://github.com/bluz71/vim-moonfly-colors', opt = true },
  { 'https://github.com/axvr/photon.vim', opt = true },
  { 'https://github.com/owickstrom/vim-colors-paramount', opt = true },
}

packer.init {
  package_root = string.format('%s/pack', vim.fn.stdpath 'config'),
  display = {
    non_interactive = vim.env.PACKER_NON_INTERACTIVE or false,
    open_cmd = function()
      return require('packer.util').float { border = 'single' }
    end,
  },
}

return packer.startup(function(use)
  au.augroup('__packer__', function()
    au.autocmd('BufWritePost', 'plugins.lua', 'PackerCompile')
  end)

  use(plugins)
end)
