defmodule AiChatWeb.ChatLive do
  use AiChatWeb, :live_view

  alias AiChat.Anthropic.Claude
  alias AiChat.FormValidators.ChatForm

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(form: to_form(ChatForm.changeset(%ChatForm{}, %{})))
      |> assign(:chain, nil)
      |> stream(:messages, [])
      |> assign(:loading, false)
      |> assign(:stream_data, "")
      |> assign(:unique_index, System.unique_integer([:positive]))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="bg-slate-50 h-screen flex flex-col">
      <section class="flex-1 overflow-hidden" id="messages-section">
        <div class="h-full overflow-y-auto" id="messages-stream" phx-update="stream">
          <div
            :for={{dom_id, message} <- @streams.messages}
            class="bg-white m-2 p-4 rounded-sm shadow-sm"
            id={dom_id}
          >
            <%= raw(MDEx.to_html!(message.content)) %>
          </div>
        </div>
      </section>

      <div class="sticky bottom-0 bg-slate-50 border-t border-slate-200">
        <.simple_form
          for={@form}
          id="form"
          phx-change="validate"
          phx-submit="submit_chat"
          class="px-6  py-2"
        >
          <.spinner show={@loading} size="w-6 h-6" />
          <div class="flex gap-2 px-3">
            <div class="flex-1">
              <.input field={@form[:message]} type="text" placeholder="write something ..." />
            </div>
            <button class="h-full px-6 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 mt-2">
              Send
            </button>
          </div>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"chat_form" => data}, socket) do
    changeset = ChatForm.changeset(%ChatForm{}, data)
    {:noreply, assign(socket, :form, to_form(changeset, action: :insert))}
  end

  @impl Phoenix.LiveView
  def handle_event("submit_chat", %{"chat_form" => %{"message" => message} = data}, socket) do
    chain = socket.assigns.chain
    liveview_process = self()

    changeset = ChatForm.changeset(%ChatForm{}, data)

    if changeset.valid? do
      socket =
        socket
        |> stream_insert(:messages, %{id: System.unique_integer([:positive]), content: message})
        |> assign(form: to_form(ChatForm.changeset(%ChatForm{}, %{})))
        |> assign(:loading, true)
        |> assign(:stream_data, "")
        |> assign(:unique_index, System.unique_integer([:positive]))
        |> start_async("send_message", fn ->
          Claude.create(message, streaming_callback(liveview_process), chain)
        end)

      {:noreply, socket}
    else
      {:noreply, assign(socket, form: to_form(changeset, action: :insert))}
    end
  end

  @impl Phoenix.LiveView
  def handle_async("send_message", {:ok, {:ok, updated_chain, _response}}, socket) do
    socket =
      socket
      |> assign(:chain, updated_chain)
      |> assign(:loading, false)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_async("send_message", _response, socket) do
    # a lazy error handling
    socket =
      socket
      |> assign(:loading, false)
      |> put_flash(:error, "An error occurred try again")

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:streaming_response, message}, socket) do
    content = socket.assigns.stream_data <> message

    socket =
      socket
      |> stream_insert(:messages, %{
        id: socket.assigns.unique_index,
        content: content
      })
      |> assign(:stream_data, content)

    {:noreply, socket}
  end

  defp streaming_callback(liveview_process) do
    %{
      on_llm_new_delta: fn _model, %LangChain.MessageDelta{} = data ->
        # we received a piece of data
        send(liveview_process, {:streaming_response, data.content})
      end,
      on_message_processed: fn _chain, %LangChain.Message{} ->
        # the message was assmebled and is processed
       :ok
      end
    }
  end
end
