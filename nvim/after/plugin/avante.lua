require("avante").setup({
  provider = "gemini",
  providers = {
    -- claude = {
    --   model = "claude-3-5-sonnet-20240620",
    -- },
    gemini = {
      model = "gemini-1.5-pro-latest",
    },
    ollama = {
      endpoint = "http://127.0.0.1:1234/v1/chat/completions",
      model = "llama3",
    },
    -- New provider for LM Studio
    lmstudio = {
      -- This tells avante to treat this provider like the built-in ollama provider
      __inherited_from = "openai",
      -- This endpoint must match the one in your LM Studio server
      endpoint = "http://127.0.0.1:1234/v1",
      -- The model name doesn't matter as much, LM Studio uses the loaded model
      -- model = "openai/gpt-oss-20b",
      model = "deepseek/deepseek-r1-0528-qwen3-8b",
      api_key_name = 'API_TEST',
    },
  },
  input = {
    provider = "snacks",
  },
  spinner = {
    editing = { "⡀", "⠄", "⠂", "⠁", "⠈", "⠐", "⠠", "⢀", "⣀", "⢄", "⢂", "⢁", "⢈", "⢐", "⢠", "⣠", "⢤", "⢢", "⢡", "⢨", "⢰", "⣰", "⢴", "⢲", "⢱", "⢸", "⣸", "⢼", "⢺", "⢹", "⣹", "⢽", "⢻", "⣻", "⢿", "⣿" },
    generating = { "·", "✢", "✳", "∗", "✻", "✽" }, -- Spinner characters for the 'generating' state
    thinking = { "🤯", "🙄" }, -- Spinner characters for the 'thinking' state
  },
  mappings = {
    sidebar = {
      switch_provider = "<leader>ap",
    },
  },
})
