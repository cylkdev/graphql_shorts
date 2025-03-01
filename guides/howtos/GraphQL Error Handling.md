# GraphQL Error Handling

GraphQL error handling is a fundamental aspect of
building reliable APIs. In this guide we will explore
GraphQL's approaches to error handling.

## Top-Level Errors

A top-level error prevents an operation from executing
and can affect multiple fields at once. These appear
in the top-most `:error` field alongside `:data` in
the GraphQL response.

## User Errors

User errors are predictable, application-specific errors
from validation or business logic failures. They appear
in the `data` object, providing a standardized way for
clients to receive resolved data alongside errors.

## Query vs Mutation Errors

Queries and mutations handle errors differently, meaning
the same error can appear differently depending on the
operation.

Queries retrieve structured data. If a query fails, it
either returns nil with an error in the "errors" array or
only affects specific fields, leaving others resolvable.
Unlike mutations, queries don’t structure business logic
errors inside data, so they go in the top-most "errors".

```elixir
query {
user(id: 1) {
    id
    email
}
}

%{
data: %{"user" => nil},
errors: [
    %{
    "message" => "You do not have permission to access this resource.",
    "extensions" => %{
        "code" => "FORBIDDEN",
        "id" => 1
    }
    }
]
}
```

Here, the query fails due to a business rule, returning
`nil` for user and adding an error to the errors array.

In mutations, business logic errors go inside the mutation
payload (e.g., userErrors) instead of as top-level errors.
Since mutations allow partial execution, some parts can
succeed while others fail.

```elixir
mutation {
updateUser(input: %{"id" => "1", "email" => "alice@example.com"}) {
    users {
    id
    email
    }
    userErrors {
    message
    field
    }
}
}

%{
data: %{
    "updateUser" => %{
    "user" => nil,
    "userErrors" => %{
        "message" => "You do not have permission to access this resource.",
        "field" => ["input", "id"]
    }
    }
}
}
```

Here, a user tries to update `id: 1` but lacks permission.
Since mutations define their own response, the error
appears in `userErrors` instead of blocking execution.

Now, consider a case where multiple users are updated,
and some succeed while others fail:

```elixir
mutation {
updateUsers(input: [
    %{"id" => "1", "email" => "alice@example.com"},
    %{"id" => "2", "email" => "invalid-email"},
    %{"id" => "3", "email" => "bob@example.com"}
]) {
    users {
    id
    email
    }
    userErrors {
    message
    field
    }
}
}

%{
data: %{
    "updateUsers" => [
    %{
        "users" => [
        %{"id" => "1", "email" => "alice@example.com"},
        nil,
        %{"id" => "3", "email" => "bob@example.com"}
        ],
        "userErrors" => [
        %{
            "message" => "You do not have permission to access this resource.",
            "field" => ["input", "users", "id"]
        }
        ]
    }
    ]
}
}
```

Here, a user tries to update three users, but one has an
invalid email. The mutation executes partially, updating
two users successfully and returning an error in
`userErrors` for the failed update.

In summary:

- GraphQL allows partial responses where some fields can
resolve while others fail.

- Mutations allow partial execution, attaching user errors
to the failed parts.

- Queries return `nil` for business logic errors (e.g.
data-validation and authorization failures) and place
them in the "errors" array.