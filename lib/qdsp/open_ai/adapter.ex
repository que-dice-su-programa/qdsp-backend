defmodule QDSP.OpenAi.Adapter do
  @moduledoc """
  Behaviour for interacting with OpenAI API
  """

  @callback chat_completion(String.t()) :: {:ok, String.t()} | {:error, any()}
  @callback chat_completion(String.t(), keyword()) :: {:ok, String.t()} | {:error, any()}
  @callback chat_completion(String.t(), keyword(), atom()) :: {:ok, String.t()} | {:error, any()}

  @callback embeddings(list(String.t())) :: {:ok, list(list(float))} | {:error, any()}
  @callback embeddings(list(String.t()), atom()) :: {:ok, list(list(float))} | {:error, any()}
end
