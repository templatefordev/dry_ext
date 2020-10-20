defmodule DryExt.Utils.String do
  @moduledoc false

  @doc """
    ## Examples

      iex> DryExt.Utils.String.random(7)
      "5KlvUjd"
  """
  @spec random(integer) :: binary
  def random(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
