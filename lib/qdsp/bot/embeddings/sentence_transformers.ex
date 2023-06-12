defmodule QDSP.Bot.Embeddings.SentenceTransformers do
  @behaviour QDSP.Bot.Embeddings.Adapter

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

  @impl true
  def embed(texts) do
    QDSP.Bot.Embeddings.Model
    |> Nx.Serving.batched_run(texts)
    |> Nx.to_list()
    |> then(&{:ok, &1})
  end
end
