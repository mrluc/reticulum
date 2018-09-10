defmodule Ret.Scene.SceneSlug do
  use EctoAutoslugField.Slug, from: :name, to: :slug

  def get_sources(_changeset, _opts) do
    [:scene_sid, :name]
  end
end

defmodule Ret.Scene do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ret.{Scene}
  alias Ret.Scene.{SceneSlug}

  @schema_prefix "ret0"
  @primary_key {:scene_id, :id, autogenerate: true}

  schema "scenes" do
    field(:scene_sid, :string)
    field(:slug, SceneSlug.Type)
    field(:name, :string)
    field(:description, :string)
    belongs_to(:account, Ret.Account, references: :account_id)
    belongs_to(:model_owned_file, Ret.OwnedFile, references: :owned_file_id)
    belongs_to(:screenshot_owned_file, Ret.OwnedFile, references: :owned_file_id)
    field(:state, Scene.State)

    timestamps()
  end

  def changeset(
        %Scene{} = scene,
        account,
        model_owned_file,
        screenshot_owned_file,
        params \\ %{}
      ) do
    scene
    |> cast(params, [
      :name,
      :description,
      :state
    ])
    |> validate_required([
      :name
    ])
    |> validate_length(:name, min: 4, max: 64)
    # TODO BP: this is repeated from hub.ex. Maybe refactor the regex out.
    |> validate_format(:name, ~r/^[A-Za-z0-9-':"!@#$%^&*(),.?~ ]+$/)
    |> maybe_add_scene_sid_to_changeset
    |> unique_constraint(:scene_sid)
    |> put_assoc(:account, account)
    |> put_assoc(:model_owned_file, model_owned_file)
    |> put_assoc(:screenshot_owned_file, screenshot_owned_file)
    |> SceneSlug.maybe_generate_slug()
    |> SceneSlug.unique_constraint()
  end

  defp maybe_add_scene_sid_to_changeset(changeset) do
    scene_sid = changeset |> get_field(:scene_sid) || Ret.Sids.generate_sid()
    put_change(changeset, :scene_sid, "#{scene_sid}")
  end
end