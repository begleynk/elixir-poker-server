defmodule Poker.User do
  use Poker.Web, :model

  alias Poker.{User}

  schema "users" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :password, :string, virtual: true

    timestamps
  end

  @required_fields ~w()
  @optional_fields ~w(email username password)

  def register_user_changeset(params) do
    %User{} 
    |> cast(params, ~w(email password), ~w(username))
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> validate_length(:username, min: 1, max: 128)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 8)
    |> encrypt_password
  end

  defp encrypt_password(current_changeset) do
    case current_changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(current_changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))
      _ ->
        current_changeset
    end
  end

  defp random_username do
    Faker.Name.title <> " " <>
    Faker.Name.first_name <> ", " <>
    Faker.Name.last_name <> ", " <>
    Faker.Name.suffix
  end
end
