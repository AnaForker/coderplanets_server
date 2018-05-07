defmodule MastaniServer.CMS.Delegate.CommentReaction do
  import MastaniServer.CMS.Utils.Matcher

  alias MastaniServer.Accounts
  alias Helper.ORM

  def like_comment(part, comment_id, %Accounts.User{id: user_id}) do
    feel_comment(part, comment_id, user_id, :like)
  end

  def undo_like_comment(part, comment_id, %Accounts.User{id: user_id}) do
    undo_feel_comment(part, comment_id, user_id, :like)
  end

  def dislike_comment(part, comment_id, %Accounts.User{id: user_id}) do
    feel_comment(part, comment_id, user_id, :dislike)
  end

  def undo_dislike_comment(part, comment_id, %Accounts.User{id: user_id}) do
    undo_feel_comment(part, comment_id, user_id, :dislike)
  end

  defp feel_comment(part, comment_id, user_id, feeling)
       when valid_feeling(feeling) do
    with {:ok, action} <- match_action(part, feeling) do
      clause = %{post_comment_id: comment_id, user_id: user_id}

      case ORM.find_by(action.target, clause) do
        {:ok, _} ->
          {:error, "user has #{to_string(feeling)}d this comment"}

        {:error, _} ->
          action.target |> ORM.create(clause)
      end
    end
  end

  defp undo_feel_comment(part, comment_id, user_id, feeling) do
    with {:ok, action} <- match_action(part, feeling) do
      clause = %{post_comment_id: comment_id, user_id: user_id}
      ORM.findby_delete(action.target, clause)
    end
  end
end