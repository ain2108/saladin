defmodule Saladin.Clock.BasicTest do
  use ExUnit.Case
  doctest Saladin.Clock

  test "registration with clock module successful" do
    {:ok, pid} = Saladin.Clock.start_link(%{})
    send(pid, {:register, self()})
    assert_receive {:registration_ok}, 5_000
  end
end
