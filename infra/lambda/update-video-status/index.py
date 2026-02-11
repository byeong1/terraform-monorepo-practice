import json
import os
import urllib.request

def handler(event, context):
    callback_url = os.environ["CALLBACK_URL"]
    callback_secret = os.environ["CALLBACK_SECRET"]

    detail = event.get("detail", {})
    status = detail.get("status")
    user_metadata = detail.get("userMetadata", {})
    video_id = user_metadata.get("videoId")

    if not video_id:
        print("No videoId in event metadata, skipping")
        return {"statusCode": 200}

    # MediaConvert 상태를 앱 상태로 매핑
    if status == "COMPLETE":
        video_status = "ready"
    elif status == "ERROR":
        video_status = "error"
    else:
        print(f"Ignoring status: {status}")
        return {"statusCode": 200}

    payload = json.dumps({
        "videoId": video_id,
        "status": video_status,
    }).encode("utf-8")

    req = urllib.request.Request(
        callback_url,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "X-Callback-Secret": callback_secret,
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            print(f"Callback response: {resp.status} for video {video_id} -> {video_status}")
    except Exception as e:
        print(f"Callback failed: {e}")
        raise

    return {"statusCode": 200}
