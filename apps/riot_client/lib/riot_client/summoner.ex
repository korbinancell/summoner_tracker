defmodule RiotClient.Summoner do
  @moduledoc """
  Calls to Summoner-V4 api https://developer.riotgames.com/apis#summoner-v4/
  """
  import RiotClient

  defstruct ~w(name region profile_icon_id puuid summoner_level)a

  @base_uri "lol/summoner/v4/summoners"

  def new(region, item) do
    %RiotClient.Summoner{
      name: item.name,
      profile_icon_id: item.profileIconId,
      puuid: item.puuid,
      summoner_level: item.summonerLevel,
      region: region
    }
  end

  @spec get_by_name(name :: String.t(), region :: String.t()) ::
          {:ok, %RiotClient.Summoner{}} | {:error, term()}
  def get_by_name(name, region) do
    url = get_url(region, "/#{@base_uri}/by-name/#{name}")

    with {:ok, summoner} <- get(url) do
      {:ok, new(region, summoner)}
    else
      error -> error
    end
  end

  @spec get_by_name(name :: String.t(), region :: String.t()) ::
          {:ok, %RiotClient.Summoner{}} | {:error, term()}
  def get_by_puuid(puuid, region) do
    url = get_url(region, "/#{@base_uri}/by-puuid/#{puuid}")

    with {:ok, summoner} <- get(url) do
      {:ok, new(region, summoner)}
    else
      error -> error
    end
  end
end
