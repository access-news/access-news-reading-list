defmodule Anrl.Repo do
  use Ecto.Repo,
    otp_app: :anrl,
    adapter: Ecto.Adapters.Postgres
end
