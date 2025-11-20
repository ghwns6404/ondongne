const functions = require('firebase-functions');
const admin = require('firebase-admin');
const OpenAI = require('openai');

// OpenAI API 초기화
const openai = new OpenAI({
  apiKey: functions.config().openai.key,
});

/**
 * 챗봇 검색 기능
 * 사용자 질문을 GPT로 분석하여 키워드 추출 후 Firestore 검색
 */
exports.chatbotSearch = functions.region('asia-northeast3').https.onCall(async (data, context) => {
  // 인증 확인
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      '로그인이 필요합니다.'
    );
  }

  const { query } = data;

  // 입력 검증
  if (!query || typeof query !== 'string' || query.trim().length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      '검색어를 입력해주세요.'
    );
  }

  try {
    // 1단계: GPT로 질문 분석 및 키워드 추출
    const keywords = await extractKeywords(query);
    console.log('추출된 키워드:', keywords);

    // 2단계: Firestore에서 검색
    const results = await searchFirestore(keywords);
    console.log('검색 결과 개수:', results.length);

    // 3단계: GPT로 결과 요약 메시지 생성
    const summaryMessage = await generateSummary(query, results);

    return {
      success: true,
      message: summaryMessage,
      results: results,
      keywords: keywords,
    };
  } catch (error) {
    console.error('챗봇 검색 오류:', error);
    throw new functions.https.HttpsError(
      'internal',
      '검색 중 오류가 발생했습니다. 다시 시도해주세요.'
    );
  }
});

/**
 * GPT로 사용자 질문에서 검색 키워드 추출
 */
async function extractKeywords(query) {
  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: `당신은 검색 키워드 추출 전문가입니다.
사용자의 질문에서 핵심 검색 키워드를 추출하세요.

규칙:
1. 명사 중심으로 추출 (동사, 조사 제거)
2. 유사어도 포함 (예: "장난감" → ["장난감", "완구", "놀이감"])
3. 최대 5개 키워드
4. JSON 배열로만 응답: ["키워드1", "키워드2", ...]

예시:
질문: "자전거 팔아요 글 찾아줘"
응답: ["자전거", "싸이클", "bike", "팔아요", "판매"]`,
        },
        {
          role: 'user',
          content: query,
        },
      ],
      temperature: 0.3,
      max_tokens: 100,
    });

    const content = response.choices[0].message.content;
    const keywords = JSON.parse(content);
    return Array.isArray(keywords) ? keywords : [query];
  } catch (error) {
    console.error('키워드 추출 오류:', error);
    // 오류 시 원본 쿼리를 키워드로 사용
    return [query];
  }
}

/**
 * Firestore에서 키워드로 검색
 */
async function searchFirestore(keywords) {
  const db = admin.firestore();
  const results = [];
  const MAX_RESULTS = 10;

  try {
    // 중고거래(products) 검색
    const productsSnapshot = await db.collection('products').get();
    productsSnapshot.forEach((doc) => {
      const data = doc.data();
      const title = (data.title || '').toLowerCase();
      const description = (data.description || '').toLowerCase();
      
      // 키워드 매칭
      const matchScore = keywords.reduce((score, keyword) => {
        const lowerKeyword = keyword.toLowerCase();
        if (title.includes(lowerKeyword)) score += 3;
        if (description.includes(lowerKeyword)) score += 1;
        return score;
      }, 0);

      if (matchScore > 0) {
        results.push({
          id: doc.id,
          type: 'product',
          title: data.title,
          description: data.description,
          imageUrl: data.imageUrls && data.imageUrls.length > 0 ? data.imageUrls[0] : null,
          price: data.price,
          createdAt: data.createdAt?.toDate().toISOString() || new Date().toISOString(),
          matchScore: matchScore,
        });
      }
    });

    // 소식(news) 검색
    const newsSnapshot = await db.collection('news').get();
    newsSnapshot.forEach((doc) => {
      const data = doc.data();
      const title = (data.title || '').toLowerCase();
      const content = (data.content || '').toLowerCase();
      
      const matchScore = keywords.reduce((score, keyword) => {
        const lowerKeyword = keyword.toLowerCase();
        if (title.includes(lowerKeyword)) score += 3;
        if (content.includes(lowerKeyword)) score += 1;
        return score;
      }, 0);

      if (matchScore > 0) {
        results.push({
          id: doc.id,
          type: 'news',
          title: data.title,
          description: data.content?.substring(0, 100), // 처음 100자
          imageUrl: data.imageUrls && data.imageUrls.length > 0 ? data.imageUrls[0] : null,
          price: null,
          createdAt: data.createdAt?.toDate().toISOString() || new Date().toISOString(),
          matchScore: matchScore,
        });
      }
    });

    // 관리자 뉴스(adminNews) 검색
    const adminNewsSnapshot = await db.collection('adminNews').get();
    adminNewsSnapshot.forEach((doc) => {
      const data = doc.data();
      const title = (data.title || '').toLowerCase();
      const content = (data.content || '').toLowerCase();
      
      const matchScore = keywords.reduce((score, keyword) => {
        const lowerKeyword = keyword.toLowerCase();
        if (title.includes(lowerKeyword)) score += 3;
        if (content.includes(lowerKeyword)) score += 1;
        return score;
      }, 0);

      if (matchScore > 0) {
        results.push({
          id: doc.id,
          type: 'news',
          title: data.title,
          description: data.content?.substring(0, 100),
          imageUrl: data.imageUrls && data.imageUrls.length > 0 ? data.imageUrls[0] : null,
          price: null,
          createdAt: data.createdAt?.toDate().toISOString() || new Date().toISOString(),
          matchScore: matchScore,
        });
      }
    });

    // 매칭 점수 순으로 정렬 후 상위 결과만 반환
    results.sort((a, b) => b.matchScore - a.matchScore);
    return results.slice(0, MAX_RESULTS);
  } catch (error) {
    console.error('Firestore 검색 오류:', error);
    return [];
  }
}

/**
 * GPT로 검색 결과 요약 메시지 생성
 */
async function generateSummary(query, results) {
  if (results.length === 0) {
    return '죄송합니다. 검색 결과를 찾지 못했습니다. 다른 키워드로 다시 검색해보세요.';
  }

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: `당신은 친절한 온동네 챗봇입니다.
사용자 질문과 검색 결과를 바탕으로 자연스러운 한국어로 응답하세요.

규칙:
1. 친근하고 간결하게
2. 검색 결과 개수와 타입(중고거래/소식) 언급
3. 1-2문장으로 요약
4. 이모지 사용 가능`,
        },
        {
          role: 'user',
          content: `질문: "${query}"
검색 결과: ${results.length}개 (중고거래 ${results.filter(r => r.type === 'product').length}개, 소식 ${results.filter(r => r.type === 'news').length}개)

응답 메시지를 작성해주세요.`,
        },
      ],
      temperature: 0.7,
      max_tokens: 100,
    });

    return response.choices[0].message.content.trim();
  } catch (error) {
    console.error('요약 생성 오류:', error);
    return `${results.length}개의 결과를 찾았습니다! 아래에서 확인해보세요.`;
  }
}

