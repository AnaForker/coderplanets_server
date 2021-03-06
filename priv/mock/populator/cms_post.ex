# for mock CMS posts

defmodule MastaniServer.Mock.CMS.Post do
  alias MastaniServer.Repo
  alias MastaniServer.CMS.Post

  def random_attrs do
    %{
      title: Faker.Name.first_name() <> " " <> Faker.Name.last_name(),
      body: Faker.Lorem.paragraph(%Range{first: 1, last: 2})
    }
  end

  def random(count \\ 1) do
    for _u <- 1..count do
      insert_multi()
    end
  end

  # def insert(user) do
  # User.changeset(%User{}, user)
  # |> Repo.insert!
  # end

  defp insert_multi do
    Post.changeset(%Post{}, random_attrs())
    |> Repo.insert!()
  end
end
