defmodule DryExt.EventsTest do
  defmodule TestSubscriber do
    use DryExt.Events.Subscriber, topics: [".*"]

    def handle_event(_topic, _data), do: :ok
  end

  use ExUnit.Case
  use DryExt.ExUnit.EventCase
  alias DryExt.Events

  @topic :test_user_event

  test "event_bus" do
    :ok = Events.register_topic(@topic)

    start_supervised!({TestSubscriber, []})
    Process.sleep(100)

    assert_subscribed({TestSubscriber, [".*"]})

    :ok = Events.publish(@topic, %{email: "user@example.com"})
    assert_receive {:notify, %EventBus.Model.Event{topic: topic, id: id} = event}

    :ok = event |> Events.notify!()
    assert_receive {:complete, {TestSubscriber, ^topic, ^id}}
  end
end
