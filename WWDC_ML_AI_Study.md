# Apple Intelligence & Machine Learning 공부노트

> WWDC 세션: Making use of Apple Intelligence and machine learning
> 발표자: Jaimin Upadhyay, Engineering Manager, On-Device Machine Learning team

## 목차

1. [Platform Intelligence](#1-platform-intelligence)
2. [ML-Powered APIs](#2-ml-powered-apis)
3. [Domain-Specific Frameworks](#3-domain-specific-frameworks)
4. [Core ML - 모델 배포](#4-core-ml---모델-배포)
5. [MLX - 연구 및 실험](#5-mlx---연구-및-실험)

---

## 1. Platform Intelligence

### 개요
- ML과 AI가 iOS/macOS의 핵심 기능에 내장
- 예시: Optic ID, 손글씨 인식, FaceTime 배경 소음 제거
- 모든 모델이 **온디바이스에서 최적화**되어 실행

### Apple Intelligence
- 대규모 foundation 모델 기반
- 시스템 전체에서 사용 가능한 기능:
  - **Writing Tools**: 텍스트 작성 도우미
  - **Genmoji**: 커스텀 이모지 생성
  - **Image Playground**: 이미지 생성

### 앱 통합
```swift
// Genmoji - 시스템 텍스트 컨트롤 사용 시 자동 지원
// Image Playground - SwiftUI extension
.imagePlaygroundSheet(isPresented: $showImagePlayground)

// Writing Tools - 표준 UITextView 사용 시 자동 지원
```

**장점**: 최소한의 코드로 일관된 UI 제공

---

## 2. ML-Powered APIs

### 2.1 ImageCreator (iOS 18.4+)

프로그래밍 방식으로 이미지 생성

```swift
import ImagePlayground

// 1. ImageCreator 인스턴스 생성
let imageCreator = ImageCreator()

// 2. 프롬프트로 이미지 요청
let images = try await imageCreator.create(
    prompt: "A cat wearing a hat",
    style: .illustration
)

// 3. 앱에서 자유롭게 사용
imageView.image = images.first
```

### 2.2 Smart Reply (iOS 18.4+)

메시지/이메일 자동 답장 생성

```swift
// 대화 컨텍스트 설정
let context = UIMessageConversationContext(messages: messages)
textView.setInputSuggestionContext(context)

// 이메일의 경우 delegate로 처리
func insertInputSuggestion(_ suggestion: String) {
    // 긴 이메일 답장 생성 및 삽입
}
```

**특징**:
- 완전히 온디바이스 실행
- Apple foundation 모델 사용
- 개인정보 보호

### 2.3 Foundation Models Framework (iOS 26+) ⭐

**가장 중요한 신규 프레임워크**

온디바이스 언어 모델에 프로그래밍 방식으로 접근

#### 기본 사용법

```swift
import FoundationModels

// 1. 세션 생성
let session = await FoundationModelSession()

// 2. 프롬프트 전송
let response = try await session.prompt("Summarize this article: ...")

print(response.text)
```

#### 주요 특징
- ✅ 온디바이스 실행 (개인정보 보호)
- ✅ 오프라인 작동
- ✅ 무료 (API 키 불필요)
- ✅ 빠른 응답 속도

#### 활용 사례
- 요약 (Summarization)
- 정보 추출 (Extraction)
- 분류 (Classification)
- 개인화된 검색 제안
- 여행 일정 생성
- 게임 캐릭터 대화 생성

#### Guided Generation - 구조화된 응답

커스텀 타입을 직접 생성

```swift
@Generable
struct TravelItinerary {
    @Guide("The destination city")
    var destination: String

    @Guide("List of activities")
    var activities: [String]

    @Guide("Estimated budget in USD")
    @Range(100...5000)
    var budget: Int
}

// 사용
let itinerary: TravelItinerary = try await session.generate(
    prompt: "Create a 3-day itinerary for Tokyo"
)

print(itinerary.destination) // "Tokyo"
print(itinerary.activities) // ["Visit Senso-ji Temple", ...]
print(itinerary.budget) // 1500
```

**장점**:
- JSON 스키마 불필요
- 타입 안전성 보장
- 구조적 오류 자동 방지

#### Tool Calling

모델이 실시간 데이터에 접근하거나 작업 수행

```swift
// 날씨 정보 제공 도구
@Tool
func getCurrentWeather(location: String) -> String {
    // 실제 날씨 API 호출
    return "Sunny, 25°C"
}

let response = try await session.prompt(
    "What's the weather in Seoul?",
    tools: [getCurrentWeather]
)
```

**활용**:
- 실시간/개인 데이터 접근 (날씨, 캘린더)
- 사실 확인을 위한 출처 인용
- 앱/시스템에서 실제 작업 수행

#### 기타 기능
- Streaming responses (실시간 응답)
- Stateful sessions (대화 컨텍스트 유지)
- Xcode 통합

#### 제약사항
- 모델의 지식은 학습 시점까지로 제한
- 최신 이벤트는 포함되지 않음
- 서버 규모 모델보다 지식량 적음
- → Tool Calling으로 보완 가능

#### 관련 세션
- "Meet the Foundation Models framework"
- "Explore prompt design and safety for on-device Foundation models"

---

## 3. Domain-Specific Frameworks

특정 작업에 최적화된 태스크별 모델

### 3.1 Vision

이미지/비디오 콘텐츠 이해 (30+ APIs)

#### 신규 기능 (iOS 26)

**1. Document Recognition**

```swift
import Vision

let request = VNRecognizeDocumentRequest { request, error in
    guard let results = request.results as? [VNDocumentObservation] else { return }

    // 문서 구조 그룹화 (제목, 본문, 표 등)
    for document in results {
        print(document.structure)
    }
}

let handler = VNImageRequestHandler(cgImage: image)
try handler.perform([request])
```

**2. Lens Smudge Detection**

카메라 렌즈의 얼룩 감지

```swift
let request = VNDetectLensSmudgeRequest()
// 이미지 품질 저하 가능성 사전 감지
```

### 3.2 Speech

음성을 텍스트로 변환

#### SpeechAnalyzer (iOS 26+) ⭐

기존 SFSpeechRecognizer의 진화형

```swift
import Speech

let analyzer = SpeechAnalyzer()

// 오디오 버퍼 전달
analyzer.process(audioBuffer) { result in
    print(result.transcription)
}
```

**특징**:
- 더 빠르고 유연한 모델
- 장시간 오디오 지원 (강의, 회의, 대화)
- 원거리 오디오 인식 향상
- 완전히 온디바이스 실행

**관련 세션**: "Bring advanced speech-to-text to your app with SpeechAnalyzer"

### 3.3 기타 프레임워크

| 프레임워크 | 기능 |
|-----------|------|
| **Natural Language** | 언어 식별, 품사 태깅, 개체명 인식 |
| **Translation** | 다국어 텍스트 번역 |
| **Sound Analysis** | 다양한 소리 카테고리 인식 |

### Create ML

시스템 모델을 커스텀 데이터로 파인튜닝

- 이미지 분류기 (Vision)
- 커스텀 단어 태거 (Natural Language)
- Vision Pro 객체 인식/트래킹 (6DoF)

---

## 4. Core ML - 모델 배포

### 모델 소스

**1. Apple 공식**
- developer.apple.com: 카테고리별 정리된 Core ML 모델
- 성능 정보, 다양한 변형 제공

**2. Hugging Face**
- Apple Space: Core ML 포맷 + PyTorch 소스
- 학습/파인튜닝 파이프라인 포함

### Core ML Tools

PyTorch 모델을 Core ML 포맷으로 변환 + 최적화

```python
import coremltools as ct

# PyTorch 모델 변환
model = ct.convert(
    pytorch_model,
    inputs=[ct.TensorType(shape=(1, 3, 224, 224))]
)

# 최적화 (옵션)
model_compressed = ct.compression.quantize_weights(
    model,
    nbits=8
)

model_compressed.save("optimized_model.mlpackage")
```

**자동 최적화**:
- 연산 융합
- 중복 계산 제거

**수동 최적화**:
- 양자화 (Quantization)
- 프루닝 (Pruning)
- 압축 기법

### Xcode 통합

1. **모델 검사**: 입출력, 아키텍처 확인
2. **성능 프리뷰**: 레이턴시, 로드 시간, 실행 위치
3. **모델 시각화** (신규): 전체 아키텍처 구조 확인
4. **Swift 인터페이스 자동 생성**

```swift
// Xcode가 자동 생성한 타입 안전 인터페이스
let model = try MyModel(configuration: .init())
let prediction = try model.prediction(input: inputData)
```

### 런타임 최적화

Core ML이 자동으로 최적 컴퓨트 선택:
- CPU
- GPU
- Neural Engine

### 세밀한 제어가 필요한 경우

| 프레임워크 | 용도 |
|-----------|------|
| **MPS Graph** | ML + 그래픽 워크로드 통합 |
| **BNNS Graph** | CPU 실시간 신호 처리, 엄격한 레이턴시 제어 |
| **Metal** | 직접적인 GPU 제어 |

#### BNNS Graph (신규)

```swift
// Graph Builder로 연산 그래프 생성
let graph = BNNSGraph()
graph.addOperation(/* pre-processing */)
graph.addOperation(/* ML inference */)
graph.addOperation(/* post-processing */)
```

**관련 세션**: "What's new in BNNS Graph"

---

## 5. MLX - 연구 및 실험

### 개요

Apple의 ML 연구진이 개발한 오픈소스 프레임워크

**특징**:
- 수치 계산 및 머신러닝용 배열 프레임워크
- Apple Silicon 최적화
- 최신 모델 실험 가능

### 빠른 시작

```bash
# LLM 추론 (한 줄로!)
mlx_lm generate --model mistral --prompt "Write quicksort in Python" --max-tokens 1024
```

### Hugging Face 통합

MLX 커뮤니티에 수백 개의 최신 모델 제공

```python
from mlx_lm import load, generate

model, tokenizer = load("mlx-community/DeepSeek-R1")
response = generate(model, tokenizer, prompt="...")
```

**관련 세션**: "Explore large language models on Apple silicon with MLX"

### Unified Memory 아키텍처

일반 시스템과의 차이:

**일반 시스템**:
- GPU가 분리된 메모리 사용
- 데이터가 특정 디바이스에 고정
- 메모리 간 복사 필요 (비효율)

**Apple Silicon**:
- CPU와 GPU가 동일한 물리 메모리 공유
- 배열은 디바이스에 고정 안 됨
- CPU/GPU에서 동시에 같은 버퍼 작업 가능

```python
import mlx.core as mx

# 같은 배열에 대해 CPU/GPU 병렬 실행
array = mx.random.normal((1000, 1000))

# CPU 연산
result_cpu = mx.add(array, 1, device=mx.cpu)

# GPU 연산 (동시에!)
result_gpu = mx.matmul(array, array.T, device=mx.gpu)
```

### 파인튜닝

```bash
# 한 줄로 파인튜닝
mlx_lm.lora --model mistral --data my_dataset.jsonl
```

- 분산 학습 지원
- Python, Swift, C++, C 바인딩

### 기타 프레임워크

- **PyTorch**: Metal 백엔드로 Apple Silicon 활용
- **JAX**: Metal 지원

**관련 세션**: "Get started with MLX for Apple silicon"

---

## 요약

### 사용 시나리오별 선택 가이드

| 목적 | 추천 도구 |
|------|----------|
| 시스템 AI 기능 빠른 통합 | Writing Tools, Genmoji, Image Playground |
| 텍스트 생성/요약/분류 | Foundation Models framework |
| 이미지/음성/언어 분석 | Vision, Speech, Natural Language |
| 커스텀 모델 배포 | Core ML |
| 최신 모델 연구/실험 | MLX |
| 세밀한 성능 제어 | BNNS Graph, MPS Graph, Metal |

### 핵심 장점

1. **온디바이스 실행**: 개인정보 보호, 오프라인 작동
2. **무료**: API 키 불필요, 비용 없음
3. **Apple Silicon 최적화**: CPU, GPU, Neural Engine 자동 활용
4. **간편한 통합**: 몇 줄의 코드로 강력한 AI 기능

### 다음 단계

- [developer.apple.com](https://developer.apple.com) ML/AI 리소스
- Developer 앱 "Machine Learning and AI" 카테고리
- Developer Forums 커뮤니티

---

## 참고 자료

### 필수 세션
- "Meet the Foundation Models framework"
- "Explore prompt design and safety for on-device Foundation models"
- "Bring advanced speech-to-text to your app with SpeechAnalyzer"
- "Reading documents using the Vision Framework"
- "Explore large language models on Apple silicon with MLX"
- "Get started with MLX for Apple silicon"

### 문서
- "Adopting Smart Reply in your messaging or email app"
- Core ML Tools User Guide
- MLX Documentation
