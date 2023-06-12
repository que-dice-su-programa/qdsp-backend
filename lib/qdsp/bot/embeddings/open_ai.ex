defmodule QDSP.Bot.Embeddings.OpenAi do
  @behaviour QDSP.Bot.Embeddings.Adapter

  @impl true
  def embed(texts) do
    open_ai().embeddings(texts)
  end

  defp open_ai() do
    Application.get_env(:qdsp, :open_ai)[:client] || QDSP.OpenAi.Client
  end
end
