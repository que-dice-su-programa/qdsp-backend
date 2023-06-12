defmodule QDSP.BotTest do
  use ExUnit.Case, async: true

  alias QDSP.Bot

  describe "assist/1" do
    @test_embeddings %{
      podemos: [
        {"Los restaurantes no podrán servir paella para cenar", [0, 0.1, -0.2]},
        {"Prohibiremos la tortilla de patata sin cebolla", [0, 0.1, 0.2]},
        {"Todos los ciudadanos tendrán derecho a un perro", [-0.8, 0.8, -0.7]}
      ]
    }

    test "uses openai to answer your questions" do
      QDSP.OpenAi.Mock
      |> Mox.expect(:chat_completion, fn prompt, [instructions: instructions] ->
        assert prompt == """
               Esto es lo que dice cada partido en su programa electoral sobre este tema:
               podemos: Prohibiremos la tortilla de patata sin cebolla

               Pregunta:
               Qué propone cada partido sobre la tortilla de patata?

               Responde brevemente, 280 characteres máximo (sin usar hashtags),
               por separado para cada partido de esta lista, usando estrictamente este formato:

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
      |> Mox.expect(:embeddings, fn ["la tortilla de patata"] ->
        {:ok, [[0, 0.2, 0.2]]}
      end)

      assert Bot.assist("la tortilla de patata", @test_embeddings, sample_size: 1) ==
               {:ok,
                %{
                  podemos: "prohibirá la tortilla de patata sin cebolla"
                }}
    end
  end
end
