defmodule DryExt.ExUnit.EventCase do
  @moduledoc """
  EventCase module will handle registering the test process
  and also give us a new `assert_subscribed/1` test helper.


  Provides a function `handle_event/2` to handle a event.

  ## Examples

      defmodule EventsTest do
        use ExUnit.Case
        use DryExt.ExUnit.EventCase
        alias DryExt.Events

        test "event_bus" do
          :ok = Events.register_topic(:test_topic)
          start_supervised!({TestSubscriber, []})
          Process.sleep(100)

          assert_subscribed({TestSubscriber, [".*"]})
        end
      end
  """
  use ExUnit.CaseTemplate

  defmacro __using__(_) do
    quote do
      setup do
        Mix.Project.config()[:app]
        |> Application.put_env(:shared_test_process, self())

        :ok
      end

      def assert_subscribed({module, topics}) do
        assert DryExt.Events.subscribers()
               |> Enum.member?({module, topics})
      end
    end
  end
end
