defmodule Mix.Tasks.CreateEmbeddings do
  @moduledoc "The mix task to create embeddings: `mix help create_embeddings`"
  use Mix.Task

  alias QDSP.Bot.Embeddings

  def run(_) do
    Mix.Task.run("app.start")

    IO.puts("Creating embeddings for Podemos")
    # read priv/programas/programas.txt
    paragraphs =
      "priv/programas/podemos.txt"
      |> File.read!()
      |> String.replace(" -\n", "")
      |> String.replace("  ", " ")
      |> String.replace("- ", "")
      |> String.replace(" \n", " ")
      |> String.split("\n", trim: true)

    IO.puts("-> Processing #{length(paragraphs)} paragraphs")

    {:ok, progress} = Agent.start_link(fn -> 0 end)

    embeddings =
      paragraphs
      |> Enum.chunk_every(8)
      |> Enum.map(
        &Task.async(fn ->
          {:ok, embeddings} = Embeddings.embed(&1)
          Agent.update(progress, fn count -> count + length(&1) end)
          ProgressBar.render(Agent.get(progress, fn count -> count end), length(paragraphs))
          embeddings
        end)
      )
      |> Task.await_many(:infinity)

    data =
      paragraphs
      |> Enum.zip(embeddings)
      |> Enum.map(fn {text, embedding} ->
        %{"text" => text, "embedding" => Jason.encode!(embedding)}
      end)

    filename = "priv/embeddings/podemos.csv"
    IO.write("-> Writing embeddings to #{filename}")
    file = File.open!(filename, [:write, :utf8])
    data |> CSV.encode(headers: ["text", "embedding"]) |> Enum.each(&IO.write(file, &1))
  end
end
