defmodule QDSP.BotTest do
  use ExUnit.Case, async: true

  alias QDSP.Bot

  describe "assist/1" do
    @test_embeddings %{
      sumar: [
        {"Los restaurantes no podrán servir paella para cenar", [0, 0.1, -0.2]},
        {"Prohibiremos la tortilla de patata sin cebolla", [0, 0.1, 0.2]},
        {"Todos los ciudadanos tendrán derecho a un perro", [-0.8, 0.8, -0.7]}
      ],
      vox: [
        {"La tortilla de patata se llamará tortilla española", [0, 0.1, -0.2]}
      ],
      pp: [
        {"Las bicicletas son el demonio", [0, 0.1, -0.2]}
      ],
      psoe: [
        {"La tortilla de patata es vasca", [0, 0.1, -0.2]}
      ]
    }

    test "uses openai to answer your questions" do
      QDSP.OpenAi.Mock
      |> Mox.expect(:chat_completion, fn prompt, [instructions: instructions] ->
        assert prompt == """
               Esto es lo que dice cada partido en su programa electoral para las elecciones
               generales del estado español sobre este tema:

               sumar: Prohibiremos la tortilla de patata sin cebolla
               psoe: La tortilla de patata es vasca
               vox: La tortilla de patata se llamará tortilla española
               pp: Las bicicletas son el demonio

               Pregunta:
               Qué propone cada partido sobre la tortilla de patata?

               Responde brevemente, 450 characteres aprox,
               por separado para cada partido de esta lista, usando estrictamente este formato:

               sumar: ${sumar}
               psoe: ${psoe}
               vox: ${vox}
               pp: ${pp}

               Recuerda: Si no se menciona el tema en su programa, no digas que no se menciona. En su lugar,
               es estríctamente necesario que devuelvas única y exclusivamente la palabra "false"
               como resultado de ese partido.
               """

        assert instructions == """
               Eres un analista político totalmente imparcial, especializado en
               comparar programas electorales. La información de los programas
               electorales tiene prioridad. Utilizas un vocabulario sencillo para que
               sea fácild e entender. Priorizas mencionar medidas específicas.
               No respondes preguntas sobre temas no relacionados con los programas
               electorales. Si alguien pregunta algo no relacionado, simplemente
               respondes "No lo sé, pero soy un 🤖, prueba a formular la pregunta de otra manera.".
               Si no se menciona el tema en su programa, no digas que no se menciona. En su lugar,
               es estríctamente necesario que devuelvas única y exclusivamente la palabra "false"
               como resultado de ese partido.
               """

        {:ok,
         """
         sumar: prohibirá la tortilla de patata sin cebolla
         psoe: oficializará la tortilla de patata como vasca
         vox: renombrará la tortilla de patata como tortilla española
         pp: false
         """}
      end)
      |> Mox.expect(:embeddings, fn ["medidas y propuestas sobre la tortilla de patata"] ->
        {:ok, [[0, 0.2, 0.2]]}
      end)

      assert Bot.assist("la tortilla de patata", embeddings: @test_embeddings, sample_size: 1) ==
               {:ok,
                %{
                  sumar: %{
                    result: "prohibirá la tortilla de patata sin cebolla",
                    context: [
                      "Prohibiremos la tortilla de patata sin cebolla"
                    ]
                  },
                  psoe: %{
                    result: "oficializará la tortilla de patata como vasca",
                    context: [
                      "La tortilla de patata es vasca"
                    ]
                  },
                  vox: %{
                    result: "renombrará la tortilla de patata como tortilla española",
                    context: [
                      "La tortilla de patata se llamará tortilla española"
                    ]
                  },
                  pp: %{
                    result: nil,
                    context: []
                  }
                }}
    end
  end
end
