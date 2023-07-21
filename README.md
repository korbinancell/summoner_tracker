# SummonerWatch

-   Given a valid `summoner_name` and `region` will fetch all summoners this summoner has played with in the last 5 matches. This data is returned to the caller as a list of summoner names (see below). Also, the following occurs:
    -   Once fetched, all summoners will be monitored for new matches every minute for the next hour
    -   When a summoner plays a new match, the match id is logged to the console, such as:
        -   `Summoner <summoner name> completed match <match id>`
-   The returned data should be formatted as:
    ```
    [summoner_name_1, summoner_name_2, ...]
    ```
-   Please upload this project to Github and send us the link.
    Notes:
-   Make use of Riot Developer API
    -   https://developer.riotgames.com/apis
        -   https://developer.riotgames.com/apis#summoner-v4
        -   https://developer.riotgames.com/apis#match-v5
    -   You will have to generate an api key. Please make this configurable so we can substitute our own key in order to test.

## Instructions

-   add riot api key to config

### CLI

-   `cd .\apps\summoner_watch\`
-   `mix escript.build`
-   `escript ./summoner_watch -s eyesfordayz -r na1`

### Function

-   `SummonerWatch.start_watch`
