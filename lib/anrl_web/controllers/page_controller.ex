defmodule AnrlWeb.PageController do
  use AnrlWeb, :controller

  def index(conn, _params) do
    ads = Anrl.Ads.list()
    render(conn, "index.html", ads: ads)
  end
end
