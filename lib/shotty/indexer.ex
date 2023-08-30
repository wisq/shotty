defmodule Shotty.Indexer do
  @indexers %{
    :generic => Shotty.Indexer.Generic,
    :steam => Shotty.Indexer.Steam
  }

  @default_indexer :generic

  @type config :: term
  @callback configure(opts :: Keyword.t()) :: config()
  @callback latest(config :: config(), count :: integer) :: [Path.t()]

  def configure(opts) do
    {indexer, opts} = Keyword.pop(opts, :indexer, @default_indexer)
    module = indexer_module(indexer)
    config = module.configure(opts)
    {module, config}
  end

  def latest({module, config}, count) do
    module.latest(config, count)
  end

  defp indexer_module(indexer) when is_atom(indexer) do
    case Map.fetch(@indexers, indexer) do
      {:ok, module} ->
        module

      :error ->
        if Code.ensure_loaded?(indexer) do
          indexer
        else
          raise "Indexer not found: #{inspect(indexer)}"
        end
    end
  end
end
