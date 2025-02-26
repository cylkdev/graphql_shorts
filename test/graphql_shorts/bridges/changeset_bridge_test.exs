defmodule GraphQLShorts.Bridges.ChangesetBridgeTest do
  use ExUnit.Case, async: true
  doctest GraphQLShorts.Bridges.ChangesetBridge

  alias Ecto.Changeset

  alias GraphQLShorts.{
    Bridges.ChangesetBridge,
    Support.Ecto.Schemas
  }

  describe "&errors_on_changeset/1: " do
    test "returns map with matching changeset errors" do
      # setup
      changeset =
        %Schemas.Post{}
        |> Schemas.Post.changeset(%{})
        |> Changeset.put_assoc(:comments, [Schemas.Comment.changeset(%Schemas.Comment{}, %{})])

      # expected errors exist on changeset?
      assert %Ecto.Changeset{
               changes: %{
                 comments: [
                   %Ecto.Changeset{
                     changes: %{},
                     data: %Schemas.Comment{},
                     errors: [body: {"can't be blank", [validation: :required]}]
                   }
                 ]
               },
               data: %Schemas.Post{},
               errors: [title: {"can't be blank", [validation: :required]}]
             } = changeset

      # ensure the errors map returned contain the same errors on the changeset.
      assert %{
               title: ["can't be blank"],
               comments: [
                 %{body: ["can't be blank"]}
               ]
             } = ChangesetBridge.errors_on_changeset(changeset)
    end
  end

  describe "&build_user_errors/3 " do
    test "returns expected user errors given changeset" do
      # changeset error map
      changeset =
        %Schemas.Post{}
        |> Schemas.Post.changeset(%{})
        |> Changeset.put_assoc(:comments, [Schemas.Comment.changeset(%Schemas.Comment{}, %{})])

      # expected errors exist on changeset?
      assert %Ecto.Changeset{
               changes: %{
                 comments: [
                   %Ecto.Changeset{
                     changes: %{},
                     data: %Schemas.Comment{},
                     errors: [body: {"can't be blank", [validation: :required]}]
                   }
                 ]
               },
               data: %Schemas.Post{},
               errors: [title: {"can't be blank", [validation: :required]}]
             } = changeset

      # mutation arguments
      arguments =
        %{
          input: %{
            title: "",
            comments: [
              %{
                body: ""
              }
            ]
          }
        }

      # mapping schema
      schema =
        [
          path: [:input],
          mappings: [
            :title,
            comments: [
              keys: [
                body: [
                  field: :body
                ]
              ]
            ]
          ]
        ]

      assert [
               %GraphQLShorts.UserError{
                 message: "can't be blank",
                 field: [:input, :title]
               },
               %GraphQLShorts.UserError{
                 message: "can't be blank",
                 field: [:input, :comments, :body]
               }
             ] = ChangesetBridge.build_user_errors(changeset, arguments, schema)
    end

    test "returns expected user errors given map" do
      # changeset error map
      errors =
        %{
          title: ["can't be blank"],
          comments: [
            %{body: ["can't be blank"]}
          ]
        }

      # mutation arguments
      arguments =
        %{
          input: %{
            title: "",
            comments: [
              %{
                body: ""
              }
            ]
          }
        }

      # mapping schema
      schema =
        [
          path: [:input],
          mappings: [
            :title,
            comments: [
              keys: [
                body: [
                  field: :body
                ]
              ]
            ]
          ]
        ]

      assert [
               %GraphQLShorts.UserError{
                 message: "can't be blank",
                 field: [:input, :title]
               },
               %GraphQLShorts.UserError{
                 message: "can't be blank",
                 field: [:input, :comments, :body]
               }
             ] = ChangesetBridge.build_user_errors(errors, arguments, schema)
    end

    test "can set field prefix" do
      # changeset error map
      errors = %{title: ["can't be blank"]}

      # mutation arguments
      arguments = %{input: %{title: ""}}

      # mapping schema
      schema =
        [
          path: [:input],
          mappings: [:title]
        ]

      assert [
               %GraphQLShorts.UserError{
                 message: "can't be blank",
                 field: [:prefix, :input, :title]
               }
             ] =
               ChangesetBridge.build_user_errors(errors, arguments, schema,
                 field_prefix: [:prefix]
               )
    end
  end
end
