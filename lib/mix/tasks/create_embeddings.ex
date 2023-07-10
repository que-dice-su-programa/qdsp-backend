defmodule Mix.Tasks.CreateEmbeddings do
  @moduledoc "The mix task to create embeddings: `mix help create_embeddings`"
  use Mix.Task

  alias QDSP.Bot.Embeddings

  def run(args) do
    Mix.Task.run("app.start")

    [:sumar, :psoe, :vox, :pp]
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
    |> remove_line_breaks_except_periods()
    |> String.replace(" -\n", "")
    |> String.replace("-\n", "")
    |> String.replace("  ", " ")
    |> String.replace("- ", "")
    |> String.replace(" \n", " ")
    |> String.split("\n", trim: true)
    |> Enum.flat_map(fn p ->
      ensure_manageable_size(p)
    end)
  end

  defp remove_line_breaks_except_periods(text) do
    pattern = ~r/(?<!\.)\n/
    cleaned_text = Regex.replace(pattern, text, " ")
    cleaned_text
  end

  defp ensure_manageable_size(paragraph) do
    paragraph |> String.length()

    if String.length(paragraph) > 1000 do
      paragraph
      |> split_in_half()
      |> Enum.flat_map(fn chunk -> ensure_manageable_size(chunk) end)
    else
      [paragraph]
    end
  end

  def split_in_half(string) do
    length = String.length(string)
    midpoint = div(length, 2)
    [String.slice(string, 0, midpoint), String.slice(string, midpoint, length)]
  end

  @batch_size %{
    Embeddings.OpenAi => 100
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
    "openai" => Embeddings.OpenAi
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
