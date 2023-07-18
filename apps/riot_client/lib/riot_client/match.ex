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

  @spec get_for_summoner(%RiotClient.Summoner{}, count :: integer) ::
          {:ok, [%RiotClient.Match{}]} | {:error, term()}
  def get_for_summoner(%RiotClient.Summoner{region: region, puuid: puuid}, count) do
    url =
      region
      |> to_region_group
      |> get_url("/#{@base_uri}/by-puuid/#{puuid}/ids")

    with {:ok, match_ids} <- get(url, params: [count: count]),
         {:ok, matches} <- get_info(match_ids, region) do
      {:ok, matches}
    else
      error -> error
    end
  end

  @spec get_info(ids :: [String.t()], region :: String.t()) ::
          {:ok, [%RiotClient.Match{}]} | {:error, term()}
  def get_info(ids, region) when is_list(ids) do
    matches =
      ids
      |> Enum.map(fn id -> Task.async(fn -> get_info(id, region) end) end)
      |> Enum.map(fn task -> Task.await(task, @timeout) end)
      |> Enum.reduce_while({:ok, []}, fn
        {:ok, match}, {_, acc} -> {:cont, {:ok, [match | acc]}}
        {:error, err}, _ -> {:halt, {:error, err}}
      end)

    case matches do
      {:ok, matches} -> {:ok, Enum.reverse(matches)}
      err -> err
    end
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
      error -> error
    end
  end
end
