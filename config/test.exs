import Config

config :riot_client,
  api_key: "riot-api-key",
  http_client: HTTPoison.BaseMock,
  do_rate_limit: false

config :summoner_watch,
  riot_client: MockClient,
  check_times: 1,
  check_interval: 0
