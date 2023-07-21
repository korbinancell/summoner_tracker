defmodule SummonerWatch.CLI do
  @timeout 61 * 60 * 1000
  @options [strict: [summoner: :string, region: :string], aliases: [s: :summoner, r: :region]]
  def main(args) do
    {opts, _} = OptionParser.parse!(args, @options)

    with {:ok, msg, task_list} <-
           SummonerWatch.start_watch(opts[:summoner], opts[:region], &callback/1) do
      IO.puts(inspect(msg))
      IO.puts("Waiting...")

      task_list
      |> Enum.map(&Task.await(&1, @timeout))

      IO.puts("Done watching")
    else
      {:error, err} -> IO.puts("ERROR: #{err}")
    end
  end

  defp callback({:ok, event}), do: IO.puts(event)
  defp callback({:error, er}), do: IO.puts("ERROR: #{er}")
end
