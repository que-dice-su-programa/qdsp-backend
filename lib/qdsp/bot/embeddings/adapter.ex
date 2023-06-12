defmodule QDSP.Bot.Embeddings.Adapter do
  @callback embed(list(String.t())) :: {:ok, list(float)}
end
