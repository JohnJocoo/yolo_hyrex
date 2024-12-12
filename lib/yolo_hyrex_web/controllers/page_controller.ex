defmodule YoloWeb.PageController do
  use YoloWeb, :controller

  def redirect_matches(conn, _params) do
    redirect(conn, to: ~p"/matches")
  end
end
