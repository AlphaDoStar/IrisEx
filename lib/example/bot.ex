defmodule Example.Bot do
  use IrisEx.Bot

  on :message do
    set chat.room.id

    state :default do
      match "select" do
        reply("어떤 과일이 좋으신가요?")
        reply("1. 딸기\n2. 바나나")
        trans :fruit_selection
      end
    end

    state :fruit_selection do
      match ~r/^(\d)$/ do
        [choice] = args
        case String.to_integer(choice) do
          1 -> reply("난 바나나가 더 좋은데...")
          2 -> reply("난 딸기가 더 좋은데...")
          _ -> :ok
        end
        trans :default
      end
    end

    match "greet" do
      reply("반갑습니다.")
    end

    match ~r/greet (.+)/ do
      [name] = args
      reply("#{name} 님, 안녕하세요!")
    end
  end

  on :new_member do
    reply("#{chat.sender.name} 님, 어서오세요!")
  end
end
