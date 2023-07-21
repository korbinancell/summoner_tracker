ExUnit.start()

Mox.defmock(HTTPoison.BaseMock, for: HTTPoison.Base)

defmodule ApiMocks do
  def test_api(
        <<"https://", _region::binary-size(3),
          ".api.riotgames.com/lol/summoner/v4/summoners/by-name/", name::binary>>,
        _,
        _
      ) do
    %{
      id: "id_#{name}",
      accountId: "account_id_#{name}",
      puuid: "puuid_#{name}",
      name: name,
      profileIconId: 5433,
      revisionDate: 1_687_750_383_000,
      summonerLevel: 162
    }
    |> to_response
  end

  def test_api(
        <<"https://", _region::binary-size(3),
          ".api.riotgames.com/lol/summoner/v4/summoners/by-puuid/", puuid::binary>>,
        _,
        _
      ) do
    "puuid_" <> name = puuid

    %{
      id: "id_#{name}",
      accountId: "account_id_#{name}",
      puuid: puuid,
      name: name,
      profileIconId: 5433,
      revisionDate: 1_687_750_383_000,
      summonerLevel: 162
    }
    |> to_response
  end

  for puuid_len <- 9..22 do
    def test_api(
          <<"https://americas.api.riotgames.com/lol/match/v5/matches/by-puuid/",
            _puuid::binary-size(unquote(puuid_len)), "/ids">>,
          _,
          params: [count: count]
        ) do
      1..count
      |> Enum.map(&"NA1_#{&1}")
      |> to_response
    end
  end

  def test_api(
        "https://americas.api.riotgames.com/lol/match/v5/matches/" <> match_id,
        _,
        _
      ) do
    %{
      metadata: %{
        matchId: match_id,
        participants: ["puuid_eyesfordayz", "puuid_veepower"]
      }
    }
    |> to_response
  end

  defp to_response(response),
    do: {:ok, %HTTPoison.Response{status_code: 200, body: Jason.encode!(response)}}
end
