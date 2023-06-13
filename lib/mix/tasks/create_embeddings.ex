defmodule Mix.Tasks.CreateEmbeddings do
  @moduledoc "The mix task to create embeddings: `mix help create_embeddings`"
  use Mix.Task

  alias QDSP.Bot.Embeddings

  def run(args) do
    Mix.Task.run("app.start")

    [:sumar, :psoe, :vox, :pp, :bildu, :erc, :junts]
    |> Enum.each(fn party -> create_embeddings_for(party, args) end)
  end

  defp create_embeddings_for(party, args) do
    IO.puts("Creating embeddings for #{party}")
    paragraphs = parse(party)

    IO.puts("-> Processing #{length(paragraphs)} paragraphs")

    embeddings = create_embeddings(paragraphs, args)

    write(party, paragraphs, embeddings)
  end

  defp parse(party) do
    "priv/programas/#{party}.txt"
    |> File.read!()
    |> String.replace(" -\n", "")
    |> String.replace("-\n", "")
    |> String.replace("  ", " ")
    |> String.replace("- ", "")
    |> String.replace(" \n", " ")
    |> String.split("\n", trim: true)
  end

  @batch_size %{
    Embeddings.OpenAi => 100,
    Embeddings.SentenceTransformers => 8
  }

  defp create_embeddings(paragraphs, args) do
    {:ok, progress} = Agent.start_link(fn -> 0 end)

    paragraphs
    |> Enum.chunk_every(@batch_size[embeddings_impl(args)])
    |> Enum.flat_map(fn chunks ->
      {:ok, embeddings} = embeddings_impl(args).embed(chunks)
      Agent.update(progress, fn count -> count + length(chunks) end)
      ProgressBar.render(Agent.get(progress, fn count -> count end), length(paragraphs))
      embeddings
    end)
  end

  @embedding_implementations %{
    "openai" => Embeddings.OpenAi,
    "sentence-transformers" => Embeddings.SentenceTransformers
  }
  defp embeddings_impl(args) do
    {[embeddings: impl], _, _} = OptionParser.parse(args, strict: [embeddings: :string])
    @embedding_implementations[impl]
  end

  defp write(party, paragraphs, embeddings) do
    data =
      paragraphs
      |> Enum.zip(embeddings)
      |> Enum.map(fn {text, embedding} ->
        %{"text" => text, "embedding" => Jason.encode!(embedding)}
      end)

    filename = "priv/embeddings/#{party}.csv"
    IO.puts("\n-> Writing embeddings to #{filename}")
    file = File.open!(filename, [:write, :utf8])
    data |> CSV.encode(headers: ["text", "embedding"]) |> Enum.each(&IO.write(file, &1))
  end
end
