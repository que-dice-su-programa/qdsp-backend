defmodule QDSP.BotTest do
  use ExUnit.Case, async: true

  alias QDSP.Bot
  alias QDSP.Bot.Embeddings

  describe "assist/1" do
    defp embed(chunks) do
      Enum.map(chunks, fn text ->
        {:ok, embedding} = Embeddings.embed(text)
        {text, embedding}
      end)
    end

    defp test_embeddings() do
      %{
        podemos:
          embed([
            "Los restaurantes no podrán servir paella para cenar",
            "Todos los ciudadanos tendrán derecho a un perro",
            "Prohibiremos la tortilla de patata sin cebolla",
            "Los perros tendrán derecho a un ciudadano"
          ])
      }
    end

    test "uses openai to answer your questions" do
      QDSP.OpenAi.Mock
      |> Mox.expect(:chat_completion, fn prompt, [instructions: instructions] ->
        assert prompt == """
               Esto es lo que dice cada partido en su programa electoral sobre este tema:
               podemos: Prohibiremos la tortilla de patata sin cebolla

               Pregunta:
               Qué propone cada partido sobre la tortilla de patata?

               Responde por separado para cada partido de esta lista, usando
               estrictamente este formato:

               podemos: ${podemos}
               """

        assert instructions == """
               Eres un analista político totalmente imparcial, especializado en
               comparar programas electorales. La información de los programas
               electorales tiene prioridad. No respondes preguntas sobre temas
               no relacionados con los programas electorales. Si alguien pregunta
               algo no relacionado, simplemente respondes "No lo sé, pero soy un 🤖,
               prueba a formular la pregunta de otra manera.".
               """

        {:ok,
         """
         podemos: prohibirá la tortilla de patata sin cebolla
         """}
      end)

      assert Bot.assist("la tortilla de patata", test_embeddings(), sample_size: 1) ==
               {:ok,
                %{
                  podemos: "prohibirá la tortilla de patata sin cebolla"
                }}
    end
  end
end
