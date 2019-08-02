defmodule AnrlWeb.PageController do
  use AnrlWeb, :controller

  def index(conn, _params) do
    ads = Anrl.Ads.load_ads()
    render(conn, "index.html", ads: ads)
  end

  def reserve(conn, params) do
    require IEx; IEx.pry
  end
end
