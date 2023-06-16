defmodule QDSP.Bot do
  @moduledoc """
  Bot is a module that will help you with your questions about sketchq
  """

  alias QDSP.Bot.{Embeddings, Parser}
  alias QDSP.OpenAi

  @parties [:sumar, :vox, :pp, :bildu]
  @embeddings %{
    sumar: "priv/embeddings/sumar.csv" |> File.read!() |> Parser.parse(),
    # psoe: "priv/embeddings/psoe.csv" |> File.read!() |> Parser.parse(),
    vox: "priv/embeddings/vox.csv" |> File.read!() |> Parser.parse(),
    pp: "priv/embeddings/pp.csv" |> File.read!() |> Parser.parse(),
    bildu: "priv/embeddings/bildu.csv" |> File.read!() |> Parser.parse()
    # erc: "priv/embeddings/erc.csv" |> File.read!() |> Parser.parse(),
    # junts: "priv/embeddings/junts.csv" |> File.read!() |> Parser.parse()
  }

  @spec assist(String.t(), map(), keyword()) :: {:ok, String.t()} | {:error, any()}
  def assist(question, embeddings \\ @embeddings, opts \\ []) do
    sample_size = Keyword.get(opts, :sample_size, 2)

    with {:ok, question_embedding} <- Embeddings.embed(question) do
      context =
        @parties
        |> Enum.map(fn party ->
          {party, context_for_party(party, embeddings, sample_size, question_embedding)}
        end)
        |> Enum.into(%{})

      open_ai().chat_completion(
        """
        Esto es lo que dice cada partido en su programa electoral para las elecciones
        generales del estado español sobre este tema:

        #{@parties |> Enum.map(fn party -> "#{party}: #{context[party]}" end) |> Enum.join("\n")}

        Pregunta:
        Qué propone cada partido sobre #{question}?

        Responde brevemente, 350 characteres aprox,
        por separado para cada partido de esta lista, usando estrictamente este formato:

        #{Enum.map(@parties, fn party -> "#{party}: ${#{party}}" end) |> Enum.join("\n")}
        """,
        instructions: """
        Eres un analista político totalmente imparcial, especializado en
        comparar programas electorales. La información de los programas
        electorales tiene prioridad. No respondes preguntas sobre temas
        no relacionados con los programas electorales. Si alguien pregunta
        algo no relacionado, simplemente respondes "No lo sé, pero soy un 🤖,
        prueba a formular la pregunta de otra manera.".
        """
      )
      |> parse_response()
    end
  end

  defp context_for_party(party, embeddings, sample_size, question_embedding) do
    embeddings[party]
    |> strings_ranked_by_relatedness(sample_size, question_embedding)
    |> Enum.join(". ")
  end

  defp strings_ranked_by_relatedness(embeddings, top_n, question_embedding) do
    embeddings
    |> Enum.map(fn {text, embedding} ->
      {text, Embeddings.relatedness(question_embedding, embedding)}
    end)
    |> Enum.sort(fn {_, a}, {_, b} -> a > b end)
    |> Enum.take(top_n)
    |> Enum.map(fn {text, _} -> text end)
  end

  defp parse_response({:ok, response}) do
    response
    |> String.split("\n")
    |> Enum.map(fn line ->
      case String.split(line, ": ") do
        [party | text] -> {String.to_atom(party), Enum.join(text, ": ")}
        _ -> nil
      end
    end)
    |> Enum.reject(fn
      {:"", _} -> true
      {_, ""} -> true
      _ -> false
    end)
    |> Enum.into(%{}, fn {party, text} -> {party, %{result: text}} end)
    |> then(&{:ok, &1})
  end

  defp open_ai() do
    Application.get_env(:qdsp, :open_ai)[:client] || OpenAi.Client
  end
end
