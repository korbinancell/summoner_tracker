defmodule RiotClient.Match do
  @moduledoc """
  Calls to Match-V5 api https://developer.riotgames.com/apis#match-v5
  """

  import RiotClient
  import RiotClient.Region, only: [to_region_group: 1]

  defstruct ~w(participants)a

  @base_uri "lol/match/v5/matches"

  @timeout 10 * 1000

  def new(data) do
    %RiotClient.Match{
      participants: data.metadata.participants
    }
  end

  @spec get_ids_for_summoner(%RiotClient.Summoner{}, opts :: Keyword.t()) ::
          {:ok, [String.t()]} | {:error, term()}
  def get_ids_for_summoner(%RiotClient.Summoner{region: region, puuid: puuid}, opts) do
    url =
      region
      |> to_region_group
      |> get_url("/#{@base_uri}/by-puuid/#{puuid}/ids")

    with {:ok, match_ids} <- get(url, params: opts) do
      {:ok, match_ids}
    else
      err -> err
    end
  end

  @spec get_for_summoner(%RiotClient.Summoner{}, count :: integer) ::
          {:ok, [%RiotClient.Match{}]} | {:error, term()}
  def get_for_summoner(%RiotClient.Summoner{region: region} = sum, count) do
    with {:ok, match_ids} <- get_ids_for_summoner(sum, count: count),
         {:ok, matches} <- get_info(match_ids, region) do
      {:ok, matches}
    else
      {:error, error} -> {:error, "Error while fetching match ids '#{inspect(error)}'"}
    end
  end

  @spec get_info(ids :: [String.t()], region :: String.t()) ::
          {:ok, [%RiotClient.Match{}]} | {:error, term()}
  def get_info(ids, region) when is_list(ids) do
    ids
    |> Enum.map(fn id -> Task.async(fn -> get_info(id, region) end) end)
    |> Enum.map(fn task -> Task.await(task, @timeout) end)
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, match}, {_, acc} -> {:cont, {:ok, [match | acc]}}
      {:error, err}, _ -> {:halt, {:error, err}}
    end)
    |> then(fn
      {:ok, matches} -> {:ok, Enum.reverse(matches)}
      resp -> resp
    end)
  end

  @spec get_info(id :: String.t(), region :: String.t()) ::
          {:ok, %RiotClient.Match{}} | {:error, term()}
  def get_info(id, region) when is_binary(id) do
    url =
      region
      |> to_region_group
      |> get_url("/#{@base_uri}/#{id}")

    with {:ok, match} <- get(url) do
      {:ok, new(match)}
    else
      {:error, error} -> {:error, "Error while fetching match info '#{inspect(error)}'"}
    end
  end
end
