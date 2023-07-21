defmodule RiotClientTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  test "includes api key" do
    expect(HTTPoison.BaseMock, :get, fn _, headers, _ ->
      with {"X-Riot-Token", "riot-api-key"} <-
             Enum.find(headers, fn {header, _} -> header == "X-Riot-Token" end) do
        {:ok, %HTTPoison.Response{body: "{}", status_code: 200}}
      else
        _ -> {:error, %HTTPoison.Response{body: "Did not include header", status_code: 401}}
      end
    end)

    assert {:ok, _} = RiotClient.get("")
  end

  describe "RiotClient.Summoner" do
    test "get_by_name handles error" do
      expect(HTTPoison.BaseMock, :get, fn _, _, _ -> {:error, "invalid request"} end)
      assert {:error, _} = RiotClient.Summoner.get_by_name("eyes", "na1")
    end

    test "get summoner by name" do
      name = "eyesfordayz"
      region = "na1"

      expect(
        HTTPoison.BaseMock,
        :get,
        &ApiMocks.test_api/3
      )

      assert {:ok,
              %RiotClient.Summoner{
                name: ^name,
                region: ^region
              }} = RiotClient.Summoner.get_by_name(name, region)
    end

    test "get summoner by puuid" do
      puuid = "puuid_eyesfordayz"
      region = "na1"

      expect(
        HTTPoison.BaseMock,
        :get,
        &ApiMocks.test_api/3
      )

      assert {:ok,
              %RiotClient.Summoner{
                puuid: ^puuid,
                region: ^region
              }} = RiotClient.Summoner.get_by_puuid(puuid, region)
    end

    test "get multiple summoners by puuid and is stable" do
      puuids = ["puuid_eyesfordayz", "puuid_veepower"]
      region = "na1"

      expect(
        HTTPoison.BaseMock,
        :get,
        2,
        &ApiMocks.test_api/3
      )

      assert {:ok, summoners} = RiotClient.Summoner.get_by_puuid(puuids, region)

      puuids
      |> Enum.zip(summoners)
      |> Enum.map(fn {puuid, resp} ->
        assert %RiotClient.Summoner{
                 puuid: ^puuid,
                 region: ^region
               } = resp
      end)
    end
  end

  describe "RiotClient.Match" do
    test "get ids for summoner w/ count" do
      summoner = %RiotClient.Summoner{puuid: "puuid_eyesfordayz", region: "na1"}

      expect(
        HTTPoison.BaseMock,
        :get,
        &ApiMocks.test_api/3
      )

      assert {:ok, ["NA1_1", "NA1_2", "NA1_3"]} =
               RiotClient.Match.get_ids_for_summoner(summoner, count: 3)
    end

    test "get info for match" do
      match_id = "NA1_100"
      region = "na1"

      expect(
        HTTPoison.BaseMock,
        :get,
        &ApiMocks.test_api/3
      )

      assert {:ok, %RiotClient.Match{}} = RiotClient.Match.get_info(match_id, region)
    end

    test "get info for match_ids and is stable" do
      match_ids = ["NA1_100", "NA1_200"]
      region = "na1"

      expect(
        HTTPoison.BaseMock,
        :get,
        2,
        &ApiMocks.test_api/3
      )

      assert {:ok, matches} = RiotClient.Match.get_info(match_ids, region)

      match_ids
      |> Enum.zip(matches)
      |> Enum.map(fn {id, match} ->
        assert %RiotClient.Match{id: ^id, participants: _participants} = match
      end)
    end

    test "get match info for summoner" do
      summoner = %RiotClient.Summoner{puuid: "puuid_eyesfordayz", region: "na1"}

      expect(
        HTTPoison.BaseMock,
        :get,
        3,
        &ApiMocks.test_api/3
      )

      assert {:ok, matches} = RiotClient.Match.get_for_summoner(summoner, 2)

      matches
      |> Enum.map(fn match ->
        assert %RiotClient.Match{} = match
      end)
    end
  end
end
