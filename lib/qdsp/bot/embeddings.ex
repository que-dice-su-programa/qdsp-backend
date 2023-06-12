defmodule QDSP.Bot.Embeddings do
  @moduledoc """
  This module is responsible for creating text embeddings using the configured adapter.
  """

  @spec embed(String.t() | list(String.t())) :: {:ok, [float()] | list([float()])}
  def embed(texts) when is_list(texts) do
    embeddings_adapter().embed(texts)
  end

  def embed(text) do
    [text]
    |> embed()
    |> then(fn {:ok, [embedding]} -> {:ok, embedding} end)
  end

  # Uses cosine similarity to calculate the relatedness of two vectors
  # https://en.wikipedia.org/wiki/Cosine_similarity
  def relatedness(a, b) do
    dot_product = :lists.sum(for {a, b} <- Enum.zip(a, b), do: a * b)
    magnitude_a = :math.sqrt(:lists.sum(for a <- a, do: a * a))
    magnitude_b = :math.sqrt(:lists.sum(for b <- b, do: b * b))

    if magnitude_a == 0 or magnitude_b == 0 do
      0.0
    else
      dot_product / (magnitude_a * magnitude_b)
    end
  end

  defp embeddings_adapter() do
    Application.get_env(:qdsp, :embeddings_adapter)
  end
end
