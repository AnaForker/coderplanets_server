# ---
# Absinthe.Middleware behaviour
# see https://hexdocs.pm/absinthe/Absinthe.Middleware.html#content
# ---
defmodule MastaniServerWeb.Middleware.Statistics.MakeContribute do
  @behaviour Absinthe.Middleware
  # google: must appear in the GROUP BY clause or be used in an aggregate function
  alias MastaniServer.Accounts.User
  alias MastaniServer.CMS.Community
  alias MastaniServer.Statistics

  def call(%{errors: errors} = resolution, _) when length(errors) > 0, do: resolution

  def call(%{value: nil, errors: _} = resolution, _), do: resolution

  def call(
        %{arguments: %{community_id: community_id}, context: %{cur_user: cur_user}} = resolution,
        for: threads
      ) do

    case is_list(threads) do
      true ->
        if :user in threads, do: Statistics.make_contribute(%User{id: cur_user.id})
        if :community in threads, do: Statistics.make_contribute(%Community{id: community_id})

      false ->
        if :user == threads, do: Statistics.make_contribute(%User{id: cur_user.id})
        if :community == threads, do: Statistics.make_contribute(%Community{id: community_id})
    end

    resolution
  end

  def call(resolution, _), do: resolution
end
