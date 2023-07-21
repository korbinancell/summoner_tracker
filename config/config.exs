# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

config :hackney, use_default_pool: false

config :riot_client,
  api_key: "",
  http_client: HTTPoison,
  do_rate_limit: true

config :summoner_watch,
  riot_client: RiotClient,
  riot_client_summoner: RiotClient.Summoner,
  riot_client_match: RiotClient.Match,
  check_times: 60,
  check_interval: 60 * 1000

import_config "#{Mix.env()}.exs"
