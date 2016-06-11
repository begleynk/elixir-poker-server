defmodule Poker.User do
  use Poker.Web, :model

  schema "users" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :password, :string, virtual: true

    timestamps
  end

  @required_fields ~w()
  @optional_fields ~w(email username password)

  def new_user_changeset do
    cast(%Poker.User{}, %{ username: random_username }, @required_fields, @optional_fields)
  end

  defp random_username do
    Faker.Name.title <> " " <>
    Faker.Name.first_name <> ", " <>
    Faker.Name.last_name <> ", " <>
    Faker.Name.suffix
  end
end
