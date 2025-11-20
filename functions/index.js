const functions = require('firebase-functions');
const admin = require('firebase-admin');
const OpenAI = require('openai');

admin.initializeApp();

// 챗봇 기능 import
const chatbotFunctions = require('./chatbot_functions');

// OpenAI API 초기화
const openai = new OpenAI({
  apiKey: functions.config().openai.key, // Firebase Functions 환경변수
});

/**
 * 텍스트에 욕설/비속어가 포함되어 있는지 GPT API로 검사합니다.
 * @param {string} text - 검사할 텍스트
 * @returns {Promise<{isClean: boolean, reason?: string}>}
 */
async function checkProfanity(text) {
  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: `당신은 한국어 텍스트의 욕설, 비속어, 혐오 표현을 감지하는 전문가입니다.
다음 기준으로 판단하세요:
1. 욕설, 비속어, 성적인 표현
2. 혐오 발언 (인종, 성별, 종교 등)
3. 폭력적이거나 위협적인 표현
4. 심각한 비방이나 모욕

단, 다음은 허용합니다:
- "개발자", "개발", "개선" 등 일상 단어
- "겁나좋음", "개좋아" 등 긍정적 강조 표현 (맥락 고려)

응답은 반드시 JSON 형식으로만 하세요:
{"isClean": true} 또는 {"isClean": false, "reason": "문제가 되는 이유"}`,
        },
        {
          role: 'user',
          content: `다음 텍스트를 검사해주세요: "${text}"`,
        },
      ],
      temperature: 0.3,
      max_tokens: 150,
    });

    const result = response.choices[0].message.content;
    console.log('GPT 응답:', result);

    // JSON 파싱
    const parsed = JSON.parse(result);
    return parsed;
  } catch (error) {
    console.error('GPT API 호출 오류:', error);
    // API 오류 시 통과 처리 (서비스 중단 방지)
    return { isClean: true };
  }
}

/**
 * 텍스트 욕설 필터링 HTTP Function
 */
exports.checkProfanity = functions.region('asia-northeast3').https.onCall(async (data, context) => {
  // 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      '로그인이 필요합니다.'
    );
  }

  const { text } = data;

  // 입력 검증
  if (!text || typeof text !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '텍스트를 입력해주세요.'
    );
  }

  // 텍스트 길이 검증
  if (text.trim().length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '빈 텍스트는 검사할 수 없습니다.'
    );
  }

  if (text.length > 5000) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '텍스트가 너무 깁니다. (최대 5000자)'
    );
  }

  // 욕설 검사
  const result = await checkProfanity(text);

  return result;
});

/**
 * 게시물 작성 시 자동 욕설 검사 Trigger
 */
exports.checkNewsOnCreate = functions.region('asia-northeast3').firestore
  .document('news/{newsId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { title, content } = data;

    // 제목과 내용 검사
    const titleCheck = await checkProfanity(title);
    const contentCheck = await checkProfanity(content);

    if (!titleCheck.isClean || !contentCheck.isClean) {
      // 욕설 감지 시 문서 삭제
      await snap.ref.delete();
      console.log(`게시물 삭제됨 (욕설 감지): ${context.params.newsId}`);
      
      // 사용자에게 알림 (선택사항)
      // 실제로는 클라이언트에서 검사 후 업로드하므로 이 케이스는 드뭅니다
    }
  });

/**
 * 댓글 작성 시 자동 욕설 검사 Trigger
 */
exports.checkCommentOnCreate = functions.region('asia-northeast3').firestore
  .document('comments/{commentId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { content } = data;

    // 댓글 내용 검사
    const result = await checkProfanity(content);

    if (!result.isClean) {
      // 욕설 감지 시 문서 삭제
      await snap.ref.delete();
      console.log(`댓글 삭제됨 (욕설 감지): ${context.params.commentId}`);
    }
  });

/**
 * 챗봇 검색 기능
 */
exports.chatbotSearch = chatbotFunctions.chatbotSearch;

/**
 * AI 상품 분석 - 이미지로부터 제목, 설명, 카테고리, 가격 추천
 */
exports.analyzeProductImage = functions.region('asia-northeast3').https.onCall(async (data, context) => {
  // 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      '로그인이 필요합니다.'
    );
  }

  const { imageBase64 } = data;

  // 입력 검증
  if (!imageBase64 || typeof imageBase64 !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '이미지 데이터가 필요합니다.'
    );
  }

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o', // GPT-4 Vision
      messages: [
        {
          role: 'system',
          content: `당신은 중고거래 플랫폼의 상품 등록을 돕는 AI 어시스턴트입니다.
사용자가 업로드한 상품 사진을 분석하여 다음을 제공하세요:
1. 상품명 (간결하고 명확하게, 20자 이내)
2. 상세 설명 (상품 상태, 특징, 크기/용량 등, 100자 이내)
3. 카테고리 (반드시 다음 중 하나: 디지털/가전, 가구/인테리어, 유아동/유아용품, 생활/가공식품, 스포츠/레저, 여성잡화, 남성패션/잡화, 게임/취미, 뷰티/미용, 반려동물용품, 도서/티켓/음반, 식물, 기타 중고물품)
4. 추천 가격 (원 단위, 최소값-최대값 범위)

중요: 응답은 반드시 JSON 형식으로만 작성하세요. 다른 텍스트나 마크다운 없이 순수 JSON만 출력하세요.

JSON 형식:
{
  "title": "상품명",
  "description": "상세 설명",
  "category": "카테고리명",
  "priceMin": 최소가격숫자,
  "priceMax": 최대가격숫자,
  "priceReason": "가격 추천 근거"
}

※ 주의사항:
- 무기, 위험물, 불법 물품은 등록할 수 없습니다. 이런 경우:
{
  "title": "등록 불가",
  "description": "이 상품은 중고거래 플랫폼에 등록할 수 없는 품목입니다.",
  "category": "기타 중고물품",
  "priceMin": 0,
  "priceMax": 0,
  "priceReason": "등록 불가 품목"
}

- 사진에서 상품을 식별할 수 없으면:
{
  "title": "",
  "description": "",
  "category": "기타 중고물품",
  "priceMin": 0,
  "priceMax": 0,
  "priceReason": "사진에서 상품을 명확히 식별할 수 없습니다."
}`,
        },
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: '이 상품 사진을 분석해서 등록 정보를 JSON 형식으로만 작성해주세요. 다른 설명 없이 JSON만 출력하세요.',
            },
            {
              type: 'image_url',
              image_url: {
                url: `data:image/jpeg;base64,${imageBase64}`,
                detail: 'high',
              },
            },
          ],
        },
      ],
      temperature: 0.3,
      max_tokens: 600,
      response_format: { type: "json_object" }, // JSON 모드 강제
    });

    let result = response.choices[0].message.content;
    console.log('GPT-4 Vision 원본 응답:', result);

    // 마크다운 코드 블록 제거 (```json ... ``` 형식)
    result = result.replace(/```json\s*/g, '').replace(/```\s*/g, '').trim();
    console.log('정제된 응답:', result);

    // JSON 파싱
    let parsed;
    try {
      parsed = JSON.parse(result);
    } catch (parseError) {
      console.error('JSON 파싱 실패:', parseError);
      console.error('파싱 시도한 문자열:', result);
      throw new Error('AI가 올바른 JSON 형식으로 응답하지 않았습니다.');
    }
    
    // 응답 검증
    if (!parsed.title || !parsed.description || !parsed.category) {
      console.error('응답 검증 실패:', parsed);
      throw new Error('AI 응답에 필수 필드가 없습니다.');
    }

    // 등록 불가 품목 체크
    if (parsed.title === '등록 불가') {
      throw new Error('이 상품은 중고거래 플랫폼에 등록할 수 없는 품목입니다.');
    }

    return {
      success: true,
      data: parsed,
    };
  } catch (error) {
    console.error('GPT-4 Vision API 호출 오류:', error);
    console.error('에러 상세:', error.message);
    throw new functions.https.HttpsError(
      'internal',
      `AI 분석 중 오류가 발생했습니다: ${error.message}`
    );
  }
});

