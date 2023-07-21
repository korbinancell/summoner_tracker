defmodule RiotClient.Summoner do
  @behaviour RiotClient.SummonerClient
  @moduledoc """
  Calls to Summoner-V4 api https://developer.riotgames.com/apis#summoner-v4/
  """
  import RiotClient

  defstruct ~w(name region profile_icon_id puuid summoner_level)a

  @base_uri "lol/summoner/v4/summoners"

  @timeout 10 * 1000

  def new(region, item) do
    %RiotClient.Summoner{
      name: item.name,
      profile_icon_id: item.profileIconId,
      puuid: item.puuid,
      summoner_level: item.summonerLevel,
      region: region
    }
  end

  @impl true
  def get_by_name(name, region) do
    url = get_url(region, "/#{@base_uri}/by-name/#{name}")

    with {:ok, summoner} <- get(url) do
      {:ok, new(region, summoner)}
    else
      {:error, error} -> {:error, "Error while fetching summoner '#{inspect(error)}'"}
    end
  end

  @impl true
  def get_by_puuid(puuids, region) when is_list(puuids) do
    puuids
    |> Enum.map(fn puuid -> Task.async(fn -> get_by_puuid(puuid, region) end) end)
    |> Enum.map(fn task -> Task.await(task, @timeout) end)
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, summoner}, {_, acc} -> {:cont, {:ok, [summoner | acc]}}
      {:error, err}, _ -> {:halt, {:error, err}}
    end)
    |> then(fn
      {:ok, summoners} -> {:ok, Enum.reverse(summoners)}
      resp -> resp
    end)
  end

  @impl true
  def get_by_puuid(puuid, region) do
    url = get_url(region, "/#{@base_uri}/by-puuid/#{puuid}")

    with {:ok, summoner} <- get(url) do
      {:ok, new(region, summoner)}
    else
      {:error, error} -> {:error, "Error while fetching summoner by puuid '#{inspect(error)}'"}
    end
  end
end
