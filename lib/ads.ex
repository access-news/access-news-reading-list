defmodule Anrl.Ads do

  # Choosing map  as output to be  able to use it  for a
  # JSON API later

  def list() do
    # hard_config = %{
    # }
    images_dir = "priv/static/images"
    image_paths_map = %{}

    Enum.reduce(
      File.ls!(images_dir),
      %{},
      fn(store, acc) ->
        images_dir
        |> Path.join(store)
        |> File.ls!()
        |> Enum.map(&Path.join(["/images", store, &1]))
        |> (&Map.put(acc, store, &1)).()
      end
    )
  end
end
