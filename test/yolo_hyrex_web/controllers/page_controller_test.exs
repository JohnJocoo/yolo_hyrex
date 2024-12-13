defmodule YoloWeb.PageControllerTest do
  use YoloWeb.ConnCase

  import YoloWeb.Utils

  test "GET /matches", %{conn: conn} do
    conn = get(conn, ~p"/matches")
    assert html_response(conn, 200) =~ "class=\"matches\""
  end

  test "/matches return existing matches", %{conn: conn} do
    update_match(1, "Porto vs Boavista", "active")
    update_match(2, "Sporting vs Benfica", "paused")

    conn = get(conn, ~p"/matches")
    resp = html_response(conn, 200)

    assert resp =~ "Porto vs Boavista"
    assert resp =~ "Sporting vs Benfica"
  end

  test "/matches return match and status", %{conn: conn} do
    update_match(1, "Porto vs Boavista", "active")

    conn = get(conn, ~p"/matches")
    resp = html_response(conn, 200)

    assert resp =~ "Porto vs Boavista"
    assert resp =~ "active"
  end

  test "/matches update matches", %{conn: conn} do
    update_match(1, "Porto vs Boavista", "active")

    conn = get(conn, ~p"/matches")
    resp = html_response(conn, 200)

    assert resp =~ "Porto vs Boavista"
    assert resp =~ "active"
    refute resp =~ "paused"

    update_match(1, "Porto vs Boavista", "paused")

    conn = get(conn, ~p"/matches")
    resp = html_response(conn, 200)

    assert resp =~ "Porto vs Boavista"
    refute resp =~ "active"
    assert resp =~ "paused"
  end

  test "/matches update matches live", %{conn: conn} do
    update_match(1, "Porto vs Boavista", "active")

    {:ok, view, html} = live(conn, "/matches")
    assert html =~ "Porto vs Boavista"
    assert html =~ "active"
    refute html =~ "completed"

    update_match(1, "Porto vs Boavista", "completed")

    wait_until(1000, fn ->
      html = render(view)
      assert html =~ "Porto vs Boavista"
      refute html =~ "active"
      assert html =~ "completed"
    end)
  end
end
