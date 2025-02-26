defmodule GraphQLShorts.Support.Ecto.Schemas.Post do
  @moduledoc false
  use Ecto.Schema
  @timestamps_opts type: :utc_datetime

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "posts" do
    field :title, :string
    field :body, :string

    has_many :comments, GraphQLShorts.Support.Ecto.Schemas.Comment

    belongs_to :user, GraphQLShorts.Support.Ecto.Schemas.User

    timestamps()
  end

  @required_fields [:title]

  @allowed_fields [
                    :body,
                    :user_id
                  ] ++ @required_fields

  @doc false
  def changeset(model_or_changeset, attrs \\ %{}) do
    model_or_changeset
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
    |> validate_length(:title, min: 3)
  end

  @doc false
  def create_changeset(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
  end
end
