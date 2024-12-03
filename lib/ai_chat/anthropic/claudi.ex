defmodule AiChat.Anthropic.Claudi do
  @moduledoc """
   Will contain langchain claudi logic
  """
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatAnthropic
  alias LangChain.Message

  def create(message, chain \\ nil)

  def create(message, nil) do
    create(
      message,
      LLMChain.new!(%{llm: ChatAnthropic.new!(%{model: "claude-3-5-sonnet-20241022"})})
    )
  end

  def create(message, chain) do
    chain
    |> LLMChain.add_message(Message.new_user!(message))
    |> LLMChain.run()
  end
end
