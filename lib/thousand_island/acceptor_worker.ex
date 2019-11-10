defmodule ThousandIsland.AcceptorWorker do
  use Task, restart: :transient

  require Logger

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run({server_pid, parent_pid, opts}) do
    Logger.debug("Acceptor #{inspect(self())} starting up")

    listener_pid = ThousandIsland.Server.listener_pid(server_pid)
    {:ok, listener_state} = ThousandIsland.Listener.listener_state(listener_pid)
    transport_module = ThousandIsland.Transport.transport_module(opts)
    handler_module = ThousandIsland.Handler.handler_module(opts)
    connection_sup_pid = ThousandIsland.Acceptor.connection_sup_pid(parent_pid)

    accept(listener_state, transport_module, handler_module, connection_sup_pid, opts)

    Logger.debug("Acceptor #{inspect(self())} shutting down")
  end

  defp accept(listener_state, transport_module, handler_module, connection_sup_pid, opts) do
    {:ok, socket} = transport_module.accept(listener_state)

    Logger.debug("Acceptor #{inspect(self())} accepting connection")

    ThousandIsland.ConnectionSupervisor.start_connection(
      connection_sup_pid,
      {socket, handler_module, opts}
    )

    accept(listener_state, transport_module, handler_module, connection_sup_pid, opts)
  end
end
