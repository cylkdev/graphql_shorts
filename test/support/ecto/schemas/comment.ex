defmodule GraphQLShorts.Support.Ecto.Schemas.Comment do
  @moduledoc false
  use Ecto.Schema
  @timestamps_opts type: :utc_datetime

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "comments" do
    field :body, :string

    belongs_to :post, GraphQLShorts.Support.Ecto.Schemas.Post

    belongs_to :user, GraphQLShorts.Support.Ecto.Schemas.User

    timestamps()
  end

  @required_fields [:body]

  @allowed_fields [
                    :user_id,
                    :post_id
                  ] ++ @required_fields

  @doc false
  def changeset(model_or_changeset, attrs \\ %{}) do
    model_or_changeset
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
    |> validate_length(:body, min: 3)
  end

  @doc false
  def create_changeset(attrs \\ %{}) do
    changeset(%__MODULE__{}, attrs)
  end
end
