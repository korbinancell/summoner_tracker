defmodule RiotClient do
  @moduledoc """
  Wrapper client for riot api
  """

  @type region :: String.t()

  def get_url(region, path), do: "https://#{region}.api.riotgames.com#{path}"

  def get(url, opts \\ []) do
    case get_bandwidth() do
      :ok -> nil
      wait -> Process.sleep(wait)
    end

    with {:ok, %{body: body, status_code: 200}} <-
           HTTPoison.get(url, get_headers(), opts),
         {:ok, body} <- Jason.decode(body, keys: :atoms) do
      {:ok, body}
    else
      {_, %Jason.DecodeError{data: data}} ->
        {:error, "unable to parse response: '#{inspect(data)}'"}

      {_, %HTTPoison.Error{reason: reason}} ->
        {:error, "unable to parse response: '#{inspect(reason)}'"}
    end
  end

  defp get_headers() do
    [
      {"Content-Type", "application/json; charset=utf-8"},
      {"Accept-Language", "en-US,en;q=0.9"},
      {"X-Riot-Token", Application.get_env(:riot_client, :api_key)}
    ]
  end

  @max_requests {20, 1100}

  # Naive rate limiter.
  # TODO: limit requests per 2min as well {100, 12100}
  defp get_bandwidth do
    limiter =
      case :ets.whereis(__MODULE__) do
        :undefined -> :ets.new(__MODULE__, [:named_table, :public])
        _ -> __MODULE__
      end

    timeout =
      case :ets.lookup(limiter, :timeout) do
        [{:timeout, time}] -> time
        [] -> nil
      end

    count =
      case :ets.lookup(limiter, :count) do
        [{:count, time}] -> time
        [] -> nil
      end

    {max_requests, _} = @max_requests

    cond do
      is_nil(timeout) -> start_timeout(limiter)
      count < max_requests -> add_request(limiter)
      count == max_requests -> timeout - get_timestamp()
    end
  end

  defp start_timeout(limiter) do
    {_, time_span} = @max_requests

    timeout = get_timestamp() + time_span
    :ets.insert(limiter, [{:timeout, timeout}, {:count, 1}])

    Task.async(fn ->
      Process.sleep(time_span)
      :ets.insert(limiter, [{:timeout, nil}])
    end)

    :ok
  end

  defp add_request(limiter) do
    :ets.update_counter(limiter, :count, {2, 1})
    :ok
  end

  defp get_timestamp, do: DateTime.now!("Etc/UTC") |> DateTime.to_unix()
end
