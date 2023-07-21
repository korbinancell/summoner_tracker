defmodule SummonerWatchTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  test "invalid names" do
    ["e", "", "hhhhhhhhhhhhhhhhhh"]
    |> Enum.map(&assert {:error, "Invalid name"} = SummonerWatch.start_watch(&1, "na1"))
  end

  test "invalid region" do
    assert {:error, "Invalid region"} = SummonerWatch.start_watch("eyesfordayz", "nope")
  end

  @sum1 %RiotClient.Summoner{name: "eyesfordayz", puuid: "puuid_eyesfordayz", region: "na1"}
  @sum2 %RiotClient.Summoner{name: "Veepower", puuid: "puuid_veepower", region: "na1"}

  @match1 %RiotClient.Match{id: "NA1_1", participants: [@sum2.puuid, @sum1.puuid]}
  @match2 %RiotClient.Match{id: "NA1_2", participants: [@sum1.puuid, "extra_puuid"]}

  test "start_watch" do
    Process.register(self(), :start_watch_test)

    expect(
      MockClient.Summoner,
      :get_by_name,
      fn "eyesfordayz", _ -> {:ok, @sum1} end
    )

    expect(
      MockClient.Match,
      :get_for_summoner,
      fn _, 1 -> {:ok, [@match1]} end
    )

    expect(
      MockClient.Summoner,
      :get_by_puuid,
      fn ["puuid_veepower"], _ -> {:ok, [@sum2]} end
    )

    expect(
      MockClient.Match,
      :get_ids_for_summoner,
      2,
      fn
        @sum1, _ -> {:ok, [@match2.id]}
        @sum2, _ -> {:ok, []}
        _, _ -> {:error, "wat"}
      end
    )

    expected_event = "Summoner #{@sum1.name} completed match #{@match2.id}"

    callback = fn {:ok, event} ->
      send(:start_watch_test, {:found_match, event})
    end

    {:ok, summoners, tasks} =
      SummonerWatch.start_watch(
        @sum1.name,
        @sum1.region,
        callback,
        matches_to_fetch: 1
      )

    assert ["eyesfordayz", "Veepower"] = summoners

    tasks
    |> Enum.map(&Task.await/1)
    |> Enum.map(&assert :ok == &1)

    assert_received {:found_match, ^expected_event}
  end
end
