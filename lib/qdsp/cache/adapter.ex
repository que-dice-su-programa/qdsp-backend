defmodule QDSP.Cache.Adapter do
  @moduledoc """
  Behaviour for a cache
  """

  @callback set(String.t(), any()) :: :ok | {:error, any}
  @callback get(String.t()) :: {:ok, any} | {:error, any}
end
