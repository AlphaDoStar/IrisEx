# IrisEx

Elixir로 작성된 Iris 클라이언트 프레임워크입니다.

## 설치

`mix.exs`에 dependency를 추가하세요:

```elixir
def deps do
  [
    {:iris_ex, git: "https://github.com/AlphaDoStar/IrisEx.git"}
  ]
end
```

## 시작하기

### 1. 챗봇 생성

```elixir
defmodule MyBot do
  use IrisEx.Bot

  on :message do
    match "안녕" do
      reply("안녕하세요!")
    end
  end
end
```

### 2. Application 설정

```elixir
defmodule MyApp.Application do
  use IrisEx.Application,
    bots: [MyBot],
    ws_url: "ws://localhost:3000/ws",
    http_url: "http://localhost:3000",
    children: []
end
```

### 3. mix.exs 설정

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {MyApp.Application, []}
  ]
end
```

### 4. 실행

```bash
# 개발 모드로 실행
mix run --no-halt

# 또는 iex에서 실행
iex -S mix
```

## 주요 기능

### 메시지 매칭

텍스트와 정규표현식으로 메시지를 매칭할 수 있습니다:

```elixir
# 정확한 텍스트
match "greet" do
  reply("반갑습니다.")
end

# 정규표현식 + 파라미터 추출
match ~r/greet (.+)/ do
  [name] = args
  reply("#{name} 님, 안녕하세요!")
end
```

### 상태 관리

대화 흐름을 상태로 관리할 수 있습니다:

```elixir
on :message do
  # 채팅방 ID에 따른 상태 관리
  set chat.room.id

  state :default do
    match "메뉴" do
      reply("1. 딸기\n2. 바나나")
      trans :selection
    end
  end

  state :selection do
    match ~r/^(\d)$/ do
      [choice] = args
      case String.to_integer(choice) do
        1 -> reply("딸기를 선택하셨네요!")
        2 -> reply("바나나를 선택하셨네요!")
        _ -> :ok
      end
      trans :default
    end
  end
end
```

### 이벤트 처리

다양한 채팅 이벤트에 반응할 수 있습니다:

```elixir
# 메시지 이벤트
on :message do
  # 메시지 처리 로직
end

# 새 멤버 입장
on :new_member do
  reply("#{chat.sender.name} 님, 환영합니다!")
end

# 기존 멤버 퇴장
on :del_member do
  reply("#{chat.sender.name} 님, 잘가요!")
end
```

### 컨텍스트 접근

`chat` 변수로 채팅방과 사용자 정보에 접근할 수 있습니다:

```elixir
on :message do
  match "정보" do
    reply("채팅방: #{chat.room.id}")
    reply("사용자: #{chat.sender.name}")
  end
end
```

## 완전한 예제

```elixir
defmodule FruitBot do
  use IrisEx.Bot

  on :message do
    set chat.room.id

    state :default do
      match "선택" do
        reply("어떤 과일이 좋으신가요?")
        reply("1. 딸기\n2. 바나나")
        trans :fruit_selection
      end
    end

    state :fruit_selection do
      match ~r/^(\d)$/ do
        [index] = args
        case String.to_integer(index) do
          1 -> reply("난 바나나가 더 좋은데...")
          2 -> reply("난 딸기가 더 좋은데...")
          _ -> reply("1 또는 2를 선택해주세요.")
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

    # 매칭되지 않은 경우 처리
  end

  on :new_member do
    reply("#{chat.sender.name} 님, 어서오세요!")
  end
end

defmodule MyApp.Application do
  use IrisEx.Application,
    bots: [FruitBot],
    ws_url: "ws://localhost:3000/ws",
    http_url: "http://localhost:3000",
    children: []
end
```

## 설정 옵션

### Application 옵션

- `bots` - 실행할 봇 모듈 리스트
- `ws_url` - WebSocket 서버 주소 (실시간 메시지 수신)
- `http_url` - HTTP API 서버 주소 (메시지 전송)
- `children` - 추가 supervisor children

## API 참조

### 매크로
- `on/2` - 이벤트 핸들러 정의
- `set/1` - 상태 구분 키 지정
- `state/2` - 상태별 정의
- `match/2` - 메시지 패턴 매칭
- `trans/1` - 상태 전환
- `reply/1` - 메시지 응답

### 컨텍스트 변수
- `chat` - 채팅 컨텍스트
- `args` - 매칭된 정규표현식 그룹
- `match_handled` - 메시지 패턴 매칭 여부
- `agent_id` - 상태 구분 키
- `agent_state` - 상태