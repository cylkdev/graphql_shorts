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

  describe "&convert_to_error_message/3 " do
    test "returns expected user errors given changeset" do
      changeset =
        %Schemas.Post{}
        |> Schemas.Post.changeset(%{})
        |> Changeset.put_assoc(:comments, [Schemas.Comment.changeset(%Schemas.Comment{}, %{})])

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

      schema =
        [
          path: [:input],
          keys: [
            title: [
              input_key: :title,
              resolve: fn message, field -> {message, field} end,
              keys: []
            ],
            comments: [
              input_key: :comments,
              resolve: fn message, field -> {message, field} end,
              keys: [
                body: [
                  input_key: :body,
                  resolve: fn message, field -> {message, field} end,
                  keys: []
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
             ] = ChangesetBridge.convert_to_error_message(changeset, arguments, schema)
    end

    test "returns users errors with keyword-list schema" do
      errors =
        %{
          title: ["can't be blank"],
          comments: [
            %{body: ["can't be blank"]}
          ]
        }

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

      schema =
        [
          path: [:input],
          keys: [
            title: [
              input_key: :title,
              resolve: fn message, field -> {message, field} end,
              keys: []
            ],
            comments: [
              input_key: :comments,
              resolve: fn message, field -> {message, field} end,
              keys: [
                body: [
                  input_key: :body,
                  resolve: fn message, field -> {message, field} end,
                  keys: []
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
             ] = ChangesetBridge.convert_to_error_message(errors, arguments, schema)
    end

    test "returns users errors with list of atoms schema" do
      errors = %{title: ["can't be blank"]}

      arguments = %{input: %{title: ""}}

      schema = [
        path: [:input],
        keys: [:title]
      ]

      assert [
               %GraphQLShorts.UserError{
                 message: "can't be blank",
                 field: [:input, :title]
               }
             ] = ChangesetBridge.convert_to_error_message(errors, arguments, schema)
    end

    test "returns users errors with schema that has atoms and keyword lists" do
      errors =
        %{
          title: ["can't be blank"],
          comments: [
            %{body: ["can't be blank"]}
          ]
        }

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

      schema =
        [
          path: [:input],
          keys: [
            :title,
            comments: [
              input_key: :comments,
              resolve: fn message, field -> {message, field} end,
              keys: [
                body: [
                  input_key: :body,
                  resolve: fn message, field -> {message, field} end,
                  keys: []
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
             ] = ChangesetBridge.convert_to_error_message(errors, arguments, schema)
    end

    test "does not return users errors for nested fields with list of atoms schema" do
      errors =
        %{
          title: ["can't be blank"],
          comments: [
            %{body: ["can't be blank"]}
          ]
        }

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

      schema =
        [
          path: [:input],
          keys: [:title, :comments]
        ]

      assert [
               %GraphQLShorts.UserError{
                 message: "can't be blank",
                 field: [:input, :title]
               }
             ] = ChangesetBridge.convert_to_error_message(errors, arguments, schema)
    end
  end
end
