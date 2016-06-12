defmodule Poker.Authentication do
  alias Poker.{Repo, User}

  def authenticate(%{ "email" => email, "password" => password }) do
    case Repo.get_by(User, email: email) do
      nil ->
        Comeonin.Bcrypt.dummy_checkpw
        {:error, :not_found}
      user ->
        verify_user_password(user, password)
    end
  end

  defp verify_user_password(user, password) do
    if Comeonin.Bcrypt.checkpw(password, user.password_hash) do
      {:ok, user}
    else
      {:error, :invalid_password}
    end
  end
end
