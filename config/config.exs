import Config

config :graphql_shorts, :json_adapter, Jason

config :graphql_shorts, GraphQLShorts.Absinthe.Middleware,
  on_unrecognized_error: :warn,
  user_error_key: :user_errors
