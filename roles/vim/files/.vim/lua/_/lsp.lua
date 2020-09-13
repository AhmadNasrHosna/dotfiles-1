-- for debugging
-- :lua require('vim.lsp.log').set_level("debug")
-- :lua print(vim.inspect(vim.lsp.buf_get_clients()))
-- :lua print(vim.lsp.get_log_path())
-- :lua print(vim.inspect(vim.tbl_keys(vim.lsp.callbacks)))

local has_lsp, lsp = pcall(require, 'nvim_lsp')

if not has_lsp then
  return
end

local has_completion = pcall(require, 'completion')
local has_diagnostic, diagnostic = pcall(require, 'diagnostic')
local utils = require'_.utils'
local map_opts = { noremap=true, silent=true }

if pcall(require, '_.completion') then
  require'_.completion'.setup()
end

if has_completion then
  -- Lazy loaded because it breaks in completion is not loaded already
  pcall(vim.cmd, [[packadd completion-buffers]])
  vim.api.nvim_command("autocmd BufEnter * lua require'completion'.on_attach()")
end

vim.api.nvim_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

local callbacks = {}

local wrap_hover = function(bufnr, winnr)
  local hover_len = #vim.api.nvim_buf_get_lines(bufnr,0,-1,false)[1]
  local win_width = vim.api.nvim_win_get_width(0)
  if hover_len > win_width then
    vim.api.nvim_win_set_width(winnr,math.min(hover_len,win_width))
    vim.api.nvim_win_set_height(winnr,math.ceil(hover_len/win_width))
    vim.wo[winnr].wrap = true  -- luacheck: ignore 122
  end
end

-- https://github.com/scalameta/nvim-metals/blob/20fd8d5812f3ac2c98ab97f2049c3eabce272b43/lua/metals.lua#L138-L160
callbacks['textDocument/hover'] = function(_, method, result)
  local opts = {
    pad_left = 1;
    pad_right = 1;
  }
  lsp.util.focusable_float(method, function()
    if not (result and result.contents) then
      return
    end
    local markdown_lines = lsp.util.convert_input_to_markdown_lines(result.contents)
    markdown_lines = lsp.util.trim_empty_lines(markdown_lines)
    if vim.tbl_isempty(markdown_lines) then
      return
    end
    local bufnr, winnr = lsp.util.fancy_floating_markdown(markdown_lines, opts)
    lsp.util.close_preview_autocmd({"CursorMoved", "BufHidden", "InsertCharPre"}, winnr)
    wrap_hover(bufnr, winnr)
    return bufnr, winnr
  end)
end

local on_attach = function(client)
  local resolved_capabilities = client.resolved_capabilities

  if has_diagnostic then
    diagnostic.on_attach(client)
  end

  -- Mappings.
  -- [TODO] Check conflicting mappings with these ones
  utils.bmap('n', 'gd', '<Cmd>lua vim.lsp.buf.declaration()<CR>', map_opts)
  utils.bmap('n', '<C-]>', '<Cmd>lua vim.lsp.buf.definition()<CR>', map_opts)
  utils.bmap('n', 'ga', '<Cmd>lua vim.lsp.buf.code_action()<CR>', map_opts)
  if vim.api.nvim_buf_get_option(0, 'filetype') ~= 'vim' then
    utils.bmap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', map_opts)
  end
  utils.bmap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', map_opts)
  utils.bmap('n', '<leader>r', '<cmd>lua vim.lsp.buf.rename()<CR>', map_opts)
  utils.bmap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', map_opts)
  utils.bmap('n', '<leader>ld', '<cmd>lua vim.lsp.util.show_line_diagnostics()<CR>', map_opts)

  vim.api.nvim_command('autocmd CursorHold <buffer> lua vim.lsp.util.show_line_diagnostics()')

  if resolved_capabilities.document_highlight then
    vim.api.nvim_command('autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()')
    vim.api.nvim_command('autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()')
    vim.api.nvim_command('autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()')
  end
end

local servers = {
  {name = 'ocamlls'},
  {name = 'cssls'},
  {name = 'bashls'},
  {name = 'vimls'},
  {name = 'pyls'},
  {
    name = 'tsserver',
    config = {
      -- cmd = {
      --   "typescript-language-server",
      --   "--stdio",
      --   "--tsserver-log-file",
      --   "tslog"
      -- }
      -- See https://github.com/neovim/nvim-lsp/issues/237
      root_dir = lsp.util.root_pattern("tsconfig.json", ".git"),
    }
  },
  {
    name = 'rls',
    config = {
      settings = {
        rust = {
          clippy_preference = 'on'
        }
      },
    }
  },
  -- {
  --   name = 'sumneko_lua',
  --   config = {
  --     settings = {
  --       Lua = {
  --         runtime={
  --           version="LuaJIT",
  --         },
  --         diagnostics={
  --           enable=true,
  --           globals={"vim", "spoon", "hs"},
  --         },
  --       }
  --     },
  --   }
  -- },
  -- JSON & YAML schemas http://schemastore.org/json/
  {
    name = 'jsonls',
    config = {
      settings = {
        json = {
          schemas = {
            {
              description = 'TypeScript compiler configuration file',
              fileMatch = {'tsconfig.json', 'tsconfig.*.json'},
              url = 'http://json.schemastore.org/tsconfig'
            },
            {
              description = 'Lerna config',
              fileMatch = {'lerna.json'},
              url = 'http://json.schemastore.org/lerna'
            },
            {
              description = 'Babel configuration',
              fileMatch = {'.babelrc.json', '.babelrc', 'babel.config.json'},
              url = 'http://json.schemastore.org/lerna'
            },
            {
              description = 'ESLint config',
              fileMatch = {'.eslintrc.json', '.eslintrc'},
              url = 'http://json.schemastore.org/eslintrc'
            },
            {
              description = 'Bucklescript config',
              fileMatch = {'bsconfig.json'},
              url = 'https://bucklescript.github.io/bucklescript/docson/build-schema.json'
            },
            {
              description = 'Prettier config',
              fileMatch = {'.prettierrc', '.prettierrc.json', 'prettier.config.json'},
              url = 'http://json.schemastore.org/prettierrc'
            },
            {
              description = 'Vercel Now config',
              fileMatch = {'now.json', 'vercel.json'},
              url = 'http://json.schemastore.org/now'
            },
            {
              description = 'Stylelint config',
              fileMatch = {'.stylelintrc', '.stylelintrc.json', 'stylelint.config.json'},
              url = 'http://json.schemastore.org/stylelintrc'
            },
          }
        },
      },
    }
  },
  {
    name = 'yamlls',
    config = {
      settings = {
        yaml = {
          schemas = {
            ['http://json.schemastore.org/github-workflow'] = '.github/workflows/*.{yml,yaml}',
            ['http://json.schemastore.org/github-action'] = '.github/action.{yml,yaml}',
            ['http://json.schemastore.org/ansible-stable-2.9'] = 'roles/tasks/*.{yml,yaml}',
            ['http://json.schemastore.org/prettierrc'] = '.prettierrc.{yml,yaml}',
            ['http://json.schemastore.org/stylelintrc'] = '.stylelintrc.{yml,yaml}',
            ['http://json.schemastore.org/circleciconfig'] = '.circleci/**/*.{yml,yaml}'
          },
          format = {
            enable = true
          },
          validate = true,
          hover = true,
          completion = true
        }
      },
    }
  },
}

for _, server in ipairs(servers) do
  local server_disabled = (server.disabled ~= nil and server.disabled) or false

  if not server_disabled then
    if server.config then
      server.config.on_attach = on_attach
      server.config.callbacks = vim.tbl_deep_extend('keep', {}, callbacks, vim.lsp.callbacks)
    else
      server.config = {
        on_attach = on_attach,
        callbacks = vim.tbl_deep_extend('keep', {}, callbacks, vim.lsp.callbacks),
      }
    end


    lsp[server.name].setup(server.config)
  end
end
