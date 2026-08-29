#!/usr/bin/env python3
"""Rephoto 로컬 목 서버.

iOS 앱의 APITargetType 계약에 맞춰 목 픽스처(MockPhotoFixtures) 14장을 그대로 내려준다.
DB 없이 인메모리 상태로 동작하며, 태그 추가/수정/삭제·사진 업로드/삭제도 반영된다(재시작 시 초기화).
AI(태그·설명 생성, 자연어 검색)는 미구현 — 업로드 사진은 빈 태그 + 자리표시 설명,
검색은 태그·설명 문자열 부분일치로 대체한다.

실행:  python3 mock_server.py [포트] [응답지연ms] [호스트]   (기본 8080, 0, 127.0.0.1)
       시뮬레이터는 기본값으로 붙는다. 실기기로 붙일 때만 호스트를 0.0.0.0 으로
       — /debug/ 와 /images/ 는 인증 면제라 LAN에 열면 아무나 접근할 수 있다
이미지: Rephoto_iOS/Resources/MockImages/ 를 /images/<파일명> 으로 정적 서빙

앱을 이 서버에 붙이려면 아래 두 가지를 직접 바꿔야 한다(자동 전환 스위치는 없다).

  1. Config.xcconfig 의 BASE_URL 을 로컬 서버로
     — xcconfig는 // 를 주석으로 읽으므로 `http:/$()/127.0.0.1:8080` 처럼 $() 를 끼워 쓴다
     — 이 파일은 .gitignore 대상이라 변경이 로컬에만 남는다
  2. AppContainer.autoRegister() 의 DEBUG Mock provider 등록 3줄을 주석 처리
     — 등록된 상태로는 네트워크 레이어를 아예 타지 않아 이 서버로 요청이 오지 않는다
     — 테스트가 끝나면 반드시 주석을 해제한다. 주석 상태로 커밋되면 DEBUG 빌드가
       실서버를 때린다

두 값이 안 맞으면 조용히 실패하는 게 아니라 에러 화면이 뜬다. 서버가 없으면
URLError(.cannotConnectToHost) → AppError.unknown 경로로 떨어진다.

디버그 스위치 (터미널에서 호출):
  curl -X POST http://127.0.0.1:8080/debug/expire      → 액세스 토큰 만료: 다음 요청 401
                                                          → 앱이 조용히 리프레시 후 재시도해야 정상
  curl -X POST http://127.0.0.1:8080/debug/expire-all  → 리프레시도 401: forceLogout → LoginView
  (앱에서 다시 로그인하면 만료 상태 해제)
"""
import json
import re
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
DELAY_MS = int(sys.argv[2]) if len(sys.argv) > 2 else 0
# 기본은 루프백. /debug/·/images/는 인증 면제라 LAN에 열면 같은 네트워크의 누구나
# 픽스처를 읽고 세션 만료를 유발할 수 있다. 실기기 테스트가 필요할 때만 0.0.0.0으로
HOST = sys.argv[3] if len(sys.argv) > 3 else "127.0.0.1"

if DELAY_MS < 0:
    # time.sleep()이 ValueError를 던지는데 그 호출은 try 밖이라 모든 요청이
    # 응답 없이 죽는다. 원인 찾기 어려운 실패라 시작 시점에 막는다
    sys.exit("응답 지연은 0 이상이어야 합니다.")
MOCK_IMAGES_DIR = Path(__file__).resolve().parent / "Rephoto_iOS" / "Resources" / "MockImages"

# MockPhotoFixtures.entries 와 1:1 (photoId = index + 1, 최신순)
FIXTURES = [
    ("IMG_2015.JPG", ["해방촌", "노을"],
     "해 질 녘 옥상에서 내려다본 해방촌 주택가 풍경입니다. 분홍빛으로 물든 하늘 아래 낮은 지붕들이 겹겹이 이어져 있어요.",
     37.544113, 126.987962, "2026-07-13T10:45:07Z", False),
    ("IMG_7350.jpeg", ["산책", "시골길"],
     "수풀이 우거진 굴다리 아래로 좁은 길이 이어집니다. '집으로 가시는 길' 표지판이 정겨운 분위기를 더해요.",
     38.019283, 127.364792, "2026-07-08T02:07:01Z", False),
    ("IMG_0871.jpeg", ["연등", "축제"],
     "알록달록한 연등이 줄지어 걸린 거리 풍경입니다. 흐린 하늘 아래에서도 연등 색이 선명하게 살아 있어요.",
     37.558037, 126.999863, "2026-06-25T04:44:43Z", False),
    ("IMG_0813.jpeg", ["카페", "커피"],
     "카페에서 받은 에티오피아 시다마 원두 카드입니다. 창가로 들어온 햇살이 카드 위에 부드럽게 드리워져 있어요.",
     37.539475, 127.007828, "2026-06-18T07:30:37Z", False),
    ("IMG_0689.jpeg", ["남산타워", "퇴근길"],
     "충무로 거리에서 올려다본 남산서울타워입니다. 맑은 저녁 하늘 아래 타워가 또렷하게 보여요.",
     37.562180, 126.997672, "2026-06-11T09:24:21Z", False),
    ("IMG_0673.jpeg", ["도넛", "간식"],
     "글레이즈드 도넛 두 개와 커피 한 병. 달콤한 휴식 시간의 기록입니다.",
     37.558342, 126.998328, "2026-06-10T04:13:37Z", False),
    ("IMG_0446.jpeg", ["학교", "일상"],
     "강의실 화이트보드에 남겨진 낙서와 공지들. 학과 생활의 평범한 한 장면입니다.",
     37.558342, 126.998353, "2026-05-28T08:31:24Z", False),
    ("IMG_0356.jpeg", ["커피", "강의실"],
     "캐리어에 담긴 아이스커피 세 잔. 수업 전 나눠 마실 커피를 챙겨온 참입니다.",
     37.558472, 126.998567, "2026-05-13T05:44:47Z", False),
    ("IMG_0275.jpeg", ["남산", "전망"],
     "남산 산책로에서 내려다본 서울 도심 전경입니다. 초록 숲 너머로 빌딩들이 넓게 펼쳐져 있어요.",
     37.551133, 126.991142, "2026-05-06T06:52:42Z", False),
    ("8146BE25-73DE-4BC5-A48D-D3227D8DBF6F.jpg", ["쇼핑", "셀피"],
     "선글라스 매장 거울 앞에서 찍은 셀피입니다. 진열된 선글라스 너머로 카메라를 든 모습이 비쳐요.",
     37.541370, 127.059417, "2026-04-26T08:54:28Z", True),
    ("IMG_0099.jpeg", ["한강", "여의도"],
     "여의도 한강공원에서 바라본 63빌딩과 도심 실루엣. 오후의 역광이 만든 은은한 분위기가 인상적입니다.",
     37.517997, 126.957833, "2026-04-22T08:36:19Z", False),
    ("IMG_9898.jpeg", ["벚꽃", "봄"],
     "다리 난간 옆으로 벚꽃이 만개했습니다. 파란 하늘과 흰 꽃잎의 대비가 봄 분위기를 그대로 담고 있어요.",
     37.557605, 127.001511, "2026-04-02T03:46:35Z", False),
    ("IMG_9563.jpeg", ["강릉", "바다", "겨울바다"],
     "강릉 해변의 짙푸른 겨울 바다입니다. 구름 한 점 없는 하늘 아래로 하얀 파도가 밀려오고 있어요.",
     37.805705, 128.908875, "2026-02-25T03:45:21Z", False),
    ("IMG_8415.JPG", ["고양이", "길냥이"],
     "볕 좋은 잔디밭에 늘어져 낮잠 자는 주황 고양이. 완벽하게 이완된 자세가 귀엽습니다.",
     0, 0, "2025-11-06T17:10:53Z", False),
]

UPLOAD_DESCRIPTION = "(로컬 목 서버) 업로드된 사진입니다. AI 태그·설명 생성은 미구현이에요."


class Store:
    def __init__(self):
        self.lock = threading.Lock()
        self.photos = {}       # photoId -> dict
        self.photo_tags = {}   # photoTagId -> {"photoId", "tagName"}
        self.tag_ids = {}      # tagName -> tagId (한 번 부여되면 고정)
        self.uploaded_images = {}  # imageName -> bytes
        self.next_photo_id = 1
        self.next_photo_tag_id = 1
        self.next_tag_id = 1
        self.next_upload = 1
        # /debug/expire* 용 — required_access가 None이면 토큰 검사 안 함(기본)
        self.auth_generation = 0
        self.required_access = None
        self.refresh_enabled = True
        for file_name, tags, desc, lat, lon, created, sensitive in FIXTURES:
            pid = self.next_photo_id
            self.next_photo_id += 1
            self.photos[pid] = {
                "photoId": pid, "imageName": file_name, "fileName": file_name,
                "latitude": lat, "longitude": lon, "createdAt": created,
                "description": desc, "isSensitive": sensitive,
            }
            for name in tags:
                self._add_tag(pid, name)

    def _tag_id(self, name):
        if name not in self.tag_ids:
            self.tag_ids[name] = self.next_tag_id
            self.next_tag_id += 1
        return self.tag_ids[name]

    def _add_tag(self, photo_id, name):
        ptid = self.next_photo_tag_id
        self.next_photo_tag_id += 1
        self.photo_tags[ptid] = {"photoId": photo_id, "tagName": name}
        return {"photoTagId": ptid, "tagId": self._tag_id(name),
                "tagName": name, "photoId": photo_id}

    def tags_of(self, photo_id):
        return [
            {"photoTagId": ptid, "tagId": self._tag_id(t["tagName"]),
             "tagName": t["tagName"], "photoId": photo_id}
            for ptid, t in sorted(self.photo_tags.items())
            if t["photoId"] == photo_id
        ]


STORE = Store()


def normalize_created_at(value):
    # 업로드 메타데이터는 'yyyy-MM-ddTHH:mm:ss'(UTC, 표기 없음)로 오지만
    # 앱의 사진 목록 파싱은 ISO8601(타임존 필수)이므로 Z를 붙여 저장한다
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}", value):
        return value + "Z"
    return value


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    # --- helpers -------------------------------------------------------

    def send_json(self, obj, status=200):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_bytes(self, data, content_type):
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def read_body(self):
        """요청 본문을 한 번만 읽어 캐시한다.

        route()가 STORE.lock을 잡기 전에 미리 호출한다 — 락을 쥔 채 소켓을 읽으면
        Content-Length만 보내고 본문 전송을 멈춘 클라이언트 하나가 나머지 모든
        요청을 락에서 대기시킨다.
        """
        if self._body is None:
            length = int(self.headers.get("Content-Length") or 0)
            self._body = self.rfile.read(length) if length else b""
        return self._body

    def read_json(self):
        body = self.read_body()
        return json.loads(body) if body else {}

    def image_url(self, image_name):
        host = self.headers.get("Host", f"127.0.0.1:{PORT}")
        return f"http://{host}/images/{quote(image_name)}"

    def photo_dto(self, photo):
        return {
            "photoId": photo["photoId"],
            "imageUrl": self.image_url(photo["imageName"]),
            "latitude": photo["latitude"],
            "longitude": photo["longitude"],
            "createdAt": photo["createdAt"],
            "fileName": photo["fileName"],
            "tags": [t["tagName"] for t in STORE.tags_of(photo["photoId"])],
            "isSensitive": photo["isSensitive"],
        }

    def photos_desc(self):
        return sorted(STORE.photos.values(), key=lambda p: p["createdAt"], reverse=True)

    def parse_multipart_file(self):
        content_type = self.headers.get("Content-Type", "")
        match = re.search(r"boundary=(.+)", content_type)
        if not match:
            return None
        boundary = match.group(1).strip().strip('"').encode()
        for part in self.read_body().split(b"--" + boundary):
            header_blob, sep, content = part.partition(b"\r\n\r\n")
            if not sep or b'name="file"' not in header_blob:
                continue
            if content.endswith(b"\r\n"):
                content = content[:-2]
            return content
        return None

    def log_message(self, fmt, *args):
        print(f"  {self.command} {self.path} -> {args[1] if len(args) > 1 else args}")

    # --- routing -------------------------------------------------------

    def serve_image(self, name):
        """이미지는 락 밖에서 전송한다.

        수 MB 바이트 쓰기를 락 안에서 하면 그리드 썸네일 요청이 한 줄로 직렬화되어
        ThreadingHTTPServer를 쓰는 의미가 없어진다. 관찰 도구가 관찰 대상을 왜곡하는 셈.
        공유 상태는 uploaded_images 조회 한 번뿐이라 그 구간만 락으로 감싼다.
        """
        with STORE.lock:
            data = STORE.uploaded_images.get(name)

        if data is None:
            file_path = (MOCK_IMAGES_DIR / name).resolve()
            if file_path.is_relative_to(MOCK_IMAGES_DIR) and file_path.is_file():
                data = file_path.read_bytes()
        if data is None:
            return self.send_json({"error": "image not found"}, 404)
        self.send_bytes(data, "image/jpeg")

    def route(self):
        method, path = self.command, urlsplit(self.path).path

        # 본문 읽기와 이미지 전송은 락 밖에서 끝낸다 (read_body·serve_image 주석 참고).
        # 두 경로 모두 원래 인증 면제였으므로 순서를 앞당겨도 동작은 같다
        if method in ("POST", "PUT"):
            self.read_body()

        image_match = re.fullmatch(r"/images/(.+)", path)
        if method == "GET" and image_match:
            return self.serve_image(unquote(image_match.group(1)))

        with STORE.lock:
            # 인증: 기본은 아무 토큰이나 통과. /debug/expire* 호출 후에만 검사 시작
            public = (path in ("/login", "/join", "/auth/refresh")
                      or path.startswith("/images/") or path.startswith("/debug/"))
            if not public and STORE.required_access is not None:
                if self.headers.get("Authorization") != f"Bearer {STORE.required_access}":
                    return self.send_json({"error": "access token expired"}, 401)

            if method == "POST" and path == "/login":
                self.read_body()
                STORE.required_access = None
                STORE.refresh_enabled = True
                return self.send_json({"accessToken": "mock-access-token",
                                       "refreshToken": "mock-refresh-token"})
            if method == "POST" and path == "/auth/refresh":
                # 리프레시 토큰을 검사한다 — 안 보내도 통과하면 클라이언트가 토큰을
                # 빼먹는 버그를 이 서버로는 잡을 수 없다.
                # TokenRefreshServiceImpl의 본문 형식: {"Authorization": refreshToken}
                try:
                    sent = self.read_json().get("Authorization")
                except json.JSONDecodeError:
                    sent = None
                if sent != "mock-refresh-token":
                    return self.send_json({"error": "invalid refresh token"}, 401)
                if not STORE.refresh_enabled:
                    return self.send_json({"error": "refresh token expired"}, 401)
                token = STORE.required_access or "mock-access-token"
                return self.send_json({"accessToken": token,
                                       "refreshToken": "mock-refresh-token"})

            if method == "POST" and path == "/debug/expire":
                STORE.auth_generation += 1
                STORE.required_access = f"mock-access-{STORE.auth_generation}"
                STORE.refresh_enabled = True
                return self.send_json(
                    {"message": "액세스 토큰 만료 — 다음 요청 401, 앱이 리프레시 후 재시도해야 함"})
            if method == "POST" and path == "/debug/expire-all":
                STORE.auth_generation += 1
                STORE.required_access = f"mock-access-{STORE.auth_generation}"
                STORE.refresh_enabled = False
                return self.send_json(
                    {"message": "세션 만료 — 리프레시도 401, forceLogout 유도. 재로그인 시 해제"})
            if method == "POST" and path == "/logout":
                self.read_body()
                return self.send_json({})
            if method == "GET" and path == "/users":
                return self.send_json({"userId": 1, "loginId": 1, "name": "테스트유저"})

            if method == "GET" and path == "/photos":
                return self.send_json([self.photo_dto(p) for p in self.photos_desc()])

            m = re.fullmatch(r"/photos/(\d+)", path)
            if method == "DELETE" and m:
                pid = int(m.group(1))
                STORE.photos.pop(pid, None)
                for ptid in [k for k, t in STORE.photo_tags.items() if t["photoId"] == pid]:
                    del STORE.photo_tags[ptid]
                return self.send_json({})

            if method == "POST" and path == "/photos/s3":
                data = self.parse_multipart_file()
                if data is None:
                    return self.send_json({"error": "multipart 'file' part not found"}, 400)
                name = f"upload_{STORE.next_upload}.jpg"
                STORE.next_upload += 1
                STORE.uploaded_images[name] = data
                return self.send_json({"imageUrl": self.image_url(name)})

            if method == "POST" and path == "/photos/batch":
                for item in self.read_json().get("photos", []):
                    pid = STORE.next_photo_id
                    STORE.next_photo_id += 1
                    image_name = unquote(urlsplit(item["imageUrl"]).path.rsplit("/", 1)[-1])
                    STORE.photos[pid] = {
                        "photoId": pid, "imageName": image_name,
                        "fileName": item["fileName"],
                        "latitude": item["latitude"], "longitude": item["longitude"],
                        "createdAt": normalize_created_at(item["createdAt"]),
                        "description": UPLOAD_DESCRIPTION, "isSensitive": False,
                    }
                return self.send_json({})

            m = re.fullmatch(r"/photos/(\d+)/tags", path)
            if method == "GET" and m:
                return self.send_json(STORE.tags_of(int(m.group(1))))

            m = re.fullmatch(r"/photos/(\d+)/description", path)
            if method == "GET" and m:
                photo = STORE.photos.get(int(m.group(1)))
                return self.send_json({"description": photo["description"] if photo else ""})

            if method == "POST" and path == "/tags":
                body = self.read_json()
                return self.send_json(STORE._add_tag(body["photoId"], body["tagName"]))

            m = re.fullmatch(r"/tags/(\d+)", path)
            if method == "PUT" and m:
                ptid = int(m.group(1))
                tag = STORE.photo_tags.get(ptid)
                if tag is None:
                    return self.send_json({"error": "tag not found"}, 404)
                tag["tagName"] = self.read_json()["tagName"]
                return self.send_json({"photoTagId": ptid, "tagId": STORE._tag_id(tag["tagName"]),
                                       "tagName": tag["tagName"], "photoId": tag["photoId"]})
            if method == "DELETE" and m:
                STORE.photo_tags.pop(int(m.group(1)), None)
                return self.send_json({})

            if method == "POST" and path == "/search":
                query = self.read_json().get("query", "").strip().casefold()
                results = []
                if query:
                    for p in self.photos_desc():
                        if p["isSensitive"]:
                            continue
                        haystack = " ".join(
                            [t["tagName"] for t in STORE.tags_of(p["photoId"])]
                            + [p["description"]]
                        ).casefold()
                        if query in haystack:
                            results.append({"imageUrl": self.image_url(p["imageName"]),
                                            "photoId": p["photoId"]})
                return self.send_json({"query": query, "searchResults": results})

            if method == "GET" and path == "/albums":
                # 민감 사진은 검색과 마찬가지로 앨범에서도 제외 (해당 사진에만 있는 태그는 앨범 자체가 안 뜸)
                # 계약 개선판: 앨범 카드용 커버·장수를 포함해 N+1을 없애고, 쓸모없던 userId는 제거
                visible = {pid for pid, p in STORE.photos.items() if not p["isSensitive"]}
                by_tag = {}
                for t in STORE.photo_tags.values():
                    if t["photoId"] in visible:
                        by_tag.setdefault(t["tagName"], set()).add(t["photoId"])
                albums = []
                for name, tid in sorted(STORE.tag_ids.items(), key=lambda kv: kv[1]):
                    pids = by_tag.get(name)
                    if not pids:
                        continue
                    newest = max((STORE.photos[pid] for pid in pids),
                                 key=lambda p: p["createdAt"])
                    albums.append({"tagId": tid, "tagName": name,
                                   "coverImageUrl": self.image_url(newest["imageName"]),
                                   "photoCount": len(pids)})
                return self.send_json(albums)

            m = re.fullmatch(r"/albums/(\d+)/photos", path)
            if method == "GET" and m:
                tag_id = int(m.group(1))
                names = {n for n, tid in STORE.tag_ids.items() if tid == tag_id}
                pids = {t["photoId"] for t in STORE.photo_tags.values() if t["tagName"] in names}
                return self.send_json([self.photo_dto(p) for p in self.photos_desc()
                                       if p["photoId"] in pids and not p["isSensitive"]])

        self.send_json({"error": f"no route: {method} {path}"}, 404)

    def dispatch(self):
        self._body = None
        if DELAY_MS:
            time.sleep(DELAY_MS / 1000)  # 로딩 인디케이터·디바운스 관찰용 (lock 밖에서 대기)
        try:
            self.route()
        except Exception as e:  # noqa: BLE001
            print(f"  !! {self.command} {self.path}: {e}")
            try:
                self.send_json({"error": str(e)}, 500)
            except Exception:
                pass

    do_GET = do_POST = do_PUT = do_DELETE = dispatch


if __name__ == "__main__":
    sys.stdout.reconfigure(line_buffering=True)  # 파일로 리다이렉트해도 요청 로그가 즉시 보이게
    if not MOCK_IMAGES_DIR.is_dir():
        sys.exit(f"MockImages 디렉토리를 찾을 수 없음: {MOCK_IMAGES_DIR}")
    print(f"Rephoto 목 서버 시작 — http://{HOST}:{PORT}")
    print(f"이미지 디렉토리: {MOCK_IMAGES_DIR}")
    if DELAY_MS:
        print(f"응답 지연: {DELAY_MS}ms")
    print("디버그: POST /debug/expire (401→리프레시), POST /debug/expire-all (forceLogout)")
    print("종료: Ctrl+C")
    try:
        ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
    except KeyboardInterrupt:
        print("\n종료됨")
