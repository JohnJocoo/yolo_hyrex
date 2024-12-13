defmodule Yolo.MatchesPipe do
  use Broadway

  alias Broadway.Message
  alias Yolo.MatchesStorage

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: Application.fetch_env!(:yolo_hyrex, :matches_updates_producer_module),
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 2]
      ],
      partition_by: fn %Message{data: %{"match_id" => id}} -> id end
    )
  end

  @impl true
  def handle_message(
        _,
        %Message{
          data: %{
            "match_id" => id,
            "crash" => crash,
            "name" => name,
            "status" => status
          }
        } = message,
        _context
      ) do
    if crash do
      raise RuntimeError, "Oops! #{id}"
    end

    MatchesStorage.update(id, name, status)

    message
  end
end
