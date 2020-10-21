defmodule DryExt.Events do
  def publish(topic, data) do
    %EventBus.Model.Event{
      id: Ecto.UUID.generate(),
      topic: topic,
      data: data
    }
    |> notify()
  end

  def notify(event) do
    with :test <- Mix.env() do
      instrument(:notify, event)
    else
      _ -> event |> notify!()
    end

    :ok
  end

  defdelegate notify!(event),
    to: EventBus,
    as: :notify

  defdelegate topic_exist?(topic),
    to: EventBus

  defdelegate topics,
    to: EventBus

  defdelegate register_topic(topic),
    to: EventBus

  defdelegate unregister_topic(topic),
    to: EventBus

  defdelegate subscribe(topic),
    to: EventBus

  defdelegate unsubscribe(subscriber),
    to: EventBus

  defdelegate subscribed?(subscriber_with_topic_patterns),
    to: EventBus

  defdelegate subscribers,
    to: EventBus

  defdelegate subscribers(topic),
    to: EventBus

  defdelegate fetch_event(event),
    to: EventBus

  defdelegate fetch_event_data(event),
    to: EventBus

  def mark_as_completed(subscriber_with_event_ref) do
    with :test <- Mix.env() do
      instrument(:complete, subscriber_with_event_ref)
    end

    subscriber_with_event_ref |> mark_as_completed!()
  end

  defdelegate mark_as_completed!(subscriber_with_event_ref),
    to: EventBus,
    as: :mark_as_completed

  defdelegate mark_as_skipped(subscriber_with_event_ref),
    to: EventBus

  defp instrument(action, event) do
    test_process() |> send({action, event})
  end

  defp test_process do
    Mix.Project.config()[:app]
    |> Application.get_env(:shared_test_process) || self()
  end
end
