use Mix.Config

config :mastani_server, MastaniServerWeb.Endpoint,
  http: [port: 4001],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

# Configure your database
config :mastani_server, MastaniServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "mastani_server_ci",
  hostname: "localhost",
  pool_size: 10

config :mastani_server, :github_oauth,
  client_id: "3b4281c5e54ffd801f85",
  client_secret: "68462fdbab195251bb71662eb2bc9dd2cb083305"
