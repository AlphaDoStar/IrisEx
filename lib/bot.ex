defmodule Bot do
  use IrisEx.Bot

  on :message do
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
