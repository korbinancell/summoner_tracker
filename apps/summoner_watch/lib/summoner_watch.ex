defmodule SummonerWatch do
  @moduledoc """
  Handles logic for core functionality
  """

  import RiotClient.Region, only: [region?: 1]

  def start_watch(name, region, callback \\ nil) do
    callback = callback || fn {_, res} -> IO.puts(res) end

    region =
      region
      |> String.trim()
      |> String.downcase()

    cond do
      !region?(region) -> {:error, "Invalid region"}
      !valid_username?(name) -> {:error, "Invalid name"}
      true -> do_watch(name, region, callback)
    end
  end

  @matches_to_watch 1
  @watch_for_min 60
  @min 60 * 1000
  defp do_watch(name, region, callback) do
    with {:ok, summoner} <- RiotClient.Summoner.get_by_name(name, region),
         {:ok, matches} <- RiotClient.Match.get_for_summoner(summoner, @matches_to_watch),
         puuids <- get_players(matches, summoner.puuid),
         {:ok, participants} <- RiotClient.Summoner.get_by_puuid(puuids, region) do
      timestamp = get_timestamp()
      participants = [summoner | participants]

      participants
      |> Enum.map(fn sum ->
        Task.Supervisor.async(SummonerWatch.TaskSupervisor, fn ->
          watch_summoner(sum, timestamp, @watch_for_min, callback)
        end)
      end)

      participants |> Enum.map(& &1.name)
    else
      err -> err
    end
  end

  defp watch_summoner(_, _, 0, _), do: :ok

  defp watch_summoner(summoner, timestamp, retries, callback) do
    Process.sleep(@min)

    with {:ok, [match_id]} <-
           RiotClient.Match.get_ids_for_summoner(summoner, count: 1, startTime: timestamp) do
      callback.({:ok, "Summoner #{summoner.name} completed match #{match_id}"})
      watch_summoner(summoner, get_timestamp(), retries - 1, callback)
    else
      {:ok, []} -> watch_summoner(summoner, get_timestamp(), retries - 1, callback)
      {:error, err} -> report_failure(summoner, err, callback)
    end
  end

  defp get_timestamp, do: DateTime.now!("Etc/UTC") |> DateTime.to_unix()

  defp report_failure(sum, error, callback) do
    callback.({:error, "Error reporting on summoner '#{sum.name}' '#{inspect(error)}'"})
    :error
  end

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
