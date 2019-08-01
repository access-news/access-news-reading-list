defmodule AnrlWeb.AdsChannel do
  use Phoenix.Channel

  def join("ads:changed", payload, socket) do
    # require IEx; IEx.pry
    {:ok, %{body: "balabab"}, socket}
  end

  def handle_in("reserve_clicked", %{ "id" => _id } = id, socket) do
    broadcast(socket, "reserve_page", id)
    {:noreply, socket}
  end
end
