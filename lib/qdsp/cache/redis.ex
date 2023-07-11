defmodule QDSP.Cache.Redis do
  @behaviour QDSP.Cache.Adapter

  @impl true
  def set(key, value) do
    with {:ok, json} <- Jason.encode(value),
         {:ok, _} <- Redix.command(:cache, ["SET", key, json]) do
      :ok
    end
  end

  @impl true
  def get(key) do
    case Redix.command(:cache, ["GET", key]) do
      {:ok, nil} -> {:ok, nil}
      {:ok, json} -> Jason.decode(json)
      e -> e
    end
  end
end
