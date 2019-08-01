defmodule AnrlWeb.PageView do
  use AnrlWeb, :view

  def src_small(src_path) do
    src_path
    |> Path.rootname()
    |> (&<>/2).("-small.jpg")
  end
end
