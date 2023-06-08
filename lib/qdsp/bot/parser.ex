defmodule QDSP.Bot.Parser do
  @moduledoc """
  Parse OpenAI embeddings
  """
  alias QDSP.Bot.CsvParser

  @spec parse(String.t()) :: list()
  def parse(content) do
    content
    |> CsvParser.parse_string()
    |> Enum.map(fn [text, embedding] -> {text, Jason.decode!(embedding)} end)
  end
end
