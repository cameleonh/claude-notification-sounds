# Claude Code Notification Sounds (Windows)

Claude Code 작업 완료 및 권한 요청 시 밈 사운드로 알려주는 Windows용 알림 시스템

## 기능

- **작업 완료** → FBI Open Up! 🚨
- **권한 요청/선택지** → Bruh 😐
- `/notification-toggle` 명령어로 ON/OFF

## 빠른 설치

PowerShell에서 한 줄로 설치:

```powershell
irm https://raw.githubusercontent.com/cameleonh/claude-notification-sounds/main/install.ps1 | iex
```

설치 중에 사운드를 선택할 수 있습니다!

## 수동 설치

### 1. 저장소 클론
```bash
git clone https://github.com/your-username/claude-notification-sounds.git
cd claude-notification-sounds
```

### 2. 파일 복사
```powershell
# hooks 폴더 생성
mkdir -Force "$env:USERPROFILE\.claude\hooks\notification-sounds"

# 파일 복사
Copy-Item -Recurse hooks\* "$env:USERPROFILE\.claude\hooks\notification-sounds\"
Copy-Item -Recurse sounds "$env:USERPROFILE\.claude\hooks\notification-sounds\"

# 스킬 복사
mkdir -Force "$env:USERPROFILE\.claude\skills\notification-toggle"
Copy-Item skills\notification-toggle\SKILL.md "$env:USERPROFILE\.claude\skills\notification-toggle\"
```

### 3. settings.json 설정

`~/.claude/settings.json`에 다음 내용 추가:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"C:\\Users\\YOUR_USERNAME\\.claude\\hooks\\notification-sounds\\stop.ps1\"",
            "timeout": 5
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"C:\\Users\\YOUR_USERNAME\\.claude\\hooks\\notification-sounds\\notification.ps1\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

> **주의**: `YOUR_USERNAME`을 본인의 Windows 사용자명으로 변경하세요.

### 4. Claude Code 재시작

## 사용법

- **자동 재생**: Claude 작업 완료 시 자동으로 사운드 재생
- **토글**: `/notification-toggle`로 ON/OFF

## 밈 사운드 목록

| 사운드 | 설명 |
|--------|------|
| `vine-boom` | 쾅! 💥 |
| `fbi` | FBI Open Up! 🚨 |
| `bruh` | Bruh 😐 |
| `wow` | Wow 😮 |
| `nice` | Nice 👌 |
| `oof` | Oof 💀 |
| `yeet` | Yeet! 🚀 |
| `damn` | Damn! 😱 |
| `hell-nah` | Hell Nah 😤 |
| `airhorn` | Air Horn 📢 |
| `sad-violin` | Sad Violin 😢 |

## 사운드 변경

`hooks/stop.ps1` 또는 `hooks/notification.ps1` 파일에서 사운드 파일명을 변경:

```powershell
$SoundPath = "C:\Users\YOUR_USERNAME\.claude\hooks\notification-sounds\sounds\fbi.mp3"
```

## 파일 구조

```
claude-notification-sounds/
├── README.md
├── hooks/
│   ├── stop.ps1           # 작업 완료 사운드
│   ├── notification.ps1   # 권한 요청 사운드
│   ├── session-start.ps1  # 세션 시작 (뮤트)
│   ├── prompt-submit.ps1  # 프롬프트 제출 (뮤트)
│   └── toggle.ps1         # ON/OFF 토글
├── sounds/
│   ├── fbi.mp3
│   ├── bruh.mp3
│   ├── vine-boom.mp3
│   └── ... (기타 밈 사운드)
└── skills/
    └── notification-toggle/
        └── SKILL.md
```

## 라이선스

MIT License

## 크레딧

- 밈 사운드: [MyInstants](https://www.myinstants.com)
- 원본 아이디어: [peon-ping](https://github.com/tonyyont/peon-ping) (macOS)
