defmodule GraphQLShorts.Support.Ecto.Schemas.User do
  @moduledoc false
  use Ecto.Schema
  @timestamps_opts type: :utc_datetime

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "users" do
    field :email, :string
    field :status, :string

    has_many :posts, GraphQLShorts.Support.Ecto.Schemas.Post

    has_many :comments, GraphQLShorts.Support.Ecto.Schemas.Comment

    timestamps()
  end

  @required_fields [:email]

  @allowed_fields [:status] ++ @required_fields

  @doc false
  def changeset(model_or_changeset, attrs \\ %{}) do
    model_or_changeset
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
    |> validate_length(:email, min: 3)
  end

  @doc false
  def create_changeset(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
  end
end
