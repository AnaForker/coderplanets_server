defmodule MastaniServer.Repo.Migrations.RecreatePostsCommentsReplies do
  use Ecto.Migration

  def change do
    create table(:posts_comments_replies) do
      add(:post_comment_id, references(:posts_comments, on_delete: :delete_all), null: false)
      add(:reply_id, references(:posts_comments, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:posts_comments_replies, [:post_comment_id]))
    create(index(:posts_comments_replies, [:reply_id]))
    # create(unique_index(:posts_comments_replies, [:comment_id, :reply_id]))
  end
end
