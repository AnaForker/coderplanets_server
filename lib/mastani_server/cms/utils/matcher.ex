defmodule MastaniServer.CMS.Utils.Matcher do
  @moduledoc """
  this module defined the matches and handy guard ...
  """
  import Ecto.Query, warn: false

  alias MastaniServer.CMS.{
    Community,
    # threads
    Post,
    Video,
    Repo,
    Job,
    # viewer
    PostViewer,
    JobViewer,
    VideoViewer,
    RepoViewer,
    # reactions
    PostFavorite,
    JobFavorite,
    VideoFavorite,
    RepoFavorite,
    PostStar,
    JobStar,
    VideoStar,
    # comments
    PostComment,
    JobComment,
    VideoComment,
    RepoComment,
    # commtnes reaction
    PostCommentLike,
    PostCommentDislike,
    JobCommentLike,
    JobCommentDislike,
    VideoCommentLike,
    VideoCommentDislike,
    RepoCommentLike,
    RepoCommentDislike,
    #
    Tag,
    Community,
    # flags
    PostCommunityFlag,
    JobCommunityFlag,
    RepoCommunityFlag,
    VideoCommunityFlag
  }

  #########################################
  ##  posts ...
  #########################################
  def match_action(:post, :self),
    do: {:ok, %{target: Post, reactor: Post, preload: :author, viewer: PostViewer}}

  def match_action(:post, :favorite),
    do: {:ok, %{target: Post, reactor: PostFavorite, preload: :user, preload_right: :post}}

  def match_action(:post, :star), do: {:ok, %{target: Post, reactor: PostStar, preload: :user}}
  def match_action(:post, :tag), do: {:ok, %{target: Post, reactor: Tag}}
  # NOTE: the tech, radar, share, city thread also use common tag
  def match_action(:radar, :tag), do: {:ok, %{target: Post, reactor: Tag}}
  def match_action(:share, :tag), do: {:ok, %{target: Post, reactor: Tag}}
  def match_action(:city, :tag), do: {:ok, %{target: Post, reactor: Tag}}
  def match_action(:tech, :tag), do: {:ok, %{target: Post, reactor: Tag}}

  def match_action(:post, :community),
    do: {:ok, %{target: Post, reactor: Community, flag: PostCommunityFlag}}

  def match_action(:post, :comment),
    do: {:ok, %{target: Post, reactor: PostComment, preload: :author}}

  def match_action(:post_comment, :like),
    do: {:ok, %{target: PostComment, reactor: PostCommentLike}}

  def match_action(:post_comment, :dislike),
    do: {:ok, %{target: PostComment, reactor: PostCommentDislike}}

  #########################################
  ## jobs ...
  #########################################
  def match_action(:job, :self),
    do: {:ok, %{target: Job, reactor: Job, preload: :author, viewer: JobViewer}}

  def match_action(:job, :community),
    do: {:ok, %{target: Job, reactor: Community, flag: JobCommunityFlag}}

  def match_action(:job, :favorite),
    do: {:ok, %{target: Job, reactor: JobFavorite, preload: :user}}

  def match_action(:job, :star), do: {:ok, %{target: Job, reactor: JobStar, preload: :user}}
  def match_action(:job, :tag), do: {:ok, %{target: Job, reactor: Tag}}

  def match_action(:job, :comment),
    do: {:ok, %{target: Job, reactor: JobComment, preload: :author}}

  def match_action(:job_comment, :like),
    do: {:ok, %{target: JobComment, reactor: JobCommentLike}}

  def match_action(:job_comment, :dislike),
    do: {:ok, %{target: JobComment, reactor: JobCommentDislike}}

  #########################################
  ## videos ...
  #########################################
  def match_action(:video, :self),
    do: {:ok, %{target: Video, reactor: Video, preload: :author, viewer: VideoViewer}}

  def match_action(:video, :community),
    do: {:ok, %{target: Video, reactor: Community, flag: VideoCommunityFlag}}

  def match_action(:video, :favorite),
    do: {:ok, %{target: Video, reactor: VideoFavorite, preload: :user}}

  def match_action(:video, :star),
    do: {:ok, %{target: Video, reactor: VideoStar, preload: :user}}

  def match_action(:video, :tag), do: {:ok, %{target: Video, reactor: Tag}}

  def match_action(:video, :comment),
    do: {:ok, %{target: Video, reactor: VideoComment, preload: :author}}

  def match_action(:video_comment, :like),
    do: {:ok, %{target: VideoComment, reactor: VideoCommentLike}}

  def match_action(:video_comment, :dislike),
    do: {:ok, %{target: VideoComment, reactor: VideoCommentDislike}}

  #########################################
  ## repos ...
  #########################################
  def match_action(:repo, :self),
    do: {:ok, %{target: Repo, reactor: Repo, preload: :author, viewer: RepoViewer}}

  def match_action(:repo, :community),
    do: {:ok, %{target: Repo, reactor: Community, flag: RepoCommunityFlag}}

  def match_action(:repo, :tag), do: {:ok, %{target: Repo, reactor: Tag}}

  def match_action(:repo, :favorite),
    do: {:ok, %{target: Repo, reactor: RepoFavorite, preload: :user}}

  def match_action(:repo, :comment),
    do: {:ok, %{target: Repo, reactor: RepoComment, preload: :author}}

  def match_action(:repo_comment, :like),
    do: {:ok, %{target: RepoComment, reactor: RepoCommentLike}}

  def match_action(:repo_comment, :dislike),
    do: {:ok, %{target: RepoComment, reactor: RepoCommentDislike}}

  # dynamic where query match
  def dynamic_where(thread, id) do
    case thread do
      :post ->
        {:ok, dynamic([p], p.post_id == ^id)}

      :post_comment ->
        {:ok, dynamic([p], p.post_comment_id == ^id)}

      :job ->
        {:ok, dynamic([p], p.job_id == ^id)}

      :job_comment ->
        {:ok, dynamic([p], p.job_comment_id == ^id)}

      :video ->
        {:ok, dynamic([p], p.video_id == ^id)}

      :video_comment ->
        {:ok, dynamic([p], p.video_comment_id == ^id)}

      :repo ->
        {:ok, dynamic([p], p.repo_id == ^id)}

      :repo_comment ->
        {:ok, dynamic([p], p.repo_comment_id == ^id)}

      _ ->
        {:error, 'where is not match'}
    end
  end
end
