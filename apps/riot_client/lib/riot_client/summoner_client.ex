defmodule RiotClient.SummonerClient do
  @callback get_by_name(name :: String.t(), region :: String.t()) ::
              {:ok, %RiotClient.Summoner{}} | {:error, term()}
  @callback get_by_puuid(puuid :: [String.t()] | String.t(), region :: String.t()) ::
              {:ok, [%RiotClient.Summoner{}]} | {:error, term()}
end
