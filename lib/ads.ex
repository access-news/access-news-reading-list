defmodule Anrl.Ads do

  @ads_in_dir          "_ads/input"
  @img_src_attr_prefix "/images/ads/"
  @ads_out_dir         Path.join("priv/static", @img_src_attr_prefix)
  @ads_json_location   Path.join(@ads_out_dir, "ads.json")

  # Choosing map  as output to be  able to use it  for a
  # JSON API later

  # %{"A store" => "/absolute/path"}
  def submit_ads(submitted) do

    submitted
    |> winnow()
    |> add_new()
    |> update_exisiting()
  end

  def winnow(submitted) do

    ads = read_json(@ads_json_location)

    submitted
    |> Enum.group_by(fn {key, _value} ->
         Map.has_key?(ads, key)
       end)
      # %{
      #   true: [
      #     {"safeway",
      #     %{
      #       "paths" => ["_ads/input/safeway/2.jpg"]
      #     }}
      #   ],
      #   false: [
      #     # { ... }
      #   ]
      # }

      # The merge  is needed  because if  there is  only new
      # input then there will be  no :true  keyword entry in
      # the output  (and vice  versa, if  there is  only new
      # content, there will be no :false). `apply_changes/2`
      # will just return with an empty list.
      #
      # This  way `add_new/1`  and `update_exisiting/1`  can
      # just match on the success paths.
    |> (&Map.merge(%{ true: [], false: []}, &1)).()
    |> Map.merge(:ads_json, ads)
  end

  # kw = keyword list (see `winnow/1`)
  defp add_new(%{ false: ad_kw, ads_json: ads } = winnowed) do

    new_ads =
      ads
      |> Map.put("status", "new")
      # + 2. copy new ones
      # + 3. create resized version
      |> Map.merge( apply_changes(ad_kw) )
      |> (&Map.put(winnowed, :ads_json, &1)).()
    # 4. push update to create the section on the frontend
  end

  defp update_exisiting(%{ true: ad_kw, ads_json: ads}) do
    # 1. delete old files
    delete_old_images(ads)
    # + 2. copy new ones
    # + 3. create resized version
    apply_changes(ad_kw, :update)
    ad_kw
    # 4. push update to the given section on the frontend
  end

  # !!!!!!!!!!!!! ezt atgondolni, hogy hgoygan torolni a regieket
  defp delete_old_images(ads_json) do
    @ads_json_location
    |> read_json()
    |> Enum.each(
         fn { _store_id, %{ "paths" => paths_with_page_numbers }} ->
           delete_path(paths_with_page_numbers)
         end
       )
  end

  defp delete_path(paths_with_page_numbers) do
    Enum.each(
      paths_with_page_numbers,
      fn { _page_number, path } ->
        # delete given path
        File.rm!(path)

        # delete small version
        path_root = Path.rootname(path)
        path_ext  = Path.extname(path)
        File.rm!(path_root <> "-small" <> path_ext)
      end
    )
  end

  def apply_changes(ad_kw, msg) do

    Enum.reduce(
      ad_kw,
      %{},
      fn { store_id, %{ "paths" => paths} = meta }, acc_map ->

        # { small_path_maps, full_res_path_maps } =
        new_paths_with_page_numbers =
          Enum.reduce(
            paths,
            %{},
            # {%{}, %{}},
            fn image_path, acc_map ->
            # fn image_path, { small, full_res} ->

              page_number  =
                image_path
                |> Path.basename()
                |> Path.rootname()

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
                acc_map,
                page_number,
                Path.join(@img_src_attr_prefix, new_filename)
              )
              # }
            end)

        new_meta =
          meta
          |> Map.put("paths", new_paths_with_page_numbers)
          # |> Map.put("small_paths",    small_path_maps)
          # |> Map.put("full_res_paths", full_res_path_maps)
          # |> Map.drop("paths")

        Map.put(
          acc_map,
          store_id,
          new_meta
        )
      end)
    # |> Jason.encode!()
    # |> Jason.Formatter.pretty_print()
    # |> (&File.write(@ads_json_location, &1)).()
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
