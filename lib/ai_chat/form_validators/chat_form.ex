defmodule AiChat.FormValidators.ChatForm do
  @moduledoc """
   Will validate chat form
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :message, :string
  end

  @required_attributes ~w(message)a
  @optional_attributes ~w()a

  def changeset(chat_form, attrs) do
    chat_form
    |> cast(attrs, @required_attributes ++ @optional_attributes)
    |> validate_required(@required_attributes)
  end
end
