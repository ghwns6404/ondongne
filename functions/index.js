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
- "존나 좋아", "개좋아" 등 긍정적 강조 표현 (맥락 고려)

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
exports.checkProfanity = functions.https.onCall(async (data, context) => {
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
exports.checkNewsOnCreate = functions.firestore
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
exports.checkCommentOnCreate = functions.firestore
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

