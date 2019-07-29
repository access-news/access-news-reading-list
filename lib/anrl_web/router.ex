defmodule AnrlWeb.Router do
  use AnrlWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]

    # get "/", PageController, :index
  end

  scope "/", AnrlWeb do
    pipe_through :browser

    get "/", PageController, :index
    resources "/ads", AdsController, only: [:index, :new, :create, :delete]
  end

  # Other scopes may use custom stacks.
  # scope "/api", AnrlWeb do
  #   pipe_through :api
  # end
end
