defmodule AnrlWeb.PageView do
  use AnrlWeb, :view

  def src_small(src_path) do
    src_path
    |> Path.rootname()
    |> (&<>/2).("-small.jpg")
  end

  def add_if_reserved(meta, page_number) do
    case page_number in meta["reserved_pages"] do
      true  -> "reserved-page"
      false -> ""
    end
  end
end
