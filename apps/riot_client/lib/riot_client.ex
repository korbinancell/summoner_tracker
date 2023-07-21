defmodule RiotClient do
  @moduledoc """
  Wrapper client for riot api
  """

  @type region :: String.t()

  @do_rate_limit Application.compile_env!(:riot_client, :do_rate_limit)

  def get_url(region, path), do: "https://#{region}.api.riotgames.com#{path}"

  def get(url, opts \\ []) do
    if @do_rate_limit do
      hold = get_bandwidth()

      case hold do
        :ok ->
          do_get(url, opts)

        wait ->
          Process.sleep(wait)
          get(url, opts)
      end
    else
      do_get(url, opts)
    end
  end

  @allowed_errors [:closed, :connect_timeout]

  defp do_get(url, opts) do
    with {:ok, %{body: body, status_code: 200}} <-
           get_client().get(url, get_headers(), opts),
         {:ok, body} <- Jason.decode(body, keys: :atoms) do
      {:ok, body}
    else
      {_, %Jason.DecodeError{data: data}} ->
        {:error, "unable to parse response: '#{inspect(data)}'"}

      {_, %HTTPoison.Response{status_code: 429, headers: headers}} ->
        retry_after(headers, url, opts)

      {_, %HTTPoison.Error{reason: reason}} when reason in @allowed_errors ->
        retry_after(2, url, opts)

      {_, %HTTPoison.Error{reason: reason}} ->
        {:error, "unable to parse response: '#{inspect(reason)}'"}

      {_, err} ->
        {:error, err}
    end
  end

  defp retry_after(headers, url, opts) when is_list(headers) do
    retry_amount =
      headers
      |> Enum.find(fn {header, _} -> header == "Retry-After" end)
      |> elem(1)
      |> String.to_integer()

    Process.sleep(retry_amount * 1000)
    get(url, opts)
  end

  defp retry_after(amount, url, opts) when is_number(amount) do
    Process.sleep(amount)
    get(url, opts)
  end

  defp get_client, do: Application.get_env(:riot_client, :http_client)

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

    {max_requests, _} = @max_requests

    wait_time = (timeout || 0) - get_timestamp()
    if wait_time <= 0, do: start_timeout(limiter)

    if add_request(limiter) < max_requests, do: :ok, else: wait_time
  end

  defp start_timeout(limiter) do
    {_, time_span} = @max_requests

    timeout = get_timestamp() + time_span
    :ets.insert(limiter, [{:timeout, timeout}, {:count, 0}])
  end

  defp add_request(limiter), do: :ets.update_counter(limiter, :count, {2, 1})

  defp get_timestamp, do: DateTime.now!("Etc/UTC") |> DateTime.to_unix(:millisecond)
end
