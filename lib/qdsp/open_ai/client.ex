defmodule QDSP.OpenAi.Client do
  @moduledoc """
  Module for interacting with OpenAI API
  """

  @behaviour QDSP.OpenAi.Adapter

  require Logger

  @impl true
  def chat_completion(input, options \\ [], api \\ OpenAI) do
    instructions = Keyword.get(options, :instructions)

    user_message = %{role: "user", content: input}

    messages =
      if instructions,
        do: [%{role: "system", content: instructions}, user_message],
        else: [user_message]

    [
      model: "gpt-3.5-turbo",
      max_tokens: 2048,
      messages: messages,
      temperature: 0.1
    ]
    |> api.chat_completion()
    |> parse_completion()
  end

  defp parse_completion({:ok, response}) do
    choice = response.choices |> Enum.find(&(&1["finish_reason"] == "stop"))

    if choice do
      parse_choice(choice)
    else
      parse_completion({:error, response})
    end
  end

  defp parse_completion({:error, response}) do
    Logger.error("Something went wrong with OpenAI API: #{inspect(response)}",
      grouping_title: "OpenAI error",
      extra_info: %{response: response}
    )

    {:error, "Something went wrong"}
  end

  defp parse_choice(%{"message" => %{"content" => text}}) do
    {:ok, text}
  end

  defp parse_choice(%{"text" => text}) do
    {:ok, text}
  end
end
