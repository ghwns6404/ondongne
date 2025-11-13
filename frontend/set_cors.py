#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Firebase Storage CORS 설정 스크립트
Google Cloud Storage API를 사용하여 CORS 설정을 적용합니다.
"""

import json
import subprocess
import sys
import os
import io

# Windows 콘솔 인코딩 설정
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# CORS 설정
cors_config = [
    {
        "origin": ["*"],
        "method": ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"],
        "maxAgeSeconds": 3600,
        "responseHeader": [
            "Content-Type",
            "Authorization",
            "Content-Length",
            "User-Agent",
            "x-goog-resumable",
            "x-goog-upload-command",
            "x-goog-upload-header-content-length",
            "x-goog-upload-header-content-type"
        ]
    }
]

bucket_name = "ondongne-e494a.firebasestorage.app"

def main():
    print("Firebase Storage CORS 설정을 시작합니다...")
    print(f"버킷: {bucket_name}")
    
    # cors.json 파일 읽기
    cors_file = "cors.json"
    if os.path.exists(cors_file):
        with open(cors_file, 'r', encoding='utf-8') as f:
            cors_config = json.load(f)
        print(f"[OK] {cors_file} 파일을 읽었습니다.")
    else:
        print(f"[WARN] {cors_file} 파일이 없습니다. 기본 설정을 사용합니다.")
    
    # gcloud CLI 사용 시도
    print("\n방법 1: gcloud CLI 사용 시도...")
    try:
        # gcloud 인증 확인
        result = subprocess.run(
            ["gcloud", "auth", "list"],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0:
            print("[OK] gcloud CLI가 설치되어 있습니다.")
            
            # gsutil로 CORS 설정
            cors_json = json.dumps(cors_config)
            result = subprocess.run(
                ["gsutil", "cors", "set", cors_file, f"gs://{bucket_name}"],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                print("[SUCCESS] CORS 설정이 완료되었습니다!")
                return 0
            else:
                print(f"[ERROR] gsutil 실행 실패: {result.stderr}")
        else:
            print("[ERROR] gcloud CLI가 설치되어 있지 않거나 인증이 필요합니다.")
    except FileNotFoundError:
        print("[ERROR] gcloud CLI가 설치되어 있지 않습니다.")
    except Exception as e:
        print(f"[ERROR] 오류 발생: {e}")
    
    # 방법 2: 수동 안내
    print("\n" + "="*60)
    print("자동 설정이 실패했습니다. 다음 방법을 사용하세요:")
    print("="*60)
    print("\n방법 1: Google Cloud SDK 설치")
    print("1. https://cloud.google.com/sdk/docs/install/windows 접속")
    print("2. 설치 프로그램 다운로드 및 실행")
    print("3. 설치 후 PowerShell에서 다음 명령어 실행:")
    print(f"   gcloud auth login")
    print(f"   gcloud config set project ondongne-e494a")
    print(f"   gsutil cors set cors.json gs://{bucket_name}")
    
    print("\n방법 2: Google Cloud Console에서 직접 설정")
    print("1. https://console.cloud.google.com/storage/browser 접속")
    print(f"2. 버킷 '{bucket_name}' 클릭")
    print("3. 구성 탭 → 아래로 스크롤 → CORS 섹션 찾기")
    print("4. CORS 구성 수정 클릭")
    print("5. cors.json 파일 내용 붙여넣기")
    
    print("\n현재 cors.json 내용:")
    print(json.dumps(cors_config, indent=2, ensure_ascii=False))
    
    return 1

if __name__ == "__main__":
    sys.exit(main())

