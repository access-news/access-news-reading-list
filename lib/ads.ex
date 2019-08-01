defmodule Anrl.Ads do

  @ads_in_dir          "_ads/input"
  @img_src_attr_prefix "/images/ads/"
  @ads_out_dir         Path.join("priv/static", @img_src_attr_prefix)
  @ads_json_location   Path.join(@ads_out_dir, "ads.json")

  # Choosing map  as output to be  able to use it  for a
  # JSON API later

  # submitted = %{ store_id => %{ paths => [], ... }}
  # see `list/0`'s output at the bottom
  def submit_ads(submitted) do

    { ads, update } =
      @ads_json_location
      |> read_json()    #=> ads
      |> winnow(submitted)

    ads
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
    |> (&File.write(@ads_json_location, &1)).()

    update
  end

  def winnow(ads, submitted) do

    Enum.reduce(
      submitted,
      { ads, %{} },
      fn(
        { store_id, _meta } = ads_entry_tuple,
        { ads, update }
      ) ->

        status =
          case Map.has_key?(ads, store_id) do
            false ->
              "new"
            true  ->
              delete_previous_images(ads[store_id])
              "update"
          end

        new_ads_entry = process_submitted(ads_entry_tuple)

        {
          # update ads
          Map.merge(ads, new_ads_entry),

          # update update
          new_ads_entry
          |> Map.update!(store_id, &Map.put(&1, "status", status))
          |> (&Map.merge(update, &1)).()
        }

      end
    )
  end

  # Only  deleting images  that  will be  updated.
  # `ads.json` will be updated by `process_submitted/2`
  defp delete_previous_images(
    %{ "paths" => paths_with_page_numbers }
  ) do
    Enum.each(
      paths_with_page_numbers,
      fn { page_number, src_path } = x ->

        IO.inspect(x)

        base = Path.basename(src_path) #=> UUID.<img_format>
        root = Path.rootname(base)     #=> UUID

        # delete full res image
        @ads_out_dir
        |> Path.join(base)
        |> File.rm!()

        # delete small version
        @ads_out_dir
        |> Path.join(root)
        |> (&<>/2).("-small.jpg")
        |> File.rm!()
      end
    )
  end

  def process_submitted({ store_id, %{ "paths" => paths } = meta }) do

    new_meta =
      paths  #=> [path_1, ..., path-n]
      |> copy_images_and_add_page_numbers() #=> ["1" => src_path, ... ]
      |> (&Map.put(meta, "paths", &1)).()

    %{ store_id => new_meta }
  end

  defp copy_images_and_add_page_numbers(paths) do

    Enum.reduce(
      paths,
      %{},
      # {%{}, %{}},
      fn image_path, acc ->
      # fn image_path, { small, full_res} ->

        new_base_filename = Ecto.UUID.generate()
        orig_extname      = Path.extname(image_path)

        new_filename       = new_base_filename <> orig_extname
        new_filename_small = new_base_filename <> "-small.jpg"

        File.cp!(
          image_path,
          Path.join(@ads_out_dir, new_filename)
        )

        # https://stackoverflow.com/questions/2257322
        System.cmd(
          "magick",
          [ "convert",
            image_path,
            "-quality",
            "16",
            Path.join(@ads_out_dir, new_filename_small)
          ]
        )

        # {
          # Map.put(
          #   small,
          #   page_number,
          #   Path.join(@img_src_attr_prefix, new_filename_small)
          # ),
        Map.put(
          # full_res,
          acc,
          get_page_number(image_path),
          Path.join(@img_src_attr_prefix, new_filename)
        )
        # }
      end)
  end

  defp get_page_number(image_path) do
    page_number  =
      image_path
      |> Path.basename()
      |> Path.rootname()
  end

  def read_json(path) do
    path
    |> File.read!()
    |> Jason.decode!()
  end

  # --- TEMPORARY ------------------------------------------------------
  #
  # Only here to emulate a frontend form input.

  def list do

    store_path_tuples =
      @ads_in_dir
      |> File.ls!()
      |> Enum.reduce(%{}, fn dir, acc ->

           rel_dir = Path.join(@ads_in_dir, dir)
           meta = Path.join(rel_dir, "meta.json") |> read_json()

           image_paths =
             File.ls!(rel_dir)
             |> Enum.reduce([], fn file, acc ->
                  case file == "meta.json" do
                    true ->
                      acc
                    false ->
                      [ Path.join(rel_dir, file) | acc ]
                  end
                end)

           Map.put(
             acc,
             dir,
             Map.put(meta, "paths", image_paths)
           )
         end)

    # %{
    #   "food-source" => %{
    #     "paths" => ["_ads/food-source/1.png", "_ads/food-source/2.png"],
    #     "store" => "Food Source"
    #   },
    #   "foods-co" => %{
    #     "paths" => ["_ads/foods-co/1.png", "_ads/foods-co/2.png"],
    #     "store" => "Food Co"
    #   },
    # }
  end
end
