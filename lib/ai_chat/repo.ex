defmodule AiChat.Repo do
  use Ecto.Repo,
    otp_app: :ai_chat,
    adapter: Ecto.Adapters.Postgres
end
