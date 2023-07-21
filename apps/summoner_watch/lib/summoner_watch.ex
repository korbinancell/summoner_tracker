defmodule SummonerWatch do
  @moduledoc """
  Handles logic for core functionality
  """

  import RiotClient.Region, only: [region?: 1]

  @check_times Application.compile_env!(:summoner_watch, :check_times)
  @check_interval Application.compile_env!(:summoner_watch, :check_interval)
  @matches_to_watch 5

  @spec start_watch(name :: String.t(), region :: String.t(), any, matches_to_fetch: integer) ::
          {:error, any} | {:ok, list, list}
  def start_watch(name, region, callback \\ nil, opts \\ []) do
    callback = callback || fn {_, res} -> IO.puts(res) end
    matches_to_fetch = opts[:matches_to_fetch] || @matches_to_watch

    region =
      region
      |> String.trim()
      |> String.downcase()

    cond do
      !region?(region) -> {:error, "Invalid region"}
      !valid_username?(name) -> {:error, "Invalid name"}
      true -> do_watch(name, region, matches_to_fetch, callback)
    end
  end

  defp do_watch(name, region, matches_to_fetch, callback) do
    with {:ok, summoner} <- get_summoner_client().get_by_name(name, region),
         {:ok, matches} <- get_match_client().get_for_summoner(summoner, matches_to_fetch),
         puuids <- get_players(matches, summoner.puuid),
         {:ok, participants} <- get_summoner_client().get_by_puuid(puuids, region) do
      timestamp = get_timestamp()
      participants = [summoner | participants]

      watch_tasks =
        participants
        |> Enum.map(fn sum ->
          Task.Supervisor.async(SummonerWatch.TaskSupervisor, fn ->
            watch_summoner(sum, timestamp, @check_times, callback)
          end)
        end)

      participant_list = participants |> Enum.map(& &1.name)

      {:ok, participant_list, watch_tasks}
    else
      err -> err
    end
  end

  defp get_summoner_client,
    do: Module.concat([Application.get_env(:summoner_watch, :riot_client), Summoner])

  defp get_match_client,
    do: Module.concat([Application.get_env(:summoner_watch, :riot_client), Match])

  defp watch_summoner(_, _, 0, _), do: :ok

  defp watch_summoner(summoner, timestamp, retries, callback) do
    Process.sleep(@check_interval)

    case get_match_client().get_ids_for_summoner(summoner, count: 1, startTime: timestamp) do
      {:ok, [match_id]} ->
        callback.({:ok, "Summoner #{summoner.name} completed match #{match_id}"})
        watch_summoner(summoner, get_timestamp(), retries - 1, callback)

      {:ok, []} ->
        watch_summoner(summoner, get_timestamp(), retries - 1, callback)

      {:error, err} ->
        callback.({:error, "Error reporting on summoner '#{summoner.name}' '#{inspect(err)}'"})
        :error
    end
  end

  defp get_timestamp, do: DateTime.now!("Etc/UTC") |> DateTime.to_unix()

  defp get_players(matches, reject_id) do
    matches
    |> Enum.flat_map(& &1.participants)
    |> Enum.reject(&(&1 === reject_id))
    |> Enum.uniq()
  end

  defp valid_username?(name) when not is_binary(name), do: false
  defp valid_username?(""), do: false

  defp valid_username?(name) do
    len = String.length(name)
    3 <= len and len <= 16
  end
end
