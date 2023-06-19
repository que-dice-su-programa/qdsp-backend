defmodule QDSP.Cache.Local do
  @behaviour QDSP.Cache.Adapter

  @impl true
  def set(key, value) do
    with {:ok, true} <- Cachex.put(:question_cache, key, value) do
      :ok
    end
  end

  @impl true
  def get(key) do
    Cachex.get(:question_cache, key)
  end
end
