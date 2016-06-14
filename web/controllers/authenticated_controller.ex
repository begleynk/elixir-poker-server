defmodule Poker.AuthenticatedController do

  defmacro __using__(_) do
    quote do
      use Poker.Web, :controller

      def action(conn, _params) do
        apply(
          __MODULE__,
          action_name(conn),
          [
            conn, 
            conn.params, 
            Guardian.Plug.current_resource(conn),
          ]
        )
      end
    end
  end
end
