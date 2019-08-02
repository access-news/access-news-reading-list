defmodule Anrl.Ads.Reserve do
  use Agent

  def start_link(_arg) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def reserve(id) do
    Agent.get_and_update(
      __MODULE__,
      fn state ->
        case id in state do
          true  -> { {:error, :already_reserved}, state }
          false -> { :ok, [ id | state ] }
        end
      end
    )
  end
end
