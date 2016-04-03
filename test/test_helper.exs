ExUnit.start

Mix.Task.run "ecto.create", ~w(-r Poker.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r Poker.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(Poker.Repo)

