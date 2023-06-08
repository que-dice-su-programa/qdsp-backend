defmodule QDSP.Bot.EmbeddingsTest do
  use ExUnit.Case, async: true

  alias QDSP.Bot.Embeddings

  describe "embed/1" do
    test "creates embeddings for the given text" do
      assert {:ok, embeddings} = Embeddings.embed("what is the meaning of life?")

      assert Enum.all?(embeddings, fn x -> x > -1.0 && x < 1.0 end)
    end
  end
end
