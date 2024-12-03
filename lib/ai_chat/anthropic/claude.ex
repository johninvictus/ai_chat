defmodule AiChat.Anthropic.Claude do
  @moduledoc """
   Will contain langchain claudi logic
  """
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatAnthropic
  alias LangChain.Message

  def create(message, callback, chain \\ nil)

  def create(message, callback, nil) do
    create(
      message,
      callback,
      LLMChain.new!(%{
        llm:
          ChatAnthropic.new!(%{
            model: "claude-3-5-sonnet-20241022",
            stream: true,
            callbacks: [callback]
          }),
        callbacks: [callback]
      })
    )
  end

  def create(message, _callback, chain) do
    chain
    |> LLMChain.add_message(Message.new_user!(message))
    |> LLMChain.run()
  end
end
