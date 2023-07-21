ExUnit.start()

Mox.defmock(MockClient.Summoner, for: RiotClient.SummonerClient)
Mox.defmock(MockClient.Match, for: RiotClient.MatchClient)
