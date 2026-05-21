# ADR-003: 네트워크 프로토콜 — Go 소켓 서버 기반 동기화

**상태**: Accepted  
**결정 일자**: 2026-05-21  
**수정 일자**: —  
**작성자**: ceo  

---

## 1. 문제 상황 (Context)

에테르 가디언은 **PvP 멀티플레이 게임**으로 다음 데이터를 실시간 동기화해야 합니다:

```
플레이어 위치 (GPS 좌표)
    ↓
영토 점유 상태 (진지 위치, 상태)
    ↓
몬스터 생성/제거 (로컬 vs 동기화)
    ↓
네트워크 지연: <100ms (PvP 공정성 보장)
```

**고려사항**:
- 초당 수백 플레이어 동시 접속 가능성
- 모바일 네트워크 (4G LTE, 5G)의 불안정성
- 배터리 소비 (네트워크 활동 = 고전력)
- 오프라인 플레이 지원 (로컬 모드)

**선택지**:
1. **REST API** (HTTP) — 높은 오버헤드, 낮은 성능
2. **소켓 (TCP/UDP)** ← 낮은 지연, 효율적
3. **WebSocket** — 웹 호환, 모바일에서 성능 감소
4. **gRPC** — 현대적, 복잡도 증가

---

## 2. 결정 (Decision)

### 핵심 결정

**Go 기반 TCP 소켓 서버로 플레이어 상태 동기화, Protocol Buffers로 데이터 직렬화**

```
┌─────────────────────────────────────┐
│ Godot 클라이언트 (모바일)           │
│ - GDScript TCP Socket               │
└─────────────────────────────────────┘
              ↓ (TCP, 직렬화: Protobuf)
┌──────────────────────────────────────────┐
│ Go 백엔드 서버 (Linux/Docker)            │
├──────────────────────────────────────────┤
│ - TCP 리스너 (포트 8888)                 │
│ - 플레이어 상태 관리                     │
│ - 영토 데이터 저장소                     │
│ - Redis (플레이어 위치 캐시)            │
│ - PostgreSQL (영토 영구 저장)           │
└──────────────────────────────────────────┘
```

### 프로토콜 설계

**Message Format** (Protocol Buffers v3):

```protobuf
// messages.proto

syntax = "proto3";

// 플레이어 상태 업데이트
message PlayerState {
    int32 player_id = 1;
    double latitude = 2;          // GPS 위도
    double longitude = 3;         // GPS 경도
    int32 altitude = 4;           // 고도 (미터)
    
    repeated Territory claimed = 5;
    int32 ether_collected = 6;    // 수집한 에테르
    int32 health = 7;
}

// 영토 정보
message Territory {
    int32 territory_id = 1;
    double latitude = 2;
    double longitude = 3;
    int32 radius = 4;             // 반경 (미터)
    int32 owner_id = 5;
    int64 timestamp = 6;
}

// 서버 → 클라이언트 브로드캐스트
message WorldState {
    repeated PlayerState players = 1;
    repeated Territory territories = 2;
    int64 server_timestamp = 3;
}

// 클라이언트 → 서버 액션
message PlayerAction {
    int32 player_id = 1;
    enum ActionType {
        UPDATE_POSITION = 0;
        CLAIM_TERRITORY = 1;
        ATTACK_TERRITORY = 2;
    }
    ActionType action = 2;
    bytes data = 3;               // 액션별 데이터
    int64 client_timestamp = 4;
}
```

### 선택 근거

| 선택지 | 지연 | 대역폭 | 확장성 | 구현 복잡도 | 선택 |
|--------|------|--------|--------|-----------|------|
| REST (HTTP) | ⭐ (200-500ms) | ⭐ (높음) | ⭐ | ⭐⭐⭐⭐⭐ | ❌ |
| **TCP 소켓** | ⭐⭐⭐⭐⭐ (50-100ms) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ |
| WebSocket | ⭐⭐⭐ (100-150ms) | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⚠️ |
| gRPC | ⭐⭐⭐⭐ (100-150ms) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | ⚠️ |

**이유**:
1. **낮은 지연 (<100ms)**: PvP 공정성 필수 → TCP 직렬화 효율성
2. **효율적 직렬화**: Protocol Buffers는 JSON 대비 10배 작은 페이로드
3. **빠른 개발**: Go + Protobuf는 보일러플레이트 자동 생성
4. **확장 가능**: Redis 캐시로 수천 플레이어 처리 가능
5. **모바일 친화**: 저대역폭, 저배터리 환경 최적화

---

## 3. 구현 전략

### 3.1 Go 백엔드 구조

```go
// main.go
package main

import (
    "net"
    "github.com/ethereum/go-ethereum/p2p" // 아님, 커스텀
)

// 플레이어 연결 관리
type PlayerConnection struct {
    ID         int32
    Conn       net.Conn
    LastUpdate int64
    State      PlayerState
}

// 서버 상태
type GameServer struct {
    Players    map[int32]*PlayerConnection
    Territories map[int32]*Territory
    Redis      *redis.Client      // 플레이어 위치 캐시
    DB         *sql.DB            // PostgreSQL
}

// 메인 리스너
func (s *GameServer) Start(port string) {
    listener, _ := net.Listen("tcp", ":"+port)
    
    for {
        conn, _ := listener.Accept()
        
        // 각 플레이어 연결을 고루틴으로 처리
        go s.HandlePlayerConnection(conn)
    }
}

// 플레이어 메시지 처리
func (s *GameServer) HandlePlayerConnection(conn net.Conn) {
    buf := make([]byte, 1024)
    
    for {
        // 1. 메시지 수신 (Protobuf 직렬화)
        n, _ := conn.Read(buf)
        var action PlayerAction
        proto.Unmarshal(buf[:n], &action)
        
        // 2. 액션 처리 (위치 업데이트, 영토 점유 등)
        s.ProcessAction(&action)
        
        // 3. 월드 상태 브로드캐스트
        worldState := s.GetWorldState()
        data, _ := proto.Marshal(worldState)
        
        // 4. 모든 플레이어에 전송 (브로드캐스트)
        for _, player := range s.Players {
            player.Conn.Write(data)
        }
    }
}
```

### 3.2 GDScript 클라이언트

```gdscript
# network_manager.gd
extends Node3D

var socket: StreamPeerTCP = StreamPeerTCP.new()
var player_id: int32
var last_position: Vector3
var sync_interval: float = 0.1  # 100ms마다 동기화

func _ready():
    # 서버 연결
    socket.connect_to_host("game-server.example.com", 8888)
    
    set_process(true)

func _process(delta: float):
    if socket.get_status() != StreamPeerTCP.STATUS_CONNECTED:
        return
    
    # 1초마다 위치 업데이트
    if get_tree().get_frame() % 60 == 0:
        send_position_update()
    
    # 서버로부터 메시지 수신
    if socket.get_available_bytes() > 0:
        var data = socket.get_var()
        handle_server_message(data)

func send_position_update():
    # Protobuf 메시지 구성
    var action = {
        "player_id": player_id,
        "action": 0,  # UPDATE_POSITION
        "latitude": GPS.get_latitude(),
        "longitude": GPS.get_longitude(),
        "client_timestamp": Time.get_ticks_msec()
    }
    
    # 직렬화 (JSON 또는 Protobuf)
    var data = var_to_bytes(action)
    socket.put_data(data)

func handle_server_message(data: Dictionary):
    # 월드 상태 수신 처리
    for player in data["players"]:
        update_player_position(player)
    
    for territory in data["territories"]:
        update_territory_visual(territory)
```

### 3.3 배포 구성 (Docker)

```dockerfile
# Dockerfile
FROM golang:1.21-alpine

WORKDIR /app
COPY . .

# Go 의존성 설치
RUN go mod download
RUN go build -o server main.go

EXPOSE 8888

CMD ["./server"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  game-server:
    build: .
    ports:
      - "8888:8888"
    environment:
      POSTGRES_URL: postgres://user:pass@db:5432/ether_guardian
      REDIS_URL: redis://cache:6379
    depends_on:
      - db
      - cache

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: ether_guardian
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - db_data:/var/lib/postgresql/data

  cache:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  db_data:
```

---

## 4. 결과 (Consequences)

### 긍정적 영향

✅ **낮은 지연**: <100ms RTT 달성 (PvP 공정성 보장)  
✅ **효율적 대역폭**: Protobuf 직렬화로 JSON 대비 90% 크기 감소  
✅ **확장성**: Redis 캐시로 수천 플레이어 지원 가능  
✅ **배터리 효율**: 최소 대역폭 사용  
✅ **빠른 개발**: Go + Protobuf로 보일러플레이트 자동화  

### 부정적 영향

⚠️ **서버 운영 필수**: 클라우드 인프라 필요 (AWS, GCP, Azure)  
⚠️ **오프라인 플레이 제약**: 네트워크 없으면 로컬 모드만 지원  
⚠️ **디버깅 어려움**: 네트워크 지연 변수 많음  
⚠️ **동시성 관리**: 수백 플레이어 동시 처리 시 복잡도 증가  

### 완화 전략

- **클라우드 자동 스케일링**: Kubernetes 사용 (자동 가용성)
- **로컬 모드**: 네트워크 연결 시 동기화, 오프라인 시 로컬 플레이
- **망 동기화**: 재연결 시 서버 상태 병합 (충돌 해결)
- **성능 모니터링**: Prometheus + Grafana로 RTT 추적

---

## 5. 데이터 모델 (Schema)

### PostgreSQL 테이블

```sql
-- 플레이어 정보
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    ether_collected INT DEFAULT 0,
    health INT DEFAULT 100,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 영토 정보
CREATE TABLE territories (
    id SERIAL PRIMARY KEY,
    owner_id INT REFERENCES players(id),
    center_latitude DECIMAL(10, 8),
    center_longitude DECIMAL(11, 8),
    radius INT,  -- 미터
    status ENUM ('vacant', 'claimed', 'under_attack') DEFAULT 'vacant',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 플레이어 액션 로그 (감사, 분석용)
CREATE TABLE player_actions (
    id SERIAL PRIMARY KEY,
    player_id INT REFERENCES players(id),
    action_type VARCHAR(50),
    data JSONB,
    timestamp TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_territories_owner ON territories(owner_id);
CREATE INDEX idx_player_actions_player ON player_actions(player_id);
```

---

## 6. 성능 목표

| 메트릭 | 목표 | 달성 기준 |
|--------|------|---------|
| **RTT (Round-Trip Time)** | <100ms | 5G: 50-70ms, 4G LTE: 80-100ms |
| **패킷 손실률** | <2% | 네트워크 재시도 메커니즘 |
| **동기화 지연** | <50ms | 플레이어 위치 업데이트 |
| **처리량** | 1000 msg/sec | 플레이어당 ~10 msg/sec (100 플레이어 = 1000 msg/sec) |
| **메모리** | <500MB (서버) | Redis + DB 연결 풀 최적화 |

---

## 7. 대안 검토

### 7.1 REST API (HTTP)

**장점**: 표준, 학습곡선 낮음  
**단점**: 높은 오버헤드 (RTT 200-500ms), 배터리 소비 증가  
**판정**: ❌ 거부 (지연 요구사항 미달)

### 7.2 WebSocket

**장점**: 웹 호환, 방향성 통신  
**단점**: 모바일에서 성능 감소, HTTP 핸드셰이크 오버헤드  
**판정**: ⚠️ 부분 활용 (웹 대시보드용)

### 7.3 gRPC

**장점**: 최신 기술, 스트리밍 지원  
**단점**: 복잡도 증가, 모바일에서 오버헤드  
**판정**: ⚠️ 향후 고려 (초기 단계에는 소켓 + Protobuf)

---

## 8. 구현 로드맵

### Phase 1: 기초 서버 (2주)
- [ ] Go TCP 리스너 구현
- [ ] 플레이어 연결 관리
- [ ] Protocol Buffer 메시지 정의
- [ ] 기본 메시지 송수신 테스트

### Phase 2: 상태 동기화 (2주)
- [ ] 플레이어 위치 업데이트
- [ ] 영토 점유 로직
- [ ] 월드 상태 브로드캐스트

### Phase 3: 데이터베이스 (1주)
- [ ] PostgreSQL 스키마 설계
- [ ] Redis 캐시 통합
- [ ] 영토 영구 저장

### Phase 4: 클라이언트 통합 (2주)
- [ ] GDScript TCP 클라이언트
- [ ] Protobuf 직렬화
- [ ] 네트워크 에러 처리

### Phase 5: 테스트 & 배포 (1주)
- [ ] 부하 테스트 (100+ 플레이어)
- [ ] Docker 배포
- [ ] 성능 벤치마크

---

## 9. 보안 고려사항

```
플레이어 인증:
  └─ JWT 토큰 (연결 시)
  └─ 요청 서명 (타임스탬프 + HMAC)

데이터 암호화:
  └─ TLS/SSL (전송 계층)
  └─ Message 암호화 (선택사항)

입력 검증:
  └─ 위치 데이터 범위 검사
  └─ 플레이어 액션 권한 확인
```

---

## 10. 참고자료

- [Protocol Buffers 문서](https://developers.google.com/protocol-buffers)
- [Go net 패키지](https://golang.org/pkg/net/)
- [Redis for Caching](https://redis.io/topics/lru-cache)
- [PostgreSQL 공식 문서](https://www.postgresql.org/docs/)

