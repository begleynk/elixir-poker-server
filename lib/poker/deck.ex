defmodule Poker.Deck do
  def new do
    :random.seed(:os.timestamp)
    create_deck |> shuffle
  end

  def draw_card([top | cards]) do
    {:ok, top, cards}
  end

  def draw_card([]) do
    {:error, :empty_deck, []}
  end

  def draw_cards(deck, count) do
    {cards, new_deck} = Enum.reduce(1..count, {[], deck}, fn(_, {cards, deck}) ->
      case Poker.Deck.draw_card(deck) do
        {:ok, card, tmp_deck} -> {[card | cards], tmp_deck}
        {:error, :empty_deck, []} -> {cards, []}
      end
    end)

    case length(cards) do
      ^count -> {:ok, cards, new_deck}
      _ -> {:error, :not_enough_cards, deck}
    end
  end

  def cards_left(deck) do
    length(deck)
  end

  def has_card?(deck, card_to_match) do
    Enum.find(deck, fn(card) -> card == card_to_match end) != nil
  end

  defp create_deck do
    for suit <- [:spades, :clubs, :diamonds, :hearts], value <- 1..13 do
      %Poker.Card{suit: suit, value: value}
    end
  end

  defp shuffle(cards) do
    cards |> Enum.shuffle
  end
end
