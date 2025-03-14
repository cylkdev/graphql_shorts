defmodule GraphQLShorts.CommonChangesetTest do
  use ExUnit.Case, async: true
  doctest GraphQLShorts.CommonChangeset

  alias Ecto.Changeset

  alias GraphQLShorts.{
    CommonChangeset,
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
             } = CommonChangeset.errors_on_changeset(changeset)
    end
  end

  describe "&translate_changeset_errors/3 " do
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

      input =
        %{
          title: "",
          comments: [
            %{
              body: ""
            }
          ]
        }

      definition =
        [
          keys: [
            title: [
              input_key: :title,
              resolve: &Function.identity/1,
              keys: []
            ],
            comments: [
              input_key: :comments,
              resolve: &Function.identity/1,
              keys: [
                body: [
                  input_key: :body,
                  resolve: &Function.identity/1,
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
             ] = CommonChangeset.translate_changeset_errors(changeset, input, definition)
    end

    test "returns users errors with keyword-list definition" do
      errors =
        %{
          title: ["can't be blank"],
          comments: [
            %{body: ["can't be blank"]}
          ]
        }

      input =
        %{
          title: "",
          comments: [
            %{
              body: ""
            }
          ]
        }

      definition =
        [
          keys: [
            title: [
              input_key: :title,
              resolve: &Function.identity/1,
              keys: []
            ],
            comments: [
              input_key: :comments,
              resolve: &Function.identity/1,
              keys: [
                body: [
                  input_key: :body,
                  resolve: &Function.identity/1,
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
             ] = CommonChangeset.translate_changeset_errors(errors, input, definition)
    end

    test "returns users errors with list of atoms definition" do
      errors = %{title: ["can't be blank"]}

      input = %{title: ""}

      definition = [
        keys: [:title]
      ]

      assert [
               %GraphQLShorts.UserError{
                 message: "can't be blank",
                 field: [:input, :title]
               }
             ] = CommonChangeset.translate_changeset_errors(errors, input, definition)
    end

    test "returns users errors with definition that has atoms and keyword lists" do
      errors =
        %{
          title: ["can't be blank"],
          comments: [
            %{body: ["can't be blank"]}
          ]
        }

      input =
        %{
          title: "",
          comments: [
            %{
              body: ""
            }
          ]
        }

      definition =
        [
          keys: [
            :title,
            comments: [
              input_key: :comments,
              resolve: &Function.identity/1,
              keys: [
                body: [
                  input_key: :body,
                  resolve: &Function.identity/1,
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
             ] = CommonChangeset.translate_changeset_errors(errors, input, definition)
    end

    test "does not return users errors for nested fields with list of atoms definition" do
      assert [
               %GraphQLShorts.UserError{
                 message: "can't be blank",
                 field: [:input, :title]
               }
             ] =
               CommonChangeset.translate_changeset_errors(
                 %{
                   title: ["can't be blank"],
                   comments: [
                     %{body: ["can't be blank"]}
                   ]
                 },
                 %{
                   title: "",
                   comments: [
                     %{body: ""}
                   ]
                 },
                 keys: [:title, :comments]
               )
    end
  end
end
