defmodule Mix.Tasks.Esdump do
  use Mix.Task

  def run(args) do
    es = Enum.at(args, 0)
    index = Enum.at(args, 1)
    :logger.info "elasticsearch #{es}"
    :logger.info "index dump: #{index}" 
    with :ok <- File.mkdir_p(Path.dirname("./#{index}_dump.json")) do
      Esx.Req.scroll(es, index, nil)
    end
    pid = spawn fn -> 1 + 1 end
    {:ok, pid}
  end
end

