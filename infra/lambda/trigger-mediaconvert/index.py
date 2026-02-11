import json
import os
import boto3

def handler(event, context):
    region = os.environ["AWS_REGION"]
    mediaconvert_role = os.environ["MEDIACONVERT_ROLE_ARN"]
    destination_bucket = os.environ["DESTINATION_BUCKET"]

    # S3 이벤트에서 소스 정보 추출
    record = event["Records"][0]
    source_bucket = record["s3"]["bucket"]["name"]
    source_key = record["s3"]["object"]["key"]

    # uploads/{videoId}/original.mp4 에서 videoId 추출
    parts = source_key.split("/")
    video_id = parts[1]

    # MediaConvert 엔드포인트 조회
    mc_client = boto3.client("mediaconvert", region_name=region)
    endpoints = mc_client.describe_endpoints()
    endpoint_url = endpoints["Endpoints"][0]["Url"]

    mc = boto3.client("mediaconvert", region_name=region, endpoint_url=endpoint_url)

    input_uri = f"s3://{source_bucket}/{source_key}"
    output_uri = f"s3://{destination_bucket}/hls/{video_id}/"

    job_settings = {
        "Inputs": [
            {
                "FileInput": input_uri,
                "AudioSelectors": {
                    "Audio Selector 1": {"DefaultSelection": "DEFAULT"}
                },
            }
        ],
        "OutputGroups": [
            {
                "Name": "HLS",
                "OutputGroupSettings": {
                    "Type": "HLS_GROUP_SETTINGS",
                    "HlsGroupSettings": {
                        "Destination": output_uri,
                        "SegmentLength": 6,
                        "MinSegmentLength": 0,
                    },
                },
                "Outputs": [
                    _build_output("_1080p", 1920, 1080, 5000000, "HIGH", 128000),
                    _build_output("_720p", 1280, 720, 3000000, "HIGH", 128000),
                    _build_output("_480p", 854, 480, 1500000, "MAIN", 128000),
                ],
            }
        ],
    }

    response = mc.create_job(
        Role=mediaconvert_role,
        Settings=job_settings,
        UserMetadata={"videoId": video_id},
    )

    print(f"MediaConvert Job created: {response['Job']['Id']} for video {video_id}")
    return {"statusCode": 200, "body": json.dumps({"jobId": response["Job"]["Id"]})}


def _build_output(name_modifier, width, height, bitrate, profile, audio_bitrate):
    return {
        "NameModifier": name_modifier,
        "ContainerSettings": {"Container": "M3U8"},
        "VideoDescription": {
            "Width": width,
            "Height": height,
            "CodecSettings": {
                "Codec": "H_264",
                "H264Settings": {
                    "RateControlMode": "CBR",
                    "Bitrate": bitrate,
                    "CodecProfile": profile,
                    "GopSize": 2.0,
                    "GopSizeUnits": "SECONDS",
                },
            },
        },
        "AudioDescriptions": [
            {
                "AudioSourceName": "Audio Selector 1",
                "CodecSettings": {
                    "Codec": "AAC",
                    "AacSettings": {
                        "Bitrate": audio_bitrate,
                        "CodingMode": "CODING_MODE_2_0",
                        "SampleRate": 48000,
                    },
                },
            }
        ],
    }
