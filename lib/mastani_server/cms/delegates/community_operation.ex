defmodule MastaniServer.CMS.Delegate.CommunityOperation do
  @moduledoc """
  community operations, like: set/unset category/thread/editor...
  """
  import ShortMaps

  alias Ecto.Multi
  alias Helper.{Certification, RadarSearch, ORM}
  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS.Delegate.PassportCURD
  alias MastaniServer.Repo

  alias MastaniServer.CMS.{
    Category,
    Community,
    CommunityCategory,
    CommunityEditor,
    CommunitySubscriber,
    CommunityThread,
    Thread
  }

  @doc """
  set a category to community
  """
  def set_category(%Community{id: community_id}, %Category{id: category_id}) do
    with {:ok, community_category} <-
           CommunityCategory |> ORM.create(~m(community_id category_id)a) do
      Community |> ORM.find(community_category.community_id)
    end
  end

  @doc """
  unset a category to community
  """
  def unset_category(%Community{id: community_id}, %Category{id: category_id}) do
    with {:ok, community_category} <-
           CommunityCategory |> ORM.findby_delete(~m(community_id category_id)a) do
      Community |> ORM.find(community_category.community_id)
    end
  end

  @doc """
  set to thread to a community
  """
  def set_thread(%Community{id: community_id}, %Thread{id: thread_id}) do
    with {:ok, community_thread} <- CommunityThread |> ORM.create(~m(community_id thread_id)a) do
      Community |> ORM.find(community_thread.community_id)
    end
  end

  @doc """
  unset to thread to a community
  """
  def unset_thread(%Community{id: community_id}, %Thread{id: thread_id}) do
    with {:ok, community_thread} <-
           CommunityThread |> ORM.findby_delete(~m(community_id thread_id)a) do
      Community |> ORM.find(community_thread.community_id)
    end
  end

  @doc """
  set a community editor
  """
  def set_editor(%Community{id: community_id}, title, %User{id: user_id}) do
    Multi.new()
    |> Multi.insert(
      :insert_editor,
      CommunityEditor.changeset(%CommunityEditor{}, ~m(user_id community_id title)a)
    )
    |> Multi.run(:stamp_passport, fn _, _ ->
      rules = Certification.passport_rules(cms: title)
      PassportCURD.stamp_passport(rules, %User{id: user_id})
    end)
    |> Repo.transaction()
    |> set_editor_result()
  end

  @doc """
  unset a community editor
  """
  def unset_editor(%Community{id: community_id}, %User{id: user_id}) do
    with {:ok, _} <- ORM.findby_delete(CommunityEditor, ~m(user_id community_id)a),
         {:ok, _} <- PassportCURD.delete_passport(%User{id: user_id}) do
      User |> ORM.find(user_id)
    end
  end

  defp set_editor_result({:ok, %{insert_editor: editor}}) do
    User |> ORM.find(editor.user_id)
  end

  defp set_editor_result({:error, :stamp_passport, %Ecto.Changeset{} = result, _steps}),
    do: {:error, result}

  defp set_editor_result({:error, :stamp_passport, _result, _steps}),
    do: {:error, "stamp passport error"}

  defp set_editor_result({:error, :insert_editor, _result, _steps}),
    do: {:error, "insert editor error"}

  @doc """
  subscribe a community. (ONLY community, post etc use watch )
  """
  def subscribe_community(
        %Community{id: community_id},
        %User{id: user_id}
      ) do
    with {:ok, record} <- CommunitySubscriber |> ORM.create(~m(user_id community_id)a) do
      Community |> ORM.find(record.community_id)
    end
  end

  def subscribe_community(
        %Community{id: community_id},
        %User{id: user_id},
        remote_ip
      ) do
    with {:ok, record} <- CommunitySubscriber |> ORM.create(~m(user_id community_id)a) do
      update_community_geo(community_id, user_id, remote_ip, :inc)
      Community |> ORM.find(record.community_id)
    end
  end

  @doc """
  unsubscribe a community
  """
  def unsubscribe_community(
        %Community{id: community_id},
        %User{id: user_id}
      ) do
    with {:ok, community} <- ORM.find(Community, community_id),
         true <- community.raw !== "home",
         {:ok, record} <-
           ORM.findby_delete(CommunitySubscriber, community_id: community.id, user_id: user_id) do
      Community |> ORM.find(record.community_id)
    else
      false ->
        {:error, "can not unsubscribe home community"}

      error ->
        error
    end
  end

  def unsubscribe_community(
        %Community{id: community_id},
        %User{id: user_id, geo_city: nil},
        remote_ip
      ) do
    with {:ok, community} <- ORM.find(Community, community_id),
         true <- community.raw !== "home",
         {:ok, record} <-
           CommunitySubscriber |> ORM.findby_delete(community_id: community.id, user_id: user_id) do
      update_community_geo(community_id, user_id, remote_ip, :dec)
      Community |> ORM.find(record.community_id)
    else
      false ->
        {:error, "can't delete home community"}

      error ->
        error
    end
  end

  def unsubscribe_community(
        %Community{id: community_id},
        %User{id: user_id, geo_city: city},
        remote_ip
      ) do
    with {:ok, community} <- ORM.find(Community, community_id),
         true <- community.raw !== "home",
         {:ok, record} <-
           CommunitySubscriber |> ORM.findby_delete(community_id: community.id, user_id: user_id) do
      update_community_geo_map(community.id, city, :dec)
      Community |> ORM.find(record.community_id)
    else
      false ->
        {:error, "can't delete home community"}

      error ->
        error
    end
  end

  @doc """
  if user is new subscribe home community by default
  """
  # 这里只有一种情况，就是第一次没有解析到 remote_ip, 那么就直接订阅社区, 但不更新自己以及社区的地理信息
  def subscribe_default_community_ifnot(%User{} = user) do
    with {:ok, community} <- ORM.find_by(Community, raw: "home"),
         {:error, _} <-
           ORM.find_by(CommunitySubscriber, %{community_id: community.id, user_id: user.id}) do
      subscribe_community(community, user)
    end
  end

  # 3种情况
  # 1. 第一次就直接解析到了 remote_ip, 正常订阅加更新地理信息
  # 2. 之前已经订阅过，但是之前的 remote_ip 为空
  # 3. 有 remote_ip 但是 geo_city 信息没有解析到
  def subscribe_default_community_ifnot(%User{geo_city: nil} = user, remote_ip) do
    with {:ok, community} <- ORM.find_by(Community, raw: "home") do
      case ORM.find_by(CommunitySubscriber, %{community_id: community.id, user_id: user.id}) do
        {:error, _} ->
          # 之前没有订阅过且第一次就解析到了 remote_ip
          subscribe_community(community, user, remote_ip)

        {:ok, _} ->
          # 之前订阅过，但是之前没有正确解析到 remote_ip 地址, 这次直接更新地理信息
          update_community_geo(community.id, user.id, remote_ip, :inc)
      end
    end
  end

  # 用户的 geo_city 和 remote_ip 都有了，如果没订阅 home 直接就更新 community geo 即可
  def subscribe_default_community_ifnot(%User{geo_city: city} = user, _remote_ip) do
    with {:ok, community} <- ORM.find_by(Community, raw: "home") do
      case ORM.find_by(CommunitySubscriber, %{community_id: community.id, user_id: user.id}) do
        {:error, _} ->
          update_community_geo_map(community.id, city, :inc)

        {:ok, _} ->
          # 手续齐全且之前也订阅了
          {:ok, :pass}
      end
    end
  end

  defp update_community_geo(community_id, user_id, remote_ip, method) do
    {:ok, user} = ORM.find(User, user_id)

    case get_user_geocity(user.geo_city, remote_ip) do
      {:ok, user_geo_city} ->
        update_community_geo_map(community_id, user_geo_city, method)

      {:error, _} ->
        {:ok, :pass}
    end
  end

  defp get_user_geocity(nil, remote_ip) do
    case RadarSearch.locate_city(remote_ip) do
      {:ok, city} -> {:ok, city}
      {:error, _} -> {:error, "update_community geo error"}
    end
  end

  defp get_user_geocity(geo_city, _remote_ip), do: {:ok, geo_city}

  defp update_community_geo_map(community_id, city, method) do
    with {:ok, community} <- Community |> ORM.find(community_id) do
      community_geo_data = community.geo_info |> Map.get("data")

      cur_city_info = community_geo_data |> Enum.find(fn g -> g["city"] == city end)
      new_city_info = update_geo_value(cur_city_info, method)

      community_geo_data =
        community_geo_data
        |> Enum.reject(fn g -> g["city"] == city end)
        |> Kernel.++([new_city_info])

      community |> ORM.update(%{geo_info: %{data: community_geo_data}})
    end
  end

  defp update_geo_value(geo_info, :inc) do
    Map.merge(geo_info, %{"value" => geo_info["value"] + 1})
  end

  defp update_geo_value(geo_info, :dec) do
    Map.merge(geo_info, %{"value" => max(geo_info["value"] - 1, 0)})
  end
end
