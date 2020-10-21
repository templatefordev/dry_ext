defmodule DryExt.Events.Subscriber do
  @moduledoc """
  Subscriber module implementation GenServer/EventBus boiler plate.
  Provides a function `handle_event/2` to handle a event.

  ## Examples

      defmodule TestSubscriber do
        use DryExt.Events.Subscriber, topics: [".*"]

        def handle_event(topic, data) do
          # do sth with data
          :ok
        end
      end
  """
  defmacro __using__(topics: topics) do
    quote do
      use GenServer, restart: :permanent

      alias DryExt.Events

      ### Client API ###

      def start_link(_),
        do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

      def process({_topic, _id} = event),
        do: GenServer.cast(__MODULE__, event)

      ### GenServer Callbacks ###

      def init(_),
        do: {:ok, nil, {:continue, :subscribe}}

      def handle_continue(:subscribe, _) do
        with :ok <- Events.subscribe({__MODULE__, unquote(topics)}) do
          {:noreply, nil}
        end
      end

      def handle_continue({:mark_as_completed, {topic, id}}, _) do
        with :ok <- Events.mark_as_completed({__MODULE__, topic, id}) do
          {:noreply, nil}
        end
      end

      def handle_cast({topic, id}, _state) do
        with event <- Events.fetch_event({topic, id}),
             %{data: data} <- event,
             :ok <- handle_event(topic, data) do
          {:noreply, nil, {:continue, {:mark_as_completed, {topic, id}}}}
        end
      end

      def handle_event(topic, _), do: {:error, topic}
      defoverridable handle_event: 2
    end
  end
end
