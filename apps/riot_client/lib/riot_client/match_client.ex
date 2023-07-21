defmodule RiotClient.MatchClient do
  @callback get_ids_for_summoner(%RiotClient.Summoner{}, opts :: Keyword.t()) ::
              {:ok, [String.t()]} | {:error, term()}
  @callback get_for_summoner(%RiotClient.Summoner{}, count :: integer) ::
              {:ok, [%RiotClient.Match{}]} | {:error, term()}
  @callback get_info(ids :: [String.t()] | String.t(), region :: String.t()) ::
              {:ok, [%RiotClient.Match{}]} | {:error, term()}
end
