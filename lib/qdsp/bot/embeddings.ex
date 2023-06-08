defmodule QDSP.Bot.Embeddings do
  @moduledoc """
  This module is responsible for creating text embeddings.
  """

  @model "sentence-transformers/all-MiniLM-L6-v2"
  @batch_size 100

  @spec serving() :: Nx.Serving.t()
  def serving() do
    {:ok, %{model: model, params: params}} = Bumblebee.load_model({:hf, @model})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, @model})
    {_init_fn, predict_fn} = Axon.build(model, compiler: EXLA)

    # credo:disable-for-lines:7 Credo.Check.Refactor.PipeChainStart
    Nx.Serving.new(fn _opts ->
      fn %{size: size} = inputs ->
        inputs = Nx.Batch.pad(inputs, @batch_size - size)
        predict_fn.(params, inputs)[:pooled_state]
      end
    end)
    |> Nx.Serving.client_preprocessing(fn input ->
      inputs =
        Bumblebee.apply_tokenizer(tokenizer, input,
          length: 128,
          return_token_type_ids: false
        )

      {Nx.Batch.concatenate([inputs]), :ok}
    end)
  end

  @spec embed(String.t()) :: {:ok, [float()]}
  def embed(text) do
    QDSP.Bot.EmbeddingsModel
    |> Nx.Serving.batched_run([text])
    |> Nx.to_flat_list()
    |> then(&{:ok, &1})
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
end
